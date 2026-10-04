import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'motion/react';
import { Check, Sparkles } from 'lucide-react';
import { amValidateBasics } from '../../shared/amSubjects.js';
import { useAmAuth } from '../lib/amAuth.jsx';
import { amSupabase, amFriendlyError } from '../lib/amSupabase.js';
import { AmButton } from '../components/amButton.jsx';
import { AmCard } from '../components/amCard.jsx';
import { AmLogo } from '../components/amLogo.jsx';
import { amToast } from '../components/amToast.jsx';
import { AmAvatarPicker, AmBasicsFields, amUploadAvatar } from '../components/amProfileFields.jsx';

export function AmStepper({ steps, current }) {
  return (
    <ol className="flex items-center gap-2" aria-label="Progress">
      {steps.map((label, i) => {
        const done = i < current;
        const active = i === current;
        return (
          <li key={label} className="flex items-center gap-2" aria-current={active ? 'step' : undefined}>
            <span
              className={`grid size-7 place-items-center rounded-full text-xs font-bold transition ${
                done ? 'bg-emerald-400 text-ink-950' : active ? 'bg-brand text-white shadow-glow' : 'bg-white/8 text-slate-400'
              }`}
            >
              {done ? <Check className="size-4" strokeWidth={3} aria-hidden /> : i + 1}
            </span>
            <span className={`hidden text-sm sm:inline ${active ? 'font-medium text-white' : 'text-slate-500'}`}>{label}</span>
            <span className="am-sr-only">{done ? '(done)' : active ? '(current)' : ''}</span>
            {i < steps.length - 1 ? <span className={`h-px w-6 sm:w-10 ${done ? 'bg-emerald-400/60' : 'bg-white/10'}`} aria-hidden /> : null}
          </li>
        );
      })}
    </ol>
  );
}

/** Basics only. Strong/weak topics come from the diagnostic (Mastery_Bridge), not from onboarding. */
export default function AmOnboardingPage() {
  const { user, profile, refreshProfile } = useAmAuth();
  const navigate = useNavigate();
  const [basics, setBasics] = useState({
    name: profile?.name || user?.user_metadata?.full_name || '',
    school: profile?.school || '',
    languages: profile?.languages?.length ? profile.languages : ['English'],
  });
  const [avatarFile, setAvatarFile] = useState(null);
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);
  const isEmailUser = user?.app_metadata?.provider === 'email';
  const steps = isEmailUser ? ['Account', 'About you'] : ['About you'];
  const offset = isEmailUser ? 1 : 0;

  async function finish() {
    const v = amValidateBasics(basics);
    setErrors(v);
    if (Object.keys(v).length) return;
    setBusy(true);
    try {
      let avatar_url = profile?.avatar_url ?? null;
      if (avatarFile) avatar_url = await amUploadAvatar(user.id, avatarFile);
      const { error } = await amSupabase
        .from('profiles')
        .update({
          name: basics.name.trim(),
          school: basics.school.trim(),
          languages: basics.languages,
          avatar_url,
          onboarded: true,
        })
        .eq('id', user.id);
      if (error) throw error;
      await refreshProfile();
      amToast.success("You're all set!", { description: 'Take the diagnostic to find your first study match.' });
      navigate('/home', { replace: true });
    } catch (e) {
      amToast.error(amFriendlyError(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mx-auto flex min-h-dvh max-w-3xl flex-col px-4 py-8 sm:px-6">
      <div className="mb-8 flex items-center justify-between gap-4">
        <AmLogo />
        <AmStepper steps={steps} current={offset} />
      </div>

      <motion.div key="basics" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }}>
        <h1 className="text-3xl font-bold text-white">Tell us about you</h1>
        <p className="mt-2 text-slate-400">Your buddy sees your name, school and languages before you join a call.</p>
        <AmCard className="mt-6 space-y-6">
          <AmAvatarPicker name={basics.name} src={profile?.avatar_url} file={avatarFile} onFile={setAvatarFile} />
          <AmBasicsFields value={basics} onChange={setBasics} errors={errors} />
        </AmCard>
        <div className="mt-6 flex justify-end">
          <AmButton size="lg" icon={Sparkles} loading={busy} onClick={finish}>
            Finish
          </AmButton>
        </div>
      </motion.div>
    </div>
  );
}
