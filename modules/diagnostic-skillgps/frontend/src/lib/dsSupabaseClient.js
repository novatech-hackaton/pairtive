import { createClient } from '@supabase/supabase-js';

/**
 * Supabase_Client — the single module that reads the Supabase connection
 * variables and creates the Supabase JS client.
 *
 * Requirements:
 * - 7.1 / 5.10 : This is the only Frontend_App module that reads
 *   `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
 * - 7.4 / 5.11 : The client authenticates with the Anon_Key only. The
 *   Service_Role_Key is never read, imported, or referenced here.
 * - 7.10       : When any of the four required frontend variables is
 *   undefined, empty, or whitespace-only, `getConfigErrors()` names every
 *   missing variable so the app can show a configuration error in place of
 *   all routes.
 * - 7.11       : When any required variable is missing, the Supabase client
 *   is not created and no request is sent.
 *
 * The four variables are read from Vite's `import.meta.env`. Only this module
 * reads the two Supabase variables; the Prediction_Client and the
 * Recommendation client read the other two.
 */

/**
 * The exact set of frontend environment variables the app requires at startup.
 * Order is preserved so the configuration error lists them predictably.
 * @type {readonly string[]}
 */
export const REQUIRED_FRONTEND_ENV_VARS = Object.freeze([
  'VITE_SUPABASE_URL',
  'VITE_SUPABASE_ANON_KEY',
  'VITE_PREDICTION_API_URL',
  'VITE_RECOMMENDATION_SERVICE_URL',
]);

/**
 * A value counts as "present" only when it is a non-empty, non-whitespace
 * string. `undefined`, empty string, and whitespace-only all count as missing.
 * @param {unknown} value
 * @returns {boolean}
 */
function isPresent(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

/**
 * Returns the names of every required frontend variable that is undefined,
 * empty, or whitespace-only. An empty array means configuration is complete.
 * (Req 7.10)
 * @returns {string[]}
 */
export function getConfigErrors() {
  const env = import.meta.env;
  return REQUIRED_FRONTEND_ENV_VARS.filter((name) => !isPresent(env[name]));
}

/** Lazily-created singleton Supabase client (null until first valid request). */
let client = null;

/**
 * Returns the single Supabase client instance, creating it on first use from
 * `VITE_SUPABASE_URL` and the Anon_Key in `VITE_SUPABASE_ANON_KEY`.
 *
 * When any required frontend variable is missing, the client is not created
 * and `null` is returned, so no request is ever sent with an invalid config
 * (Req 7.11). Callers should guard with `getConfigErrors()` and render the
 * configuration error before reaching this function.
 *
 * @returns {import('@supabase/supabase-js').SupabaseClient | null}
 */
export function getSupabase() {
  if (getConfigErrors().length > 0) {
    return null;
  }
  if (client === null) {
    const url = import.meta.env.VITE_SUPABASE_URL;
    const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
    client = createClient(url, anonKey);
  }
  return client;
}

/**
 * Integration seam for the owning user id.
 *
 * This module is designed to be embedded in a host application that owns
 * authentication. The host sets the current user id ONCE and the module writes
 * it into the `user_id` column of student-data rows. Resolution order:
 *   1. an explicit value set via `setUserId(...)` (host app calls this),
 *   2. a global `window.__DS_USER_ID__` (host app can set this before mount),
 *   3. the Supabase Auth session user id, if a session exists,
 *   4. otherwise `null` (standalone/demo: the app runs but does not persist
 *      per-user rows).
 *
 * At integration time, wiring the host's identity is a one-line call to
 * `setUserId(hostUserId)` (or setting `window.__DS_USER_ID__`). No other code
 * needs to change.
 */
let injectedUserId = null;

export function setUserId(id) {
  injectedUserId = id != null && String(id).trim() !== '' ? String(id) : null;
}

export async function getUserId() {
  if (injectedUserId) return injectedUserId;
  if (typeof window !== 'undefined' && window.__DS_USER_ID__) {
    return String(window.__DS_USER_ID__);
  }
  const supabase = getSupabase();
  if (supabase && supabase.auth && typeof supabase.auth.getUser === 'function') {
    try {
      const { data } = await supabase.auth.getUser();
      if (data && data.user && data.user.id) return data.user.id;
    } catch {
      // no session; fall through to null
    }
  }
  return null;
}
