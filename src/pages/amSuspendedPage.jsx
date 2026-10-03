import { useEffect } from 'react';
import { Navigate } from 'react-router-dom';
import { LogOut, ShieldAlert } from 'lucide-react';
import { useAmAuth } from '../lib/amAuth.jsx';
import { useAmNow } from '../lib/amHooks.js';
import { amDateTime } from '../lib/amFormat.js';
import { AmButton } from '../components/amButton.jsx';
import { AmCard } from '../components/amCard.jsx';
import { AmLogo } from '../components/amLogo.jsx';

function amRemaining(ms) {
  const s = Math.max(0, Math.floor(ms / 1000));
  const d = Math.floor(s / 86400);
  const h = Math.floor((s % 86400) / 3600);
  const m = Math.floor((s % 3600) / 60);
  if (d) return `${d}d ${h}h`;
  if (h) return `${h}h ${m}m`;
  return `${m}m ${s % 60}s`;
}

export default function AmSuspendedPage() {
  const { profile, isSuspended, refreshProfile, signOut } = useAmAuth();
  const now = useAmNow(1000);
  const until = profile?.suspended_until ? new Date(profile.suspended_until).getTime() : 0;

  useEffect(() => {
    if (until && now >= until) refreshProfile();
  }, [now, until, refreshProfile]);

  if (!isSuspended) return <Navigate to="/home" replace />;

  return (
    <div className="grid min-h-dvh place-items-center p-5">
      <div className="w-full max-w-lg">
        <AmLogo className="mb-8" />
        <AmCard className="text-center">
          <span className="mx-auto grid size-16 place-items-center rounded-full bg-rose-500/15 ring-1 ring-rose-400/40">
            <ShieldAlert className="size-8 text-rose-300" aria-hidden />
          </span>
          <h1 className="mt-5 text-2xl font-bold text-white">Your account is paused</h1>
          <p className="mt-2 text-slate-300">{profile.suspension_reason || 'Your account was suspended after a report.'}</p>
          <div className="mt-6 rounded-2xl bg-white/[0.04] p-4 ring-1 ring-white/10">
            <p className="text-xs tracking-wide text-slate-400 uppercase">You can study again in</p>
            <p className="mt-1 font-display text-3xl font-bold text-white" aria-live="off">
              {amRemaining(until - now)}
            </p>
            <p className="mt-1 text-sm text-slate-400">on {amDateTime(until)}</p>
          </div>
          <p className="mt-6 text-sm text-slate-400">
            Reports are checked automatically by AI. Please review the community rules: be respectful, keep your camera appropriate, stay on topic and don&apos;t share
            personal contact info.
          </p>
          <AmButton variant="secondary" icon={LogOut} className="mt-6" onClick={signOut}>
            Sign out
          </AmButton>
        </AmCard>
      </div>
    </div>
  );
}
