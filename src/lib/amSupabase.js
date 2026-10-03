import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const amSupabaseConfigured = Boolean(url && anonKey);

export const amSupabase = amSupabaseConfigured
  ? createClient(url, anonKey, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, flowType: 'pkce' },
      realtime: { params: { eventsPerSecond: 20 } },
    })
  : null;

/** Throw a friendly error from a Supabase response. */
export function amUnwrap({ data, error }) {
  if (error) throw new Error(amFriendlyError(error));
  return data;
}

export function amFriendlyError(error) {
  const msg = error?.message || String(error || 'Something went wrong');
  if (/Failed to fetch|NetworkError/i.test(msg)) return "Can't reach the server. Check your connection.";
  if (/JWT|token/i.test(msg) && /expired/i.test(msg)) return 'Your session expired. Please sign in again.';
  return msg;
}
