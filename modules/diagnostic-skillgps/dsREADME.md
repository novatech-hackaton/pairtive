# Diagnostic Assessment and SkillGPS

A diagnostic assessment platform for a BSCS program. Students take per-topic
diagnostics; the system estimates topic mastery and visualizes it on a SkillGPS
dashboard with recommendations.

The mastery engine uses **Bayesian Knowledge Tracing (BKT)**: it processes each
answer in order and tracks the probability a topic is mastered. See
[`ml/dsREADME.md`](ml/dsREADME.md) for the model and
[`data/dsREADME.md`](data/dsREADME.md) for the data format.

## Components

| Area | Path | What it is |
|------|------|------------|
| Database | `supabase/` | Postgres schema + RLS (`dsschema.sql`) and seed data (`dsseed.sql`). |
| ML / BKT | `ml/` | BKT engine, fitting, training, evaluation, CLI, and the Prediction_API. |
| Training data | `data/` | Synthetic, test-only response-sequence CSV. |
| Frontend | `frontend/` | Vite + React app (auth, diagnostic, SkillGPS). |
| Recommendations | `recommendation-service/` | Optional Gemini-backed wording service (planned). |

## Configuration (secrets)

Copy each `.env.example` to `.env` and fill in real values. `.env` files are
gitignored; only the `.env.example` templates are committed.

- `frontend/.env` — `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` (browser-safe
  anon key only; **never** a service-role key), `VITE_PREDICTION_API_URL`,
  `VITE_RECOMMENDATION_SERVICE_URL`.
- `ml/.env` — `ALLOWED_ORIGINS`, `PORT`, `MODEL_PATH` (no secrets).
- `recommendation-service/.env` — `GEMINI_API_KEY` (server-side only),
  `ALLOWED_ORIGINS`, `PORT`.

Do not paste secrets into chat, commits, or any `VITE_` variable that is not
meant to be public.

## Run locally

1. Database: paste `supabase/dsschema.sql` then `supabase/dsseed.sql` into the
   Supabase SQL editor and run once.
2. ML: `python ml/dsgenerate_data.py`, then `python ml/dstrain_model.py`, then
   start the Prediction_API with `python ml/dsprediction_api.py` (serves
   http://127.0.0.1:8000).
3. Frontend: `cd frontend`, `npm install`, then start the Vite dev server with
   the `dev` npm script (serves http://localhost:5173).

## Tests

- Python / BKT: `python -m pytest ml/tests/ -q`
- Frontend: `cd frontend` then the `test` npm script (Vitest).
