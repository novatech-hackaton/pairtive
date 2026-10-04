# Pairtive

AI peer-tutoring video matching. Pairtive pairs students with inverse strengths and
weaknesses (you teach your strong subject, they teach you yours) into live video
sessions, one-on-one (Study Buddy) or in small groups of 3-5 (Study Peers).

Built as a web app with HTML + Tailwind CSS, React (Vite), Supabase (Auth, Postgres
with RLS, Realtime, Storage), Daily.co for video/voice, and Vercel for hosting and
serverless API functions. Every source file is prefixed with "am".

## Features

- Email/password sign-in, with a stepper onboarding (name, languages, school, avatar, subjects).
- AI matcher: inverse subject matching, Bayesian-smoothed ratings/success, language boost, cooldowns, Study Peers group building. Pure logic in \u0060shared/\u0060, fully unit-tested.
- Match preview with a 15s Accept/Next countdown, teach/learn copy, and auto-opened camera.
- Live sessions on Daily: video/mic toggles, screen share (desktop), in-session chat (text/images/files), real-time collaborative notes (Yjs), and consent-based client-side recording saved to the user's device.
- OmeTV-style Stop/Next, post-session ratings (stars, tags, comment) feeding the matcher.
- Full messenger: lazy, de-duplicated threads, image/file sharing, and a Reconnect button that starts a call directly.
- Reports with immediate blocking and automated AI moderation (NSFWJS for images, TensorFlow toxicity for text, rules for spam/no-show), a strike ladder, and timed suspensions. No admin page.
- Diagnostic + SkillGPS: a short diagnostic quiz scores each answer and estimates per-skill mastery with Bayesian Knowledge Tracing (BKT). The SkillGPS page shows mastery bars, a summary and study recommendations.

## Diagnostic and SkillGPS

1. The user takes the diagnostic (\u0060/diagnostic\u0060). Questions come from the \u0060diagnostic_questions\u0060 table (seeded by the migrations below).
2. For each topic, the client posts the scored response sequence to \u0060/api/amPredict\u0060, which runs the Node BKT port (\u0060shared/amBkt.js\u0060 with fitted parameters in \u0060shared/amBktParams.js\u0060) and returns the mastery estimate.
3. The client saves one Mastery_Record per topic (\u0060student_topic_mastery\u0060), and the SkillGPS page (\u0060/skillgps\u0060) shows mastery per topic plus recommendations.
4. The Mastery_Bridge (\u0060shared/amMasteryBridge.js\u0060, applied in the database by \u0060am_apply_mastery_bridge()\u0060) turns mastered topics into the profile's strong subjects and struggling topics into weak subjects.
5. The matcher pairs users who share strong subjects, using these diagnostic-sourced profiles.

\u0060/match\u0060 requires a completed diagnostic. Users without Mastery_Records are redirected to \u0060/diagnostic\u0060, and \u0060/api/amMatch\u0060 also rejects them on the server (403 \u0060diagnostic-required\u0060).

\u0060POST /api/amPredict\u0060 requires a signed-in user (\u0060Authorization: Bearer <supabase access token>\u0060), validates the body (10 KB limit, known \u0060topic_id\u0060), and stores nothing. It is plain JavaScript; no Python runs in production.

## Project layout

\u0060\u0060\u0060
api/        Vercel serverless functions (amMatch, amPredict, amStartSession, amSessionToken, amReportVerify)
server/     Server-only helpers (Supabase admin, Daily REST, AI model loaders)
shared/     Pure, tested logic shared by client + server (matching, moderation, subjects, attachments, BKT, mastery)
scripts/    Dev tooling (migration runner, match demo, BKT parameter extraction)
src/        React app (amMain, amApp), lib/ (supabase, daily, media, recorder, notes, chat), components/, pages/
supabase/   Timestamped SQL migrations (schema + RLS + RPCs)
tests/      Migration tests (PGlite), API tests, real-model AI test
\u0060\u0060\u0060

## Setup

1. \u0060npm install\u0060
2. Create a Supabase project. In the SQL editor, run the files in \u0060supabase/migrations/\u0060 in order.
3. Under Authentication -> URL Configuration, add your site URL to the redirect allow-list (used by email confirmation and password reset links).
4. Create a free Daily.co account and copy its API key.
5. Copy \u0060.env.example\u0060 to \u0060.env\u0060 and fill in the values.
6. \u0060npm run dev\u0060 (the local server also emulates the \u0060/api\u0060 functions).

### Migrations

Apply the migrations in \u0060supabase/migrations/\u0060 in order, either in the SQL editor or with
the runner:

\u0060\u0060\u0060
AM_DB_URL=postgresql://... node scripts/amMigrate.mjs
\u0060\u0060\u0060

The Diagnostic/SkillGPS feature adds two:

- \u006020261003000007_am_diagnostic.sql\u0060 - programs/subjects/topics, diagnostic questions, attempts, answers and \u0060student_topic_mastery\u0060 tables, RLS, and the \u0060am_apply_mastery_bridge()\u0060 RPC
- \u006020261003000008_am_diagnostic_seed.sql\u0060 - seed the BSCS program, its subjects and topics, and the diagnostic questions

\u0060scripts/amBktExtract.py\u0060 is a dev-only helper that regenerates \u0060shared/amBktParams.js\u0060
(and the parity fixture) from the original Python model. It is never deployed and is not
needed to run the app.

### Environment variables

| Variable | Where | Purpose |
| --- | --- | --- |
| \u0060VITE_SUPABASE_URL\u0060 | client + server | Supabase project URL |
| \u0060VITE_SUPABASE_ANON_KEY\u0060 | client + server | Supabase publishable (anon) key; safe in the browser, RLS enforces access |
| \u0060SUPABASE_URL\u0060 | server only | Supabase project URL for \u0060/api\u0060 (falls back to \u0060VITE_SUPABASE_URL\u0060) |
| \u0060SUPABASE_SERVICE_ROLE_KEY\u0060 | server only | Supabase secret (service role) key for \u0060/api\u0060; bypasses RLS, never in the client |
| \u0060DAILY_API_KEY\u0060 | server only | Daily REST key for creating rooms/tokens |
| \u0060AM_DB_URL\u0060 | local only | Postgres connection string for \u0060scripts/amMigrate.mjs\u0060 |

On Vercel, add the Supabase and Daily variables under Project Settings -> Environment Variables.
Server-only secrets must never be exposed to the browser, so never give them a \u0060VITE_\u0060 prefix.
The app has no separate prediction or recommendation service URL; everything runs through
\u0060/api\u0060 on the same origin.

## Scripts

- \u0060npm run dev\u0060 - Vite dev server + local /api emulator
- \u0060npm run build\u0060 / \u0060npm run preview\u0060 - production build / preview
- \u0060npm test\u0060 - run the full Vitest suite once
- \u0060npm run demo:match\u0060 - print sample matches from the matcher

## Deploying

Push to GitHub and import the repo in Vercel. The framework preset is Vite; \u0060vercel.json\u0060
already configures the SPA rewrite and the \u0060/api\u0060 function limits (the moderation
function gets extra memory/time for the AI models).

## File naming

Every source file starts with "am". Standard tooling files keep their required names:
\u0060index.html\u0060, \u0060package.json\u0060, \u0060vite.config.js\u0060, \u0060vercel.json\u0060, \u0060.env\u0060, \u0060README.md\u0060.
Supabase migrations use a timestamp prefix.

## Notes & limitations

- Daily's free tier includes 10,000 participant-minutes/month; each participant-minute counts.
- Screen sharing is desktop-only; mobile browsers can view a shared screen but not start one.
- Recordings are produced in the browser and saved to the user's own device (download on
  desktop/Android, share sheet on iOS). They are never uploaded to Pairtive.
- Moderation captures a few still frames of a reported user's video as evidence. This must
  be disclosed in your Terms of Service and Privacy Policy before launch.
- There is no admin page by design; suspensions are automatic. An owner can adjust or lift a
  suspension directly in the Supabase dashboard (\u0060profiles.status\u0060 / \u0060suspended_until\u0060).
