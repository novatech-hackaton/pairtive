/**
 * Response_Sequence builder — the BKT input contract on the frontend.
 *
 * Bayesian Knowledge Tracing consumes an ORDERED stream of correct/incorrect
 * answers for one topic. This module turns a topic's stored answers into that
 * ordered sequence, mirroring the Python `validate_response_sequence` in
 * `ml/dsbkt.py` so the browser and the Prediction_API agree on what a valid
 * sequence is.
 *
 * This replaces the former Feature_Extractor (which aggregated answers into a
 * six-field feature vector); BKT does not use aggregated features.
 *
 * `buildResponseSequence(answers)` returns an array of `{ is_correct, difficulty? }`
 * objects in answered order. Answers are ordered by `created_at` when present,
 * else by an explicit `sequence_index`, else by their given array order. Throws
 * a `SequenceError` (with a `fields` array) when the set is empty, longer than
 * 20, or contains an answer with a missing correctness value or an invalid
 * difficulty, reporting every invalid position at once.
 */

export const MAX_SEQUENCE_LENGTH = 20;

export class SequenceError extends Error {
  constructor(fields) {
    super(fields.join('; '));
    this.name = 'SequenceError';
    this.fields = fields;
  }
}

function coerceCorrectness(answer) {
  if (answer == null || typeof answer !== 'object') return undefined;
  if ('is_correct' in answer) return answer.is_correct;
  if ('isCorrect' in answer) return answer.isCorrect;
  return undefined;
}

function orderKey(answer, index) {
  // Prefer created_at (ISO string or epoch), then explicit sequence_index,
  // then the original array index as a stable fallback.
  if (answer && answer.created_at != null) {
    const t = typeof answer.created_at === 'number'
      ? answer.created_at
      : Date.parse(answer.created_at);
    if (Number.isFinite(t)) return [0, t, index];
  }
  if (answer && Number.isFinite(Number(answer.sequence_index))) {
    return [1, Number(answer.sequence_index), index];
  }
  return [2, index, index];
}

function compareKeys(a, b) {
  for (let i = 0; i < a.length; i += 1) {
    if (a[i] < b[i]) return -1;
    if (a[i] > b[i]) return 1;
  }
  return 0;
}

/**
 * Build an ordered BKT response sequence from a topic's answers.
 * @param {Array<object>} answers
 * @returns {Array<{ is_correct: boolean, difficulty?: number }>}
 */
export function buildResponseSequence(answers) {
  if (!Array.isArray(answers)) {
    throw new SequenceError(['answers: must be an array of answers']);
  }

  const fields = [];
  if (answers.length === 0) {
    fields.push('answers: must contain at least 1 answer');
  } else if (answers.length > MAX_SEQUENCE_LENGTH) {
    fields.push(`answers: must contain at most ${MAX_SEQUENCE_LENGTH} answers`);
  }

  const ordered = answers
    .map((answer, index) => ({ answer, key: orderKey(answer, index) }))
    .sort((a, b) => compareKeys(a.key, b.key))
    .map((entry) => entry.answer);

  const sequence = [];
  ordered.forEach((answer, index) => {
    const correctness = coerceCorrectness(answer);
    if (correctness === undefined || correctness === null) {
      fields.push(`answers[${index}].is_correct: missing correctness value`);
    }
    const item = { is_correct: Boolean(correctness) };

    const difficulty = answer && answer.difficulty;
    if (difficulty != null) {
      const d = Number(difficulty);
      if (!Number.isInteger(d) || d < 1 || d > 3) {
        fields.push(`answers[${index}].difficulty: must be an integer from 1 to 3`);
      } else {
        item.difficulty = d;
      }
    }
    sequence.push(item);
  });

  if (fields.length > 0) {
    throw new SequenceError(fields);
  }
  return sequence;
}

export default buildResponseSequence;
