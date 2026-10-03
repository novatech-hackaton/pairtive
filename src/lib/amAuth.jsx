import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { amSupabase } from './amSupabase.js';
import { amIsProfileComplete } from '../../shared/amSubjects.js';

const AmAuthContext = createContext(null);

export function AmAuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [profile, setProfile] = useState(null);
  const [sessionReady, setSessionReady] = useState(false);
  // uid whose profile is currently loaded (prevents a flash of "incomplete profile" after sign-in)
  const [loadedUid, setLoadedUid] = useState(null);

  const loadProfile = useCallback(async (uid) => {
    if (!uid) {
      setProfile(null);
      setLoadedUid(null);
      return null;
    }
    const { data } = await amSupabase.from('profiles').select('*').eq('id', uid).maybeSingle();
    setProfile(data ?? null);
    setLoadedUid(uid);
    return data;
  }, []);

  useEffect(() => {
    if (!amSupabase) {
      setSessionReady(true);
      return undefined;
    }
    let active = true;
    amSupabase.auth.getSession().then(({ data }) => {
      if (!active) return;
      setSession(data.session);
      setSessionReady(true);
      loadProfile(data.session?.user?.id);
    });
    const { data: sub } = amSupabase.auth.onAuthStateChange((event, next) => {
      setSession(next);
      if (event === 'SIGNED_IN' || event === 'SIGNED_OUT' || event === 'USER_UPDATED') {
        // Defer DB calls out of the auth callback (supabase-js recommendation).
        setTimeout(() => loadProfile(next?.user?.id), 0);
      }
    });
    return () => {
      active = false;
      sub.subscription.unsubscribe();
    };
  }, [loadProfile]);

  const uid = session?.user?.id ?? null;
  const value = useMemo(
    () => ({
      session,
      user: session?.user ?? null,
      profile: uid && loadedUid === uid ? profile : null,
      loading: !sessionReady || (!!uid && loadedUid !== uid),
      profileComplete: amIsProfileComplete(profile),
      isSuspended: !!profile && profile.status === 'suspended' && new Date(profile.suspended_until) > new Date(),
      refreshProfile: () => loadProfile(uid),
      setProfile,
      signOut: async () => {
        await amSupabase.auth.signOut();
        setProfile(null);
        setLoadedUid(null);
      },
    }),
    [session, uid, profile, loadedUid, sessionReady, loadProfile],
  );

  return <AmAuthContext.Provider value={value}>{children}</AmAuthContext.Provider>;
}

export function useAmAuth() {
  const ctx = useContext(AmAuthContext);
  if (!ctx) throw new Error('useAmAuth must be used inside AmAuthProvider');
  return ctx;
}
