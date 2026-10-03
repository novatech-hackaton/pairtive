# Pairtive

AI peer-tutoring video matching. Pairtive pairs students with inverse strengths and
weaknesses (you teach your strong subject, they teach you yours) into live video
sessions, one-on-one (Study Buddy) or in small groups of 3-5 (Study Peers).

Built as a web app with HTML + Tailwind CSS, React (Vite), Supabase (Auth, Postgres
with RLS, Realtime, Storage), Daily.co for video/voice, and Vercel for hosting and
serverless API functions. Every source file is prefixed with "am".

## Features

- Email/password and Google sign-in, with a stepper onboarding (name, languages, school, avatar, subjects).
- AI matcher: inverse subject matching, Bayesian-smoothed ratings/success, language boost, cooldowns, Study Peers group building. Pure logic in \u0060shared/\u0060, fully unit-tested.
- Match preview with a 15s Accept/Next countdown, teach/learn copy, and auto-opened camera.
- Live sessions on Daily: video/mic toggles, screen share (desktop), in-session chat (text/images/files), real-time collaborative notes (Yjs), and consent-based client-side recording saved to the user's device.
- OmeTV-style Stop/Next, post-session ratings (stars, tags, comment) feeding the matcher.
- Full messenger: lazy, de-duplicated threads, image/file sharing, and a Reconnect button that starts a call directly.
- Reports with immediate blocking and automated AI moderation (NSFWJS for images, TensorFlow toxicity for text, rules for spam/no-show), a strike ladder, and timed suspensions. No admin page.

## Project layout

\u0060\u0060\u0060
api/        Vercel serverless functions (amMatch, amStartSession, amSessionToken, amReportVerify)
server/     Server-only helpers (Supabase admin, Daily REST, AI model loaders)
shared/     Pure, tested logic shared by client + server (matching, moderation, subjects, attachments)
src/        React app (amMain, amApp), lib/ (supabase, daily, media, recorder, notes, chat), components/, pages/
supabase/   Timestamped SQL migrations (schema + RLS + RPCs)
tests/      Migration tests (PGlite), API tests, real-model AI test
\u0060\u0060\u0060

## Setup

1. \u0060npm install\u0060
2. Create a Supabase project. In the SQL editor, run the files in \u0060supabase/migrations/\u0060 in order.
3. Enable Google auth (optional) under Authentication -> Providers, and add your site URL to the redirect allow-list.
4. Create a free Daily.co account and copy its API key.
5. Copy \u0060.env.example\u0060 to \u0060.env\u0060 and fill in the values.
6. \u0060npm run dev\u0060 (the local server also emulates the \u0060/api\u0060 functions).

### Environment variables

| Variable | Where | Purpose |
| --- | --- | --- |
| \u0060VITE_SUPABASE_URL\u0060 | client + server | Supabase project URL |
| \u0060VITE_SUPABASE_ANON_KEY\u0060 | client + server | Supabase anon key |
| \u0060SUPABASE_SERVICE_ROLE_KEY\u0060 | server only | Service role key for \u0060/api\u0060 (never in the client) |
| \u0060DAILY_API_KEY\u0060 | server only | Daily REST key for creating rooms/tokens |

On Vercel, add all four under Project Settings -> Environment Variables. The two
server-only secrets must never be exposed to the browser.

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
