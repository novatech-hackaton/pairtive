/**
 * Prediction_Client — sends a Response_Sequence to the BKT Prediction_API and
 * parses the Prediction_Result. Reads the base URL from
 * `VITE_PREDICTION_API_URL` only.
 *
 * Request body (BKT contract):
 *   { "topic_id": "<id>", "responses": [ { "is_correct": true, "difficulty": 2 }, ... ] }
 *
 * Response (Prediction_Result, unchanged by the refactor):
 *   { predicted_label, confidence, probabilities{Weak,Developing,Proficient},
 *     mastery_probability }
 *
 * Enforces a 10-second timeout: the request is aborted and any late response is
 * ignored, surfacing a timeout error instead.
 */

const DEFAULT_TIMEOUT_MS = 10000;

export class PredictionError extends Error {
  constructor(message, { kind = 'error', fields = null } = {}) {
    super(message);
    this.name = 'PredictionError';
    this.kind = kind; // 'timeout' | 'unreachable' | 'invalid' | 'error'
    this.fields = fields;
  }
}

function baseUrl() {
  const url = import.meta.env.VITE_PREDICTION_API_URL;
  if (typeof url !== 'string' || url.trim() === '') {
    throw new PredictionError('Prediction service URL is not configured.', {
      kind: 'unreachable',
    });
  }
  return url.replace(/\/+$/, '');
}

function isValidResult(body) {
  return (
    body &&
    typeof body === 'object' &&
    typeof body.mastery_probability === 'number' &&
    Number.isFinite(body.mastery_probability) &&
    body.mastery_probability >= 0 &&
    body.mastery_probability <= 1 &&
    typeof body.predicted_label === 'string' &&
    body.probabilities &&
    typeof body.probabilities === 'object'
  );
}

/**
 * Request a BKT prediction for one topic's ordered responses.
 * @param {Array<{is_correct:boolean, difficulty?:number}>} responses
 * @param {string|number|null} topicId
 * @param {{ timeoutMs?: number, fetchImpl?: typeof fetch }} [options]
 * @returns {Promise<object>} the Prediction_Result
 */
export async function predict(responses, topicId = null, options = {}) {
  const timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const fetchImpl = options.fetchImpl ?? fetch;
  const url = `${baseUrl()}/predict`;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  let response;
  try {
    response = await fetchImpl(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ topic_id: topicId, responses }),
      signal: controller.signal,
    });
  } catch (err) {
    clearTimeout(timer);
    if (err && err.name === 'AbortError') {
      throw new PredictionError('The prediction request timed out.', { kind: 'timeout' });
    }
    throw new PredictionError('The prediction service could not be reached.', {
      kind: 'unreachable',
    });
  }
  clearTimeout(timer);

  let body = null;
  try {
    body = await response.json();
  } catch {
    body = null;
  }

  if (!response.ok) {
    const fields = body && Array.isArray(body.fields) ? body.fields : null;
    throw new PredictionError(
      (body && body.error) || `Prediction failed (HTTP ${response.status}).`,
      { kind: response.status === 400 ? 'invalid' : 'error', fields },
    );
  }

  if (!isValidResult(body)) {
    throw new PredictionError('The prediction service returned an invalid result.', {
      kind: 'invalid',
    });
  }
  return body;
}

export default predict;
