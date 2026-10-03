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
