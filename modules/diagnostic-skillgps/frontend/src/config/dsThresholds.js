/**
 * Threshold_Config — the two mastery-probability thresholds that map a
 * mastery_probability to a Mastery_Level. Kept separate from the classifier
 * logic so thresholds can change without editing the classifier source.
 *
 * A mastery_probability p classifies as:
 *   p <  developingThreshold   -> "Weak"
 *   p <  proficientThreshold   -> "Developing"
 *   p >= proficientThreshold   -> "Proficient"
 *
 * These are unchanged by the BKT refactor: BKT emits a mastery_probability in
 * [0, 1] exactly as the previous classifier did, so the thresholds still apply.
 */
export const developingThreshold = 0.4;
export const proficientThreshold = 0.7;

export default { developingThreshold, proficientThreshold };
