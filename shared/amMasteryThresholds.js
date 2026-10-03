// Threshold_Config for mastery levels. Ported from the diagnostic-skillgps module
// (config/dsThresholds.js). Kept apart from the classifier so thresholds can change
// without editing classifier logic.
//
//   p <  AM_DEVELOPING_THRESHOLD -> "Weak"
//   p <  AM_PROFICIENT_THRESHOLD -> "Developing"
//   p >= AM_PROFICIENT_THRESHOLD -> "Proficient"

export const AM_DEVELOPING_THRESHOLD = 0.4;
export const AM_PROFICIENT_THRESHOLD = 0.7;
