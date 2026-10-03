// POST /api/amReportVerify { reportId } - AI verification + automatic enforcement.
// Called by the reporter's client right after the report (and evidence upload).
import {
  AM_REPORT_WINDOW_MS,
  amAggregateFrameScores,
  amDecideEnforcement,
  amNoShowScore,
  amNsfwFrameScore,
  amSpamScore,
  amToxicityScore,
  amVerdictFromScore,
} from '../shared/amModeration.js';
import { AmHttpError, amAdmin, amDbError, amHandler, amIsUuid, amRequireUser } from '../server/amServer.js';

const AM_DARK_LUMINANCE = 14;

async function amDownload(admin, bucket, path) {
  const { data, error } = await admin.storage.from(bucket).download(path);
  if (error || !data) return null;
  return Buffer.from(await data.arrayBuffer());
}

async function amReportedMessages(admin, report) {
  let q = admin
    .from('messages')
    .select('body, attachment_path, attachment_type, conversation_id, created_at')
    .eq('sender_id', report.reported_id)
    .order('created_at', { ascending: false })
    .limit(60);
  if (report.session_id) q = q.eq('session_id', report.session_id);
  else if (report.conversation_id) {
    q = q.eq('conversation_id', report.conversation_id).gte('created_at', new Date(Date.now() - 24 * 3600 * 1000).toISOString());
  } else return [];
  const { data, error } = await q;
  amDbError(error);
  return data ?? [];
}

/** Inject `deps` in tests; production uses the real models. */
export async function amScoreReport(admin, report, deps) {
  const details = { checks: [] };
  const evidence = [];
  for (const path of report.evidence_paths ?? []) {
    const buf = await amDownload(admin, 'report-evidence', path);
    if (buf) evidence.push(buf);
  }

  if (report.reason === 'inappropriate') {
    const messages = await amReportedMessages(admin, report);
    const images = [...evidence];
    for (const m of messages.filter((x) => x.attachment_type === 'image/jpeg').slice(0, 3)) {
      const buf = await amDownload(admin, 'chat-attachments', m.attachment_path);
      if (buf) images.push(buf);
    }
    if (!images.length) {
      details.checks.push('no-visual-evidence');
      return { score: null, details };
    }
    const results = await deps.classifyFrames(images.slice(0, 6));
    const frameScores = results.map((r) => amNsfwFrameScore(r.predictions));
    details.checks.push('nsfwjs');
    details.frameScores = frameScores.map((s) => Number(s.toFixed(3)));
    return { score: amAggregateFrameScores(frameScores), details };
  }

  if (report.reason === 'harassment') {
    const messages = (await amReportedMessages(admin, report)).filter((m) => m.body?.trim());
    if (!messages.length) {
      details.checks.push('no-messages');
      return { score: null, details };
    }
    const output = await deps.classifyText(messages.slice(0, 40).map((m) => m.body));
    details.checks.push('toxicity');
    const score = amToxicityScore(output);
    details.toxicity = score;
    return { score, details };
  }

  if (report.reason === 'spam') {
    const messages = await amReportedMessages(admin, report);
    details.checks.push('spam-rules');
    details.messageCount = messages.length;
    return { score: amSpamScore(messages), details };
  }

  if (report.reason === 'no_show') {
    let durationMs = null;
    if (report.session_id) {
      const { data: m } = await admin
        .from('session_members')
        .select('joined_at, left_at')
        .eq('session_id', report.session_id)
        .eq('user_id', report.reported_id)
        .maybeSingle();
      if (m?.joined_at) durationMs = new Date(m.left_at ?? Date.now()).getTime() - new Date(m.joined_at).getTime();
      else if (m) durationMs = 0;
    }
    let darkFrameRatio = null;
    if (evidence.length) {
      const frames = await deps.decodeLuminance(evidence);
      darkFrameRatio = frames.filter((l) => l < AM_DARK_LUMINANCE).length / frames.length;
    }
    details.checks.push('no-show-rules');
    Object.assign(details, { durationMs, darkFrameRatio });
    if (durationMs == null && darkFrameRatio == null) return { score: null, details };
    return { score: amNoShowScore({ durationMs, darkFrameRatio }), details };
  }

  details.checks.push('stored-only');
  return { score: null, details };
}

export async function amEnforce(admin, report, verdict) {
  const now = Date.now();
  const since = new Date(now - AM_REPORT_WINDOW_MS).toISOString();
  const [strikesRes, uncertainRes, recentRes, profileRes] = await Promise.all([
    admin.from('strikes').select('created_at').eq('user_id', report.reported_id),
    admin
      .from('reports')
      .select('id, reporter_id, created_at')
      .eq('reported_id', report.reported_id)
      .eq('ai_verdict', 'uncertain')
      .eq('counted_in_strike', false)
      .neq('id', report.id)
      .gte('created_at', since),
    admin.from('reports').select('reporter_id, created_at').eq('reported_id', report.reported_id).gte('created_at', since),
    admin.from('profiles').select('status, suspended_until').eq('id', report.reported_id).single(),
  ]);
  amDbError(strikesRes.error || uncertainRes.error || recentRes.error || profileRes.error);

  const current = profileRes.data;
  const decision = amDecideEnforcement({
    verdict,
    reporterId: report.reporter_id,
    now,
    priorStrikes: strikesRes.data,
    openUncertain: uncertainRes.data,
    recentReports: recentRes.data,
    currentSuspendedUntil:
      current?.status === 'suspended' && current.suspended_until ? new Date(current.suspended_until).getTime() : null,
  });

  if (decision.strike) {
    await admin.from('strikes').insert({ user_id: report.reported_id, report_id: report.id });
    const counted = [report.id, ...decision.consumeUncertainIds];
    await admin.from('reports').update({ counted_in_strike: true }).in('id', counted);
  }
  if (decision.warning) {
    await admin.from('warnings').insert({
      user_id: report.reported_id,
      report_id: report.id,
      message:
        'Someone reported a recent session and our automated check found possible problems. Please follow the community rules. Repeated reports lead to suspension.',
    });
  }
  if (decision.suspendUntil) {
    await admin
      .from('profiles')
      .update({
        status: 'suspended',
        suspended_until: new Date(decision.suspendUntil).toISOString(),
        suspension_reason: decision.suspensionReason,
      })
      .eq('id', report.reported_id);
    await admin.from('match_queue').delete().eq('user_id', report.reported_id);
  }
  if (verdict === 'confirmed') await admin.rpc('am_recompute_stats', { p_uid: report.reported_id });
  return decision;
}

async function amRealDeps() {
  const models = await import('../server/amAiModels.js');
  return {
    classifyFrames: models.amClassifyFrames,
    classifyText: models.amClassifyText,
    decodeLuminance: async (buffers) => {
      const out = [];
      for (const b of buffers) {
        const { tensor, luminance } = await models.amDecodeJpeg(b);
        tensor.dispose();
        out.push(luminance);
      }
      return out;
    },
  };
}

export default amHandler(async ({ req, body }) => {
  const admin = amAdmin();
  const user = await amRequireUser(req, admin);
  if (!amIsUuid(body.reportId)) throw new AmHttpError(400, 'reportId is required');

  const { data: report, error } = await admin.from('reports').select('*').eq('id', body.reportId).maybeSingle();
  amDbError(error);
  if (!report || report.reporter_id !== user.id) throw new AmHttpError(404, 'Report not found');
  if (report.ai_verdict !== 'pending') return { verdict: report.ai_verdict };

  // Claim the report so concurrent calls don't double-enforce.
  const { data: claimed } = await admin
    .from('reports')
    .update({ verified_at: new Date().toISOString() })
    .eq('id', report.id)
    .is('verified_at', null)
    .select('id')
    .maybeSingle();
  if (!claimed) return { verdict: 'pending' };

  const { data: files } = await admin.storage.from('report-evidence').list(report.id, { limit: 10 });
  report.evidence_paths = (files ?? []).filter((f) => f.name.endsWith('.jpg')).map((f) => `${report.id}/${f.name}`).slice(0, 3);

  let score = null;
  let details = {};
  try {
    ({ score, details } = await amScoreReport(admin, report, await amRealDeps()));
  } catch (err) {
    console.error('[verify] model error', err);
    details = { error: 'model-failed' };
  }
  const verdict = amVerdictFromScore(score);

  await admin
    .from('reports')
    .update({
      ai_score: score == null ? null : Number(score.toFixed(3)),
      ai_verdict: verdict,
      ai_details: details,
      evidence_paths: report.evidence_paths,
    })
    .eq('id', report.id);

  const decision = await amEnforce(admin, report, verdict);

  // Data minimization: delete evidence frames when the report was rejected.
  if (verdict === 'rejected' && report.evidence_paths.length) {
    await admin.storage.from('report-evidence').remove(report.evidence_paths);
  }
  return { verdict, actionTaken: decision.strike || decision.warning || !!decision.suspendUntil };
});
