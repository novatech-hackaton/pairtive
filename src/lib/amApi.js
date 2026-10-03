import { amSupabase } from './amSupabase.js';

/** POST to a Vercel /api function with the user's Supabase access token. */
export async function amApi(name, body = {}) {
  const { data } = await amSupabase.auth.getSession();
  const token = data.session?.access_token;
  const res = await fetch(`/api/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err = new Error(json.error || `Request failed (${res.status})`);
    err.status = res.status;
    // Machine-readable details from AmHttpError extras (e.g. reason: 'diagnostic-required').
    if (json.reason !== undefined) err.reason = json.reason;
    if (json.fields !== undefined) err.fields = json.fields;
    throw err;
  }
  return json;
}
