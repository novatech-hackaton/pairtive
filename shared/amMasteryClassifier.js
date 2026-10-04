// Mastery classifier: maps a mastery_probability in [0, 1] to a Mastery_Level using
// shared/amMasteryThresholds.js. Ported from the diagnostic-skillgps module
// (lib/dsMasteryClassifier.js). Shared by client, API and tests.

import { AM_DEVELOPING_THRESHOLD, AM_PROFICIENT_THRESHOLD } from './amMasteryThresholds.js';

export const AM_MASTERY_LEVELS = ['Weak', 'Developing', 'Proficient'];

// Used only when the configured thresholds are invalid.
const AM_FALLBACK_DEVELOPING = 0.4;
const AM_FALLBACK_PROFICIENT = 0.7;

let amWarnedThisLoad = false;

function amIsValidThresholdPair(dev, prof) {
  return (
    typeof dev === 'number' &&
    typeof prof === 'number' &&
    Number.isFinite(dev) &&
    Number.isFinite(prof) &&
    dev >= 0 &&
    prof <= 1 &&
    dev < prof
  );
}

/** Configured thresholds, or the defaults (with one warning per load) when invalid. */
function amResolveThresholds(dev = AM_DEVELOPING_THRESHOLD, prof = AM_PROFICIENT_THRESHOLD) {
  if (amIsValidThresholdPair(dev, prof)) return { developing: dev, proficient: prof };
  if (!amWarnedThisLoad) {
    // eslint-disable-next-line no-console
    console.warn('amMasteryThresholds: invalid Threshold_Config; falling back to defaults 0.40 / 0.70.');
    amWarnedThisLoad = true;
  }
  return { developing: AM_FALLBACK_DEVELOPING, proficient: AM_FALLBACK_PROFICIENT };
}

/** True for the `{ error: true, reason, value }` object returned by amClassifyMastery. */
export function amIsClassificationError(result) {
  return Boolean(result) && typeof result === 'object' && result.error === true;
}

/**
 * Classify a mastery_probability. Returns 'Weak' | 'Developing' | 'Proficient', or
 * `{ error: true, reason, value }` (not thrown) for non-finite or out-of-range input.
 * Monotonic: p1 <= p2 implies level(p1) <= level(p2).
 * `thresholds` is optional and exists for tests; callers use the shared config.
 */
export function amClassifyMastery(p, thresholds) {
  if (typeof p !== 'number' || !Number.isFinite(p)) {
    return { error: true, reason: 'mastery_probability must be a finite number', value: p };
  }
  if (p < 0 || p > 1) {
    return { error: true, reason: 'mastery_probability must be from 0 to 1', value: p };
  }
  const { developing, proficient } = thresholds
    ? amResolveThresholds(thresholds.developing, thresholds.proficient)
    : amResolveThresholds();
  if (p < developing) return 'Weak';
  if (p < proficient) return 'Developing';
  return 'Proficient';
}

/** Test-only: reset the once-per-load warning latch. */
export function __amResetWarningLatchForTests() {
  amWarnedThisLoad = false;
}
