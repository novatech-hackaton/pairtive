import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { act, renderHook } from '@testing-library/react';

const amMock = vi.hoisted(() => ({ amApi: null }));

vi.mock('./amSupabase.js', () => ({ amSupabase: { rpc: vi.fn(async () => ({ data: null, error: null })) } }));
vi.mock('./amRealtime.js', () => ({ useAmPostgresChanges: () => {} }));
vi.mock('./amApi.js', () => ({ amApi: (...args) => amMock.amApi(...args) }));

const { useAmQueue, AM_POLL_MS } = await import('./amQueue.js');

function httpError(status, message, reason) {
  return Object.assign(new Error(message), { status, ...(reason ? { reason } : {}) });
}

beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

async function startAndPoll(result) {
  await act(async () => {
    await result.current.start('buddy', false);
  });
  await act(async () => {
    await vi.advanceTimersByTimeAsync(AM_POLL_MS);
  });
}

describe('useAmQueue errorReason', () => {
  it('exposes the 403 reason from amMatch and clears it on leave', async () => {
    amMock.amApi = vi.fn(async () => {
      throw httpError(403, 'Take the diagnostic before matching.', 'diagnostic-required');
    });
    const { result } = renderHook(() => useAmQueue('u1'));
    expect(result.current.errorReason).toBeNull();

    await startAndPoll(result);
    expect(result.current.phase).toBe('error');
    expect(result.current.error).toBe('Take the diagnostic before matching.');
    expect(result.current.errorReason).toBe('diagnostic-required');

    await act(async () => {
      await result.current.leave();
    });
    expect(result.current.errorReason).toBeNull();
    expect(result.current.phase).toBe('idle');
  });

  it('keeps errorReason null for a 403 without a reason and for successful polls', async () => {
    amMock.amApi = vi.fn(async () => {
      throw httpError(403, 'Your account is suspended.');
    });
    const { result } = renderHook(() => useAmQueue('u1'));
    await startAndPoll(result);
    expect(result.current.phase).toBe('error');
    expect(result.current.errorReason).toBeNull();

    amMock.amApi = vi.fn(async () => ({ status: 'waiting', waiting: 3 }));
    await startAndPoll(result);
    expect(result.current.phase).toBe('searching');
    expect(result.current.waiting).toBe(3);
    expect(result.current.errorReason).toBeNull();
  });
});

describe('useAmQueue in_session handoff (earlier accepter)', () => {
  const members = [
    { user_id: 'u1', accepted: true, profile: null },
    { user_id: 'u2', accepted: true, profile: null },
  ];
  const pending = { id: 'p1', mode: 'buddy', status: 'pending', expires_at: new Date(Date.now() + 15_000).toISOString(), members: [{ ...members[0] }, { ...members[1], accepted: null }] };
  const accepted = { ...pending, status: 'accepted', members };

  it('starts the session once when a poll reports in_session with the accepted proposal, and a later idle poll keeps it', async () => {
    let matchRes = { status: 'proposed', waiting: 2, proposal: pending };
    const calls = [];
    amMock.amApi = vi.fn(async (name, body) => {
      calls.push([name, body]);
      if (name === 'amStartSession') return { sessionId: 's1' };
      return matchRes;
    });
    const { result } = renderHook(() => useAmQueue('u1'));

    await startAndPoll(result);
    expect(result.current.phase).toBe('preview');
    expect(result.current.myResponse).toBe(true);

    // Other member accepts last; their RPC flips our queue row to in_session.
    matchRes = { status: 'in_session', waiting: 0, proposal: accepted };
    await act(async () => {
      await vi.advanceTimersByTimeAsync(AM_POLL_MS);
    });
    expect(result.current.phase).toBe('starting');
    expect(result.current.sessionId).toBe('s1');
    const starts = calls.filter(([n]) => n === 'amStartSession');
    expect(starts).toEqual([['amStartSession', { proposalId: 'p1' }]]);

    // After the other user's am_mark_joined deletes the rows, polls would say idle.
    matchRes = { status: 'idle' };
    await act(async () => {
      await vi.advanceTimersByTimeAsync(AM_POLL_MS * 3);
    });
    expect(result.current.phase).toBe('starting');
    expect(result.current.sessionId).toBe('s1');
    expect(calls.filter(([n]) => n === 'amStartSession')).toHaveLength(1);
  });

  it('does not reset to idle when in_session arrives without a proposal', async () => {
    let matchRes = { status: 'proposed', waiting: 2, proposal: pending };
    amMock.amApi = vi.fn(async () => matchRes);
    const { result } = renderHook(() => useAmQueue('u1'));
    await startAndPoll(result);
    expect(result.current.phase).toBe('preview');

    matchRes = { status: 'in_session', waiting: 0 };
    await act(async () => {
      await vi.advanceTimersByTimeAsync(AM_POLL_MS);
    });
    expect(result.current.phase).toBe('preview');
    expect(result.current.proposal?.id).toBe('p1');
  });
});
