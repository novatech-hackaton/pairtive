# recommendation-service

Optional service that turns ordered recommendation entries into friendlier
wording using Gemini, grounded in the deterministic recommendation content from
the frontend. It never changes which topics are recommended or their order — it
only rewords.

**Status: not yet implemented.** `dsserver.py` is planned. This directory
currently holds only configuration.

## Configuration

Copy `.env.example` to `.env` and fill in:

- `GEMINI_API_KEY` — your Gemini key. **Server-side only**; never exposed to the
  browser and never committed (`.env` is gitignored).
- `ALLOWED_ORIGINS` — comma-separated allowed origins (e.g. `http://localhost:5173`).
- `PORT` — defaults to `8001`.

## Planned behavior

- Accept a list of entries `{topicId, topicName, masteryLevel, masteryProbability,
  recommendationContent}` and return per-entry generated wording, preserving
  request order.
- Per-entry failure / timeout (10s) / rate-limit / malformed -> omit that
  entry generated text with a reason, still HTTP 200.
- Missing `GEMINI_API_KEY` -> log and 503 for every request.
- Strict CORS from `ALLOWED_ORIGINS` (never `*`); holds no Supabase credentials;
  stores nothing.
