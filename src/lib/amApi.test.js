import { afterEach, describe, expect, it, vi } from 'vitest';

vi.mock('./amSupabase.js', () => ({
  amSupabase: { auth: { getSession: async () => ({ data: { session: { access_token: 'tok' } } }) } },
}));

const { amApi } = await import('./amApi.js');

function stubFetch(status, body) {
  const fetchMock = vi.fn(async () => ({ ok: status >= 200 && status < 300, status, json: async () => body }));
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}

afterEach(() => vi.unstubAllGlobals());

describe('amApi', () => {
  it('copies reason and status onto the thrown error', async () => {
    stubFetch(403, { error: 'Take the diagnostic before matching.', reason: 'diagnostic-required' });
    const err = await amApi('amMatch').catch((e) => e);
    expect(err).toBeInstanceOf(Error);
    expect(err.message).toBe('Take the diagnostic before matching.');
    expect(err.status).toBe(403);
    expect(err.reason).toBe('diagnostic-required');
    expect(err).not.toHaveProperty('fields');
  });

  it('copies fields when present and omits reason when absent', async () => {
    stubFetch(400, { error: 'Invalid request', fields: ['topic_id: unknown topic'] });
    const err = await amApi('amPredict', { topic_id: 'x' }).catch((e) => e);
    expect(err.status).toBe(400);
    expect(err.fields).toEqual(['topic_id: unknown topic']);
    expect(err).not.toHaveProperty('reason');
  });

  it('returns the JSON body and sends the bearer token on success', async () => {
    const fetchMock = stubFetch(200, { status: 'waiting', waiting: 2 });
    await expect(amApi('amMatch')).resolves.toEqual({ status: 'waiting', waiting: 2 });
    expect(fetchMock).toHaveBeenCalledWith('/api/amMatch', expect.objectContaining({ method: 'POST' }));
    expect(fetchMock.mock.calls[0][1].headers.Authorization).toBe('Bearer tok');
  });
});
