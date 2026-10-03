import { AmLogo } from '../components/amLogo.jsx';
import { AmCard } from '../components/amCard.jsx';

/** Shown when the Supabase env vars are missing (fresh clone / misconfigured deploy). */
export function AmSetupNotice() {
  return (
    <div className="grid min-h-dvh place-items-center p-6">
      <AmCard className="max-w-lg">
        <AmLogo />
        <h1 className="mt-6 text-2xl font-bold text-white">Almost there</h1>
        <p className="mt-2 text-slate-300">
          Pairtive needs its Supabase keys. Copy <code className="rounded bg-white/10 px-1.5">.env.example</code> to{' '}
          <code className="rounded bg-white/10 px-1.5">.env</code>, fill in <code>VITE_SUPABASE_URL</code> and <code>VITE_SUPABASE_ANON_KEY</code>, then
          restart the dev server. On Vercel, add them under Project Settings → Environment Variables.
        </p>
      </AmCard>
    </div>
  );
}
