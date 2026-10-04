// Bayesian Knowledge Tracing (BKT): a line-for-line port of the diagnostic-skillgps
// module's ml/dsbkt.py, plus request validation for /api/amPredict. Pure: no I/O.
//
// The arithmetic follows the Python operation order exactly so results match the
// reference (tests/fixtures/amBktParity.json) bit-for-bit. One deliberate divergence:
// predicted_label comes from amClassifyMastery (0.40 / 0.70 thresholds, Req 2.4)
// instead of Python's argmax over the probability triple, and confidence is the
// triple's value for that label.

import { AM_BKT_DEFAULT, AM_BKT_SKILLS } from './amBktParams.js';
import { amClassifyMastery } from './amMasteryClassifier.js';
import { amIsUuid } from './amIds.js';

// Mirrored from dsbkt.py (DEVELOPING_THRESHOLD / PROFICIENT_THRESHOLD). Used only to
// shape the probability triple; kept local so the triple stays identical to Python
// even if the classifier thresholds are reconfigured.
const AM_BKT_DEVELOPING_THRESHOLD = 0.4;
const AM_BKT_PROFICIENT_THRESHOLD = 0.7;

export const AM_BKT_MAX_RESPONSES = 20;

/** posterior_given_answer: P(mastered | this answer) via Bayes' rule, no transition. */
export function amBktPosterior(prior, isCorrect, params) {
  if (isCorrect) {
    const correctIfMastered = prior * (1.0 - params.p_slip);
    const correctIfNot = (1.0 - prior) * params.p_guess;
    const evidence = correctIfMastered + correctIfNot;
    if (evidence <= 0.0) {
      // Degenerate only if prior in {0,1} and params at bounds; fall back to the prior.
      return prior;
    }
    return correctIfMastered / evidence;
  }

  const wrongIfMastered = prior * params.p_slip;
  const wrongIfNot = (1.0 - prior) * (1.0 - params.p_guess);
  const evidence = wrongIfMastered + wrongIfNot;
  if (evidence <= 0.0) return prior;
  return wrongIfMastered / evidence;
}

/** apply_transition: the prior for the next answer. */
export function amBktTransition(posterior, params) {
  return posterior + (1.0 - posterior) * params.p_transit;
}

/**
 * run_sequence: posterior mastery after the final answer (before any further
 * transition), or p_init for an empty sequence. Clamped to [0, 1].
 * @param {boolean[]} responses
 */
export function amBktRun(responses, params) {
  let prior = params.p_init;
  let posterior = prior;
  for (const isCorrect of responses) {
    posterior = amBktPosterior(prior, Boolean(isCorrect), params);
    prior = amBktTransition(posterior, params);
  }
  const result = responses.length > 0 ? posterior : params.p_init;
  return Math.min(1.0, Math.max(0.0, result));
}

/**
 * probabilities_from_mastery: Weak/Developing/Proficient triple from linear tents
 * anchored at 0, (0.40 + 0.70) / 2 and 1, normalized to sum to 1.
 */
export function amBktProbabilities(masteryProbability) {
  const p = Math.min(1.0, Math.max(0.0, Number(masteryProbability)));

  const weakAnchor = 0.0;
  const devAnchor = (AM_BKT_DEVELOPING_THRESHOLD + AM_BKT_PROFICIENT_THRESHOLD) / 2.0;
  const profAnchor = 1.0;

  // Linear tent: 1 at the anchor, decaying to 0 at +/- width.
  const closeness = (anchor, width) => Math.max(0.0, 1.0 - Math.abs(p - anchor) / width);

  const weak = closeness(weakAnchor, Math.max(devAnchor, 1e-9));
  const developing = closeness(devAnchor, Math.max(devAnchor, 1.0 - devAnchor));
  const proficient = closeness(profAnchor, Math.max(1.0 - devAnchor, 1e-9));

  const total = weak + developing + proficient;
  if (total <= 0.0) return { Weak: 1.0, Developing: 0.0, Proficient: 0.0 };
  return {
    Weak: weak / total,
    Developing: developing / total,
    Proficient: proficient / total,
  };
}

/** Fitted parameters for a topic name, or AM_BKT_DEFAULT for unknown topics. */
export function amBktParamsFor(topicName) {
  if (typeof topicName === 'string' && Object.prototype.hasOwnProperty.call(AM_BKT_SKILLS, topicName)) {
    return AM_BKT_SKILLS[topicName];
  }
  return AM_BKT_DEFAULT;
}

/**
 * Run BKT and build a Prediction_Result
 * `{ predicted_label, confidence, probabilities, mastery_probability }`.
 * @param {boolean[]} responses
 */
export function amBktPredict(responses, params) {
  const p = amBktRun(responses, params);
  const probabilities = amBktProbabilities(p);
  const predicted_label = amClassifyMastery(p); // Req 2.4 (diverges from Python argmax by design)
  return {
    predicted_label,
    confidence: probabilities[predicted_label],
    probabilities,
    mastery_probability: p,
  };
}

const amIsPlainObject = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);

/**
 * Validate an /api/amPredict body `{ topic_id, responses: [{ is_correct, difficulty? }] }`.
 * Stricter than Python: `is_correct` must be a real boolean (no 0/1, strings or
 * `isCorrect`). `difficulty` is optional (undefined/null = absent) but, when present,
 * must be an integer number from 1 to 3; it does not affect BKT.
 * @returns {{ ok: true, topicId: string, responses: boolean[] } | { ok: false, errors: string[] }}
 */
export function amValidatePredictBody(body) {
  if (!amIsPlainObject(body)) {
    return { ok: false, errors: ['body: must be an object with topic_id and responses'] };
  }

  const errors = [];

  if (body.topic_id === undefined || body.topic_id === null) {
    errors.push('topic_id: missing required field');
  } else if (!amIsUuid(body.topic_id)) {
    errors.push('topic_id: must be a UUID');
  }

  const items = body.responses;
  const responses = [];
  if (items === undefined || items === null) {
    errors.push('responses: missing required field');
  } else if (!Array.isArray(items)) {
    errors.push('responses: must be a sequence of answers');
  } else {
    if (items.length === 0) {
      errors.push('responses: must contain at least 1 answer');
    } else if (items.length > AM_BKT_MAX_RESPONSES) {
      errors.push(`responses: must contain at most ${AM_BKT_MAX_RESPONSES} answers`);
    }

    items.forEach((item, index) => {
      if (!amIsPlainObject(item)) {
        errors.push(`responses[${index}]: must be an object with is_correct`);
        return;
      }

      const correctness = item.is_correct;
      if (correctness === undefined || correctness === null) {
        errors.push(`responses[${index}].is_correct: missing correctness value`);
      } else if (typeof correctness !== 'boolean') {
        errors.push(`responses[${index}].is_correct: must be a boolean`);
      } else {
        responses.push(correctness);
      }

      const difficulty = item.difficulty;
      if (difficulty !== undefined && difficulty !== null) {
        if (!Number.isInteger(difficulty) || difficulty < 1 || difficulty > 3) {
          errors.push(`responses[${index}].difficulty: must be an integer from 1 to 3`);
        }
      }
    });
  }

  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, topicId: body.topic_id, responses };
}
