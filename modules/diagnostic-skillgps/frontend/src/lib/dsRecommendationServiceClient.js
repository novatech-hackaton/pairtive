/**
 * Recommendation client — sends the ordered recommendation entries to the
 * Recommendation_Service in one request and returns a map of topicId ->
 * generated wording. Reads the base URL from VITE_RECOMMENDATION_SERVICE_URL
 * only. Never alters selection or order. 10-second timeout.
 *
 * On any failure (timeout, unreachable, non-200, invalid body), it returns an
 * empty map so the caller falls back to each entry's deterministic
 * recommendationContent. Per-entry misses (null generated text) are simply
 * omitted from the map, which also triggers the per-entry fallback.
 */

const DEFAULT_TIMEOUT_MS = 10000;

function baseUrl() {
  const url = import.meta.env.VITE_RECOMMENDATION_SERVICE_URL;
  if (typeof url !== 'string' || url.trim() === '') return null;
  return url.replace(/\/+$/, '');
}

/**
 * @param {Array<{topicId:any, topicName:string, masteryLevel:string, masteryProbability:number, recommendationContent:string}>} entries
 * @param {{ timeoutMs?: number, fetchImpl?: typeof fetch }} [options]
 * @returns {Promise<Map<string,string>>} topicId -> generated text (misses omitted)
 */
export async function requestWording(entries, options = {}) {
  const result = new Map();
  const url = baseUrl();
  if (!url || !Array.isArray(entries) || entries.length === 0) return result;

  const timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const fetchImpl = options.fetchImpl ?? fetch;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const resp = await fetchImpl(`${url}/recommend`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ entries }),
      signal: controller.signal,
    });
    clearTimeout(timer);
    if (!resp.ok) return result;
    const body = await resp.json();
    const list = body && Array.isArray(body.entries) ? body.entries : [];
    for (const e of list) {
      if (e && e.topicId != null && typeof e.generatedRecommendationText === 'string' && e.generatedRecommendationText.trim()) {
        result.set(String(e.topicId), e.generatedRecommendationText);
      }
    }
    return result;
  } catch {
    clearTimeout(timer);
    return result; // unreachable/timeout -> caller uses deterministic fallback
  }
}

export default requestWording;
