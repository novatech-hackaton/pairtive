// Shared server helpers for /api functions (Vercel Node runtime). Never imported by the client.
import { createClient } from '@supabase/supabase-js';

export class AmHttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

let adminClient;
export function amAdmin() {
  if (!adminClient) {
    const url = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !key) throw new AmHttpError(500, 'Server is missing Supabase configuration');
    adminClient = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  }
  return adminClient;
}

/** Verify the caller's Supabase JWT. Returns the auth user. */
export async function amRequireUser(req, admin = amAdmin()) {
  const header = req.headers?.authorization || req.headers?.Authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) throw new AmHttpError(401, 'Sign in required');
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data?.user) throw new AmHttpError(401, 'Your session expired. Please sign in again.');
  return data.user;
}

export const amIsUuid = (v) => typeof v === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);

/** Wrap a handler: POST only, JSON errors, no stack traces leaked. */
export function amHandler(fn) {
  return async function handler(req, res) {
    res.setHeader('Cache-Control', 'no-store');
    if (req.method !== 'POST') {
      res.setHeader('Allow', 'POST');
      return res.status(405).json({ error: 'Method not allowed' });
    }
    try {
      const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
      const result = await fn({ req, body });
      return res.status(200).json(result ?? {});
    } catch (err) {
      const status = err instanceof AmHttpError ? err.status : 500;
      if (status >= 500) console.error('[api]', err);
      return res.status(status).json({ error: status >= 500 ? 'Something went wrong. Please try again.' : err.message });
    }
  };
}

export function amDbError(error, fallback = 'Database error') {
  if (!error) return;
  console.error('[db]', error);
  throw new AmHttpError(500, fallback);
}

// ---------------------------------------------------------------------------
// Daily.co REST helpers
// ---------------------------------------------------------------------------
const AM_DAILY_API = 'https://api.daily.co/v1';

async function amDaily(path, { method = 'GET', body } = {}) {
  const key = process.env.DAILY_API_KEY;
  if (!key) throw new AmHttpError(500, 'Server is missing Daily configuration');
  const res = await fetch(`${AM_DAILY_API}${path}`, {
    method,
    headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  return { ok: res.ok, status: res.status, json };
}

export const AM_ROOM_TTL_SECONDS = 2 * 60 * 60;

/** Create (or reuse) a private room. Deterministic names make this idempotent. */
export async function amEnsureDailyRoom(name) {
  const exp = Math.floor(Date.now() / 1000) + AM_ROOM_TTL_SECONDS;
  const created = await amDaily('/rooms', {
    method: 'POST',
    body: {
      name,
      privacy: 'private',
      properties: {
        exp,
        max_participants: 5,
        enable_screenshare: true,
        enable_chat: false,
        enable_knocking: false,
        enable_prejoin_ui: false,
        eject_at_room_exp: true,
      },
    },
  });
  if (created.ok) return created.json;
  const existing = await amDaily(`/rooms/${encodeURIComponent(name)}`);
  if (existing.ok) return existing.json;
  console.error('[daily] room error', created.status, created.json);
  throw new AmHttpError(502, 'Could not create the video room. Please try again.');
}

export async function amCreateDailyToken({ roomName, userId, userName }) {
  const exp = Math.floor(Date.now() / 1000) + AM_ROOM_TTL_SECONDS;
  const res = await amDaily('/meeting-tokens', {
    method: 'POST',
    body: {
      properties: {
        room_name: roomName,
        user_id: userId,
        user_name: (userName || 'Student').slice(0, 60),
        exp,
        eject_at_token_exp: true,
        enable_screenshare: true,
        is_owner: false,
      },
    },
  });
  if (!res.ok || !res.json?.token) {
    console.error('[daily] token error', res.status, res.json);
    throw new AmHttpError(502, 'Could not join the video room. Please try again.');
  }
  return res.json.token;
}
