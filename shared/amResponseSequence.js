// Response_Sequence builder: turns one topic's stored answers into the ordered
// `[{ is_correct, difficulty? }]` stream that BKT consumes (the `responses` field of
// the amPredict request). Ported from the diagnostic-skillgps module
// (lib/dsResponseSequence.js). Shared by client, API and tests.
//
// Ordering: by `sequence_index` when present, else by `created_at`, else by array
// order. `sequence_index` comes first because answers saved in one batch share the
// same `created_at`. Ties keep the original array order.

export const AM_MAX_SEQUENCE_LENGTH = 20;

/** Thrown for an invalid answer set; `fields` lists every invalid position at once. */
export class AmSequenceError extends Error {
  constructor(fields) {
    super(fields.join('; '));
    this.name = 'AmSequenceError';
    this.fields = fields;
  }
}

function amCoerceCorrectness(answer) {
  if (answer == null || typeof answer !== 'object') return undefined;
  if ('is_correct' in answer) return answer.is_correct;
  if ('isCorrect' in answer) return answer.isCorrect;
  return undefined;
}

function amOrderKey(answer, index) {
  if (answer && answer.sequence_index != null && Number.isFinite(Number(answer.sequence_index))) {
    return [0, Number(answer.sequence_index), index];
  }
  if (answer && answer.created_at != null) {
    const t = typeof answer.created_at === 'number' ? answer.created_at : Date.parse(answer.created_at);
    if (Number.isFinite(t)) return [1, t, index];
  }
  return [2, index, index];
}

function amCompareKeys(a, b) {
  for (let i = 0; i < a.length; i += 1) {
    if (a[i] < b[i]) return -1;
    if (a[i] > b[i]) return 1;
  }
  return 0;
}

/**
 * Build an ordered BKT response sequence from a topic's answers.
 * Throws AmSequenceError when the set is empty, longer than 20, or contains an answer
 * with a missing correctness value or a difficulty that is not an integer 1-3.
 * @param {Array<object>} answers
 * @returns {Array<{ is_correct: boolean, difficulty?: number }>}
 */
export function amBuildResponseSequence(answers) {
  if (!Array.isArray(answers)) {
    throw new AmSequenceError(['answers: must be an array of answers']);
  }

  const fields = [];
  if (answers.length === 0) {
    fields.push('answers: must contain at least 1 answer');
  } else if (answers.length > AM_MAX_SEQUENCE_LENGTH) {
    fields.push(`answers: must contain at most ${AM_MAX_SEQUENCE_LENGTH} answers`);
  }

  const ordered = answers
    .map((answer, index) => ({ answer, key: amOrderKey(answer, index) }))
    .sort((a, b) => amCompareKeys(a.key, b.key))
    .map((entry) => entry.answer);

  const sequence = [];
  ordered.forEach((answer, index) => {
    const correctness = amCoerceCorrectness(answer);
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

  if (fields.length > 0) throw new AmSequenceError(fields);
  return sequence;
}
