// Identifier helpers shared by server functions and pure validators.

const AM_UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** True when `v` is a string in canonical 8-4-4-4-12 hex UUID form. */
export const amIsUuid = (v) => typeof v === 'string' && AM_UUID_RE.test(v);
