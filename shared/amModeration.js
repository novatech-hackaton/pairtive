// Report verification scoring + enforcement rules (no admin page; fully automatic).
// Pure functions: the API feeds in model outputs and DB history, then applies the decision.

export const AM_REPORT_REASONS = [
  { id: 'inappropriate', label: 'Inappropriate behavior', hint: 'Nudity, explicit or offensive visuals' },
  { id: 'harassment', label: 'Harassment', hint: 'Insults, threats or hateful messages' },
  { id: 'spam', label: 'Spam', hint: 'Links, ads or repeated messages' },
  { id: 'no_show', label: 'No-show', hint: 'Camera off or left right away' },
  { id: 'other', label: 'Other', hint: 'Something else went wrong' },
];

export const AM_THRESHOLDS = Object.freeze({ confirmed: 0.8, uncertain: 0.4 });
export const AM_DAY = 24 * 60 * 60 * 1000;
export const AM_REPORT_WINDOW_MS = 7 * AM_DAY;
export const AM_STRIKE_WINDOW_MS = 30 * AM_DAY;
export const AM_SAFETY_NET_REPORTERS = 3;
export const AM_UNCERTAIN_FOR_STRIKE = 2;
export const AM_SUSPENSIONS = Object.freeze({ first: AM_DAY, second: 7 * AM_DAY, third: 30 * AM_DAY, safetyNet: AM_DAY });

const toMs = (v) => (v == null ? 0 : typeof v === 'number' ? v : new Date(v).getTime());
const clamp01 = (n) => Math.max(0, Math.min(1, Number.isFinite(n) ? n : 0));

/** null score = no automated check for this reason ("stored"). */
export function amVerdictFromScore(score) {
  if (score == null) return 'stored';
  if (score >= AM_THRESHOLDS.confirmed) return 'confirmed';
  if (score >= AM_THRESHOLDS.uncertain) return 'uncertain';
  return 'rejected';
}

/** NSFWJS predictions for one frame -> 0..1 (Porn + Hentai, plus half of Sexy). */
export function amNsfwFrameScore(predictions = []) {
  const p = Object.fromEntries(predictions.map((x) => [x.className, x.probability]));
  return clamp01((p.Porn ?? 0) + (p.Hentai ?? 0) + 0.5 * (p.Sexy ?? 0));
}

/** Mean of the top two frame scores (robust against a single odd frame). */
export function amAggregateFrameScores(scores = []) {
  if (!scores.length) return null;
  const top = [...scores].sort((a, b) => b - a).slice(0, 2);
  return clamp01(top.reduce((a, b) => a + b, 0) / top.length);
}

/**
 * @tensorflow-models/toxicity output -> 0..1 (highest probability of any toxic label in any message).
 * results: [{ label, results: [{ probabilities: [no, yes], match }] }]
 */
export function amToxicityScore(results = []) {
  let max = null;
  for (const label of results) {
    for (const r of label.results ?? []) {
      const yes = Array.isArray(r.probabilities) ? r.probabilities[1] : r.probabilities?.[1];
      if (typeof yes === 'number') max = Math.max(max ?? 0, yes);
    }
  }
  return max == null ? null : clamp01(max);
}

const AM_LINK_RE = /(https?:\/\/|www\.|\b[a-z0-9-]+\.(com|net|org|ph|io|ly|me|gg|xyz)\b)/i;

/** Rule-based spam score from the reported user's messages. */
export function amSpamScore(messages = []) {
  const bodies = messages.map((m) => (m.body ?? '').trim()).filter(Boolean);
  if (bodies.length === 0) return 0;
  const n = bodies.length;
  const linkRatio = bodies.filter((b) => AM_LINK_RE.test(b)).length / n;
  const counts = new Map();
  for (const b of bodies) counts.set(b.toLowerCase(), (counts.get(b.toLowerCase()) ?? 0) + 1);
  const dupRatio = (n - counts.size) / n;
  const times = messages.map((m) => toMs(m.created_at)).filter(Boolean).sort((a, b) => a - b);
  let burst = false;
  for (let i = 0; i + 7 < times.length; i++) if (times[i + 7] - times[i] <= 60_000) burst = true;
  const volumeFactor = n >= 3 ? 1 : 0.5;
  return clamp01(Math.max(linkRatio * volumeFactor, dupRatio >= 0.5 && n >= 4 ? 0.9 : dupRatio, burst ? 0.85 : 0));
}

/** Rule-based no-show score: how long they stayed + how many evidence frames were dark (camera off). */
export function amNoShowScore({ durationMs = null, darkFrameRatio = null } = {}) {
  let byDuration = 0;
  if (durationMs != null) {
    if (durationMs < 30_000) byDuration = 0.9;
    else if (durationMs < 60_000) byDuration = 0.6;
    else byDuration = 0.1;
  }
  const byDark = darkFrameRatio == null ? 0 : darkFrameRatio >= 1 ? 0.85 : darkFrameRatio * 0.6;
  return clamp01(Math.max(byDuration, byDark));
}

/** Average luminance (0..255) of RGBA pixel data, sampled. */
export function amMeanLuminance(rgba, step = 16) {
  let sum = 0;
  let count = 0;
  for (let i = 0; i + 2 < rgba.length; i += 4 * step) {
    sum += 0.2126 * rgba[i] + 0.7152 * rgba[i + 1] + 0.0722 * rgba[i + 2];
    count++;
  }
  return count ? sum / count : 0;
}

export function amSuspensionForStrike(strikesTotal, strikesInWindow) {
  if (strikesTotal >= 3) return AM_SUSPENSIONS.third;
  if (strikesInWindow >= 2) return AM_SUSPENSIONS.second;
  return AM_SUSPENSIONS.first;
}

/**
 * Decide what happens after a report is verified.
 * @param input.verdict          verdict of the current report
 * @param input.reporterId       reporter of the current report
 * @param input.now              ms
 * @param input.priorStrikes     [{ created_at }] strikes already on the reported user (all time)
 * @param input.openUncertain    [{ id, reporter_id, created_at }] earlier uncertain reports not yet counted in a strike
 * @param input.recentReports    [{ reporter_id, created_at }] all reports against the user (incl. current)
 * @param input.currentSuspendedUntil ms or null
 */
export function amDecideEnforcement(input) {
  const { verdict, reporterId, now, priorStrikes = [], openUncertain = [], recentReports = [] } = input;
  const out = {
    strike: false,
    warning: false,
    consumeUncertainIds: [],
    suspendUntil: null,
    suspensionReason: null,
    safetyNet: false,
  };

  if (verdict === 'confirmed') {
    out.strike = true;
  } else if (verdict === 'uncertain') {
    const recent = openUncertain.filter((r) => now - toMs(r.created_at) <= AM_REPORT_WINDOW_MS && r.reporter_id !== reporterId);
    const distinct = new Map();
    for (const r of recent) if (!distinct.has(r.reporter_id)) distinct.set(r.reporter_id, r.id);
    if (distinct.size + 1 >= AM_UNCERTAIN_FOR_STRIKE) {
      out.strike = true;
      out.consumeUncertainIds = [...distinct.values()].slice(0, AM_UNCERTAIN_FOR_STRIKE - 1);
    } else {
      out.warning = true;
    }
  }

  let until = input.currentSuspendedUntil && input.currentSuspendedUntil > now ? input.currentSuspendedUntil : null;

  if (out.strike) {
    const total = priorStrikes.length + 1;
    const inWindow = priorStrikes.filter((s) => now - toMs(s.created_at) <= AM_STRIKE_WINDOW_MS).length + 1;
    const duration = amSuspensionForStrike(total, inWindow);
    const end = now + duration;
    if (!until || end > until) until = end;
    out.suspensionReason = `Strike ${total}: a report against you was confirmed by our automated review.`;
  }

  const reporters = new Set(
    recentReports.filter((r) => now - toMs(r.created_at) <= AM_REPORT_WINDOW_MS).map((r) => r.reporter_id),
  );
  if (reporters.size >= AM_SAFETY_NET_REPORTERS) {
    out.safetyNet = true;
    const end = now + AM_SUSPENSIONS.safetyNet;
    if (!until || end > until) {
      until = end;
      if (!out.suspensionReason) out.suspensionReason = 'Several different people reported you this week.';
    }
  }

  if (until && (!input.currentSuspendedUntil || until > input.currentSuspendedUntil)) out.suspendUntil = until;
  return out;
}
