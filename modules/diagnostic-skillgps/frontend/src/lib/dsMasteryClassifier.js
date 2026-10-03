/**
 * Mastery_Classifier — maps a mastery_probability to a Mastery_Level using the
 * Threshold_Config. Contains no threshold values of its own beyond fallback
 * defaults used only when the configured thresholds are invalid.
 *
 * This module is unchanged in spirit by the BKT refactor: it consumes only a
 * scalar mastery_probability (which BKT produces directly), so it does not care
 * whether that probability came from a classifier or from Bayesian Knowledge
 * Tracing.
 *
 * `classify(p)` returns "Weak" | "Developing" | "Proficient", or a
 * Classification_Error object (NOT thrown) for a non-finite or out-of-range
 * input. The mapping is monotonic: p1 <= p2 implies level(p1) <= level(p2) in
 * the order Weak < Developing < Proficient.
 */
import {
  developingThreshold as configuredDeveloping,
  proficientThreshold as configuredProficient,
} from '../config/dsThresholds.js';

const FALLBACK_DEVELOPING = 0.4;
const FALLBACK_PROFICIENT = 0.7;

let warnedThisLoad = false;

function isValidThresholdPair(dev, prof) {
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

/**
 * Resolve the thresholds to use, falling back to defaults (and logging exactly
 * one warning per page load) when the configured values are invalid.
 */
function resolveThresholds() {
  if (isValidThresholdPair(configuredDeveloping, configuredProficient)) {
    return { developing: configuredDeveloping, proficient: configuredProficient };
  }
  if (!warnedThisLoad) {
    // eslint-disable-next-line no-console
    console.warn(
      'dsThresholds: invalid Threshold_Config; falling back to defaults 0.40 / 0.70.',
    );
    warnedThisLoad = true;
  }
  return { developing: FALLBACK_DEVELOPING, proficient: FALLBACK_PROFICIENT };
}

/**
 * A Classification_Error describes why a mastery_probability could not be
 * classified. It is returned (not thrown) so callers can branch on it.
 * @typedef {{ error: true, reason: string, value: unknown }} ClassificationError
 */
export function isClassificationError(result) {
  return Boolean(result) && typeof result === 'object' && result.error === true;
}

/**
 * Classify a mastery_probability into a Mastery_Level.
 * @param {number} p a mastery probability in [0, 1]
 * @returns {('Weak'|'Developing'|'Proficient')|ClassificationError}
 */
export function classify(p) {
  if (typeof p !== 'number' || !Number.isFinite(p)) {
    return { error: true, reason: 'mastery_probability must be a finite number', value: p };
  }
  if (p < 0 || p > 1) {
    return { error: true, reason: 'mastery_probability must be from 0 to 1', value: p };
  }
  const { developing, proficient } = resolveThresholds();
  if (p < developing) return 'Weak';
  if (p < proficient) return 'Developing';
  return 'Proficient';
}

/** Test-only: reset the once-per-load warning latch. */
export function __resetWarningLatchForTests() {
  warnedThisLoad = false;
}

export default classify;
