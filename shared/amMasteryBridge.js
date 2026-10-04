// Mastery_Bridge JS reference: derives the profile's strong_subjects / weak_subjects
// from Mastery_Records. Pure twin of the SQL RPC public.am_apply_mastery_bridge();
// used by tests and by AmMasteryProvider's self-heal check. Shared by client and tests.

// Plain code-unit comparison, matching SQL `collate "C"` for the topic names in use.
const amCodeUnitCompare = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

/** Element-wise, in-order equality. null/undefined are treated as []. */
function amSameArray(a, b) {
  const x = a ?? [];
  const y = b ?? [];
  if (x.length !== y.length) return false;
  for (let i = 0; i < x.length; i += 1) {
    if (x[i] !== y[i]) return false;
  }
  return true;
}

/** Topic name from a flattened record, or from a nested `topics(topic_name)` join. */
function amRecordTopicName(r) {
  const name = r?.topic_name ?? r?.topics?.topic_name;
  return typeof name === 'string' ? name : null;
}

/**
 * records: [{ topic_name, mastery_level }] → { strong: string[], weak: string[] }.
 * Proficient → strong, Weak → weak, Developing ignored (Req 5.2). A name that appears
 * in both lists is removed from both (Req 5.3). Output is deduplicated and sorted in
 * code-unit order so it equals the SQL result (Req 5.1, 5.7).
 */
export function amBridgeMastery(records) {
  const strong = new Set();
  const weak = new Set();
  for (const r of records ?? []) {
    const name = amRecordTopicName(r);
    if (name === null) continue;
    if (r.mastery_level === 'Proficient') strong.add(name);
    else if (r.mastery_level === 'Weak') weak.add(name);
  }
  return {
    strong: [...strong].filter((s) => !weak.has(s)).sort(amCodeUnitCompare),
    weak: [...weak].filter((s) => !strong.has(s)).sort(amCodeUnitCompare),
  };
}

/**
 * True when the profile already reflects `bridged` (Req 5.4): it is diagnostic-sourced
 * and both arrays are equal element-wise, in order. False triggers the self-heal RPC.
 */
export function amBridgeMatchesProfile(profile, bridged) {
  return (
    profile?.subjects_source === 'diagnostic' &&
    amSameArray(profile.strong_subjects, bridged?.strong) &&
    amSameArray(profile.weak_subjects, bridged?.weak)
  );
}
