// Shared server helpers for /api functions (Vercel Node runtime). Never imported by the client.
import { createClient } from '@supabase/supabase-js';
import { amIsUuid } from '../shared/amIds.js';

export { amIsUuid };

/**
 * HTTP error with a client-safe message. `extra.reason` (machine-readable code) and
 * `extra.fields` (per-field validation messages) are passed through to the JSON body.
 */
export class AmHttpError extends Error {
  constructor(status, message, extra = {}) {
    super(message);
    this.status = status;
    if (extra?.reason !== undefined) this.reason = extra.reason;
    if (extra?.fields !== undefined) this.fields = extra.fields;
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

const AM_INVALID_JSON = 'Request body must be valid JSON.';
const AM_BODY_TOO_LARGE = 'Request body too large.';

/** Read `req.body` once. Vercel's lazy getter throws on malformed JSON, so capture that. */
function amReadRawBody(req) {
  try {
    return { raw: req.body, failed: false };
  } catch {
    return { raw: undefined, failed: true };
  }
}

function amHeader(req, name) {
  const headers = req.headers || {};
  return headers[name] ?? headers[name.toLowerCase()];
}

/**
 * Wrap a handler: POST only, optional body size limit, JSON errors, no stack traces leaked.
 * Status precedence: 405 → 413 → 400 (malformed JSON) → whatever `fn` throws.
 */
export function amHandler(fn, { maxBodyBytes } = {}) {
  const limit = Number.isFinite(maxBodyBytes) && maxBodyBytes >= 0 ? maxBodyBytes : null;

  return async function handler(req, res) {
    res.setHeader('Cache-Control', 'no-store');
    if (req.method !== 'POST') {
      res.setHeader('Allow', 'POST');
      return res.status(405).json({ error: 'Method not allowed' });
    }

    if (limit !== null) {
      const declared = Number(amHeader(req, 'content-length'));
      if (Number.isFinite(declared) && declared > limit) {
        return res.status(413).json({ error: AM_BODY_TOO_LARGE });
      }
    }

    const { raw, failed } = amReadRawBody(req);
    if (limit !== null && typeof raw === 'string' && Buffer.byteLength(raw, 'utf8') > limit) {
      return res.status(413).json({ error: AM_BODY_TOO_LARGE });
    }
    if (failed) return res.status(400).json({ error: AM_INVALID_JSON });

    let body;
    if (typeof raw === 'string') {
      try {
        body = JSON.parse(raw || '{}');
      } catch {
        return res.status(400).json({ error: AM_INVALID_JSON });
      }
    } else {
      body = raw || {};
    }

    try {
      const result = await fn({ req, body });
      return res.status(200).json(result ?? {});
    } catch (err) {
      const status = err instanceof AmHttpError ? err.status : 500;
      if (status >= 500) {
        console.error('[api]', err);
        return res.status(status).json({ error: 'Something went wrong. Please try again.' });
      }
      const payload = { error: err.message };
      if (err.reason !== undefined) payload.reason = err.reason;
      if (err.fields !== undefined) payload.fields = err.fields;
      return res.status(status).json(payload);
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
