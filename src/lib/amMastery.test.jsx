import { beforeEach, describe, expect, it, vi } from 'vitest';
import { act, renderHook, waitFor } from '@testing-library/react';

// Fake amSupabase: each `from()` call is logged; awaiting it resolves the next queued
// deferred response so tests can control ordering (late responses from older users).
const am = vi.hoisted(() => {
  const state = { calls: [], pending: [] };
  const client = {
    from(table) {
      const entry = { table, ops: [] };
      state.calls.push(entry);
      let resolveFn;
      const promise = new Promise((r) => {
        resolveFn = r;
      });
      state.pending.push(resolveFn);
      const b = {};
      for (const op of ['select', 'eq']) {
        b[op] = (...args) => {
          entry.ops.push([op, ...args]);
          return b;
        };
      }
      b.then = (res, rej) => promise.then(res, rej);
      return b;
    },
  };
  const auth = { value: null };
  return { state, client, auth, applyBridge: vi.fn() };
});

vi.mock('./amSupabase.js', async (importOriginal) => ({ ...(await importOriginal()), amSupabase: am.client }));
vi.mock('./amAuth.jsx', () => ({ useAmAuth: () => am.auth.value }));
vi.mock('./amDiagnostic.js', () => ({ amApplyBridge: am.applyBridge }));

const { AmMasteryProvider, useAmMastery } = await import('./amMastery.jsx');

const A = { id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' };
const B = { id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' };
const row = (topic_name, mastery_level) => ({
  topic_id: `t-${topic_name}`,
  mastery_probability: mastery_level === 'Proficient' ? 0.9 : 0.2,
  mastery_level,
  updated_at: '2024-01-01T00:00:00Z',
  topics: { topic_name },
});
const matchingProfile = { subjects_source: 'diagnostic', strong_subjects: ['Arrays'], weak_subjects: ['Graphs'] };

function setAuth(user, profile = matchingProfile) {
  am.auth.value = { user, profile, loading: false, refreshProfile: am.auth.refreshProfile };
}

function render() {
  return renderHook(() => useAmMastery(), { wrapper: ({ children }) => <AmMasteryProvider>{children}</AmMasteryProvider> });
}

beforeEach(() => {
  am.state.calls = [];
  am.state.pending = [];
  am.applyBridge.mockReset().mockResolvedValue({ strong: [], weak: [] });
  am.auth.refreshProfile = vi.fn().mockResolvedValue(null);
});

describe('AmMasteryProvider', () => {
  it('loads the user\'s records filtered by user_id and flattens topic_name', async () => {
    setAuth(A);
    const { result } = render();
    expect(result.current.loading).toBe(true);
    expect(result.current.count).toBe(0);

    const call = am.state.calls[am.state.calls.length - 1];
    expect(call.table).toBe('student_topic_mastery');
    expect(call.ops).toContainEqual(['eq', 'user_id', A.id]);
    expect(call.ops.find((o) => o[0] === 'select')[1]).toContain('topics(topic_name)');

    await act(async () => {
      am.state.pending.at(-1)({ data: [row('Arrays', 'Proficient'), row('Graphs', 'Weak')], error: null });
    });
    expect(result.current.loading).toBe(false);
    expect(result.current.count).toBe(2);
    expect(result.current.records[0]).toMatchObject({ topic_id: 't-Arrays', topic_name: 'Arrays', mastery_level: 'Proficient' });
    expect(result.current.records[0].topics).toBeUndefined();
    expect(am.applyBridge).not.toHaveBeenCalled();
  });

  it('resets on user change and ignores a late response from the previous user', async () => {
    setAuth(A);
    const { result, rerender } = render();
    const lateForA = am.state.pending.at(-1);

    setAuth(B, null);
    rerender();
    expect(result.current.loading).toBe(true);
    expect(result.current.count).toBe(0);

    await act(async () => {
      lateForA({ data: [row('Arrays', 'Proficient')], error: null });
    });
    expect(result.current.count).toBe(0);
    expect(result.current.loading).toBe(true);

    await act(async () => {
      am.state.pending.at(-1)({ data: [], error: null });
    });
    expect(result.current.loading).toBe(false);
    expect(result.current.count).toBe(0);

    setAuth(null, null);
    rerender();
    expect(result.current.records).toEqual([]);
    expect(result.current.loading).toBe(false);
  });

  it('self-heals once when the profile does not match the bridged records', async () => {
    setAuth(A, { subjects_source: 'manual', strong_subjects: [], weak_subjects: [] });
    const { rerender } = render();
    await act(async () => {
      am.state.pending.at(-1)({ data: [row('Arrays', 'Proficient')], error: null });
    });
    await waitFor(() => expect(am.auth.refreshProfile).toHaveBeenCalledTimes(1));
    expect(am.applyBridge).toHaveBeenCalledTimes(1);

    // A new profile object (still mismatched) does not trigger another call.
    setAuth(A, { subjects_source: 'manual', strong_subjects: [], weak_subjects: [] });
    rerender();
    await act(async () => {});
    expect(am.applyBridge).toHaveBeenCalledTimes(1);
  });

  it('exposes load errors and recovers on refresh', async () => {
    setAuth(A);
    const { result } = render();
    await act(async () => {
      am.state.pending.at(-1)({ data: null, error: { message: 'boom' } });
    });
    expect(result.current.error).toBe('boom');
    expect(result.current.loading).toBe(false);

    let p;
    act(() => {
      p = result.current.refresh();
    });
    expect(result.current.loading).toBe(true);
    await act(async () => {
      am.state.pending.at(-1)({ data: [row('Graphs', 'Weak')], error: null });
      await p;
    });
    expect(result.current.error).toBeNull();
    expect(result.current.count).toBe(1);
  });
});
