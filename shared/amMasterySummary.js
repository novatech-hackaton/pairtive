// Mastery summary: overall % and per-level counts for a user's Mastery_Records.
// Logic from the diagnostic-skillgps module's SkillGPS page stats (pages/dsSkillGPS.jsx).
// Used by the Home summary card and the SkillGPS page.

import { AM_MASTERY_LEVELS, amClassifyMastery, amIsClassificationError } from './amMasteryClassifier.js';

/** Stored mastery_level when valid; otherwise derived from p; otherwise 'Weak'. */
function amRecordLevel(record, p) {
  if (AM_MASTERY_LEVELS.includes(record.mastery_level)) return record.mastery_level;
  const derived = amClassifyMastery(p);
  return amIsClassificationError(derived) ? 'Weak' : derived;
}

/**
 * Summarize Mastery_Records into `{ total, overallPct, proficient, developing, weak }`.
 * Counts use the stored `mastery_level`, so proficient + developing + weak === total (Req 4.5).
 * overallPct = Math.round(mean(mastery_probability) * 100) (Req 4.6). mastery_probability
 * may be a numeric string (Postgres `numeric` via supabase-js) and is coerced with Number().
 * Empty, null or non-array input yields all zeros. Non-object entries are ignored.
 */
export function amSummarizeMastery(records) {
  const summary = { total: 0, overallPct: 0, proficient: 0, developing: 0, weak: 0 };
  if (!Array.isArray(records)) return summary;

  let sum = 0;
  let count = 0;
  for (const record of records) {
    if (!record || typeof record !== 'object') continue;
    const raw = record.mastery_probability;
    // Number(null) and Number('') are 0; treat missing values as absent, not as 0.
    const p = raw === null || raw === undefined || raw === '' ? NaN : Number(raw);
    summary.total += 1;
    if (Number.isFinite(p)) {
      sum += p;
      count += 1;
    }
    const level = amRecordLevel(record, p);
    if (level === 'Proficient') summary.proficient += 1;
    else if (level === 'Developing') summary.developing += 1;
    else summary.weak += 1;
  }

  summary.overallPct = count > 0 ? Math.round((sum / count) * 100) : 0;
  return summary;
}
