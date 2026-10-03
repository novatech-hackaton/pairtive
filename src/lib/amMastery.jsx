// AmMasteryProvider: loads the signed-in user's Mastery_Records (student_topic_mastery
// joined with topics(topic_name)) and exposes useAmMastery() → { records, count, loading,
// error, refresh }. State is keyed by user id, so records never leak across users
// (Req 8.4), and it self-heals the profile's strong/weak arrays via the Mastery_Bridge
// RPC when they disagree with the stored records (Req 5.4).
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { amSupabase, amFriendlyError } from './amSupabase.js';
import { useAmAuth } from './amAuth.jsx';
import { amApplyBridge } from './amDiagnostic.js';
import { amBridgeMastery, amBridgeMatchesProfile } from '../../shared/amMasteryBridge.js';

const AmMasteryContext = createContext(null);

const AM_MASTERY_COLUMNS =
  'topic_id, mastery_probability, mastery_level, ml_predicted_label, ml_confidence, ' +
  'total_questions, correct_answers, accuracy, average_response_time, updated_at, topics(topic_name)';

const AM_EMPTY = [];

/** Flatten a row's `topics(topic_name)` join into `topic_name`. */
export function amFlattenMasteryRow(row) {
  const { topics, ...rest } = row ?? {};
  const joined = Array.isArray(topics) ? topics[0] : topics;
  return { ...rest, topic_name: joined?.topic_name ?? null };
}

export function AmMasteryProvider({ children }) {
  const { user, profile, loading: authLoading, refreshProfile } = useAmAuth();
  const uid = user?.id ?? null;

  // `uid` is the user these records belong to; `loaded` is false until the first
  // load for that user settles.
  const [state, setState] = useState({ uid: null, records: AM_EMPTY, error: null, loaded: false });
  const [bridgeError, setBridgeError] = useState(null);
  const reqRef = useRef(0);
  const uidRef = useRef(uid);
  uidRef.current = uid;
  const healedRef = useRef(null);

  const load = useCallback(async (forUid) => {
    const req = ++reqRef.current;
    const current = () => req === reqRef.current && uidRef.current === forUid;
    if (!forUid || !amSupabase) {
      if (current()) setState({ uid: forUid, records: AM_EMPTY, error: null, loaded: true });
      return AM_EMPTY;
    }
    try {
      const { data, error } = await amSupabase
        .from('student_topic_mastery')
        .select(AM_MASTERY_COLUMNS)
        .eq('user_id', forUid);
      if (error) throw new Error(amFriendlyError(error));
      const records = (data ?? []).map(amFlattenMasteryRow);
      if (current()) setState({ uid: forUid, records, error: null, loaded: true });
      return records;
    } catch (err) {
      // Late failures from a previous user are ignored, like late successes.
      if (current()) {
        setState((prev) => ({
          uid: forUid,
          records: prev.uid === forUid ? prev.records : AM_EMPTY,
          error: err?.message || 'Could not load your diagnostic results.',
          loaded: true,
        }));
      }
      return null;
    }
  }, []);

  // Reset and reload whenever the signed-in user changes (including sign-out to null).
  useEffect(() => {
    healedRef.current = null;
    setBridgeError(null);
    setState({ uid, records: AM_EMPTY, error: null, loaded: false });
    load(uid);
  }, [uid, load]);

  const refresh = useCallback(() => {
    const forUid = uidRef.current;
    // Retrying after an error shows the loader again; a normal refresh keeps the
    // current records visible until the new ones arrive.
    setState((prev) => (prev.uid === forUid && prev.error ? { ...prev, error: null, loaded: false } : prev));
    return load(forUid);
  }, [load]);

  const ready = !!uid && state.uid === uid && state.loaded;
  const records = state.uid === uid ? state.records : AM_EMPTY;

  // Self-heal: at most one bridge call per user/records load.
  useEffect(() => {
    if (!ready || state.error || authLoading || !profile) return;
    if (state.records.length === 0 || healedRef.current === state.records) return;
    healedRef.current = state.records;
    if (amBridgeMatchesProfile(profile, amBridgeMastery(state.records))) return;
    const forUid = uid;
    (async () => {
      try {
        await amApplyBridge();
        if (uidRef.current === forUid) await refreshProfile();
        if (uidRef.current === forUid) setBridgeError(null);
      } catch (err) {
        console.warn('Mastery bridge self-heal failed:', err);
        if (uidRef.current === forUid) setBridgeError(err?.message || 'Could not update your profile.');
      }
    })();
  }, [ready, state.error, state.records, authLoading, profile, uid, refreshProfile]);

  const value = useMemo(
    () => ({
      records,
      count: records.length,
      loading: authLoading || (!!uid && !ready),
      error: state.uid === uid ? state.error : null,
      bridgeError,
      refresh,
    }),
    [records, authLoading, uid, ready, state.uid, state.error, bridgeError, refresh],
  );

  return <AmMasteryContext.Provider value={value}>{children}</AmMasteryContext.Provider>;
}

export function useAmMastery() {
  const ctx = useContext(AmMasteryContext);
  if (!ctx) throw new Error('useAmMastery must be used inside AmMasteryProvider');
  return ctx;
}
