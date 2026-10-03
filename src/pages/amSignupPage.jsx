import { useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, Lock, Mail, MailCheck, UserRound } from 'lucide-react';
import { amSupabase, amFriendlyError } from '../lib/amSupabase.js';
import { AmButton } from '../components/amButton.jsx';
import { AmField } from '../components/amField.jsx';
import { AmEmptyState } from '../components/amEmptyState.jsx';
import { AmAuthShell, AmGoogleIcon } from './amAuthShell.jsx';
import { amSignInWithGoogle } from './amLoginPage.jsx';
import { AmStepper } from './amOnboardingPage.jsx';

export function amValidateSignup({ name, email, password }) {
  const errors = {};
  if (name.trim().length < 2) errors.name = 'Enter your name.';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) errors.email = 'Enter a valid email.';
  if (password.length < 8) errors.password = 'Use at least 8 characters.';
  else if (!/[A-Za-z]/.test(password) || !/\d/.test(password)) errors.password = 'Mix letters and numbers.';
  return errors;
}

export default function AmSignupPage() {
  const [form, setForm] = useState({ name: '', email: '', password: '' });
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);
  const [sentTo, setSentTo] = useState('');
  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  async function onSubmit(e) {
    e.preventDefault();
    const v = amValidateSignup(form);
    setErrors(v);
    if (Object.keys(v).length) return;
    setBusy(true);
    const { data, error } = await amSupabase.auth.signUp({
      email: form.email.trim(),
      password: form.password,
      options: { data: { full_name: form.name.trim() }, emailRedirectTo: `${window.location.origin}/onboarding` },
    });
    setBusy(false);
    if (error) return setErrors({ form: amFriendlyError(error) });
    if (!data.session) setSentTo(form.email.trim()); // email confirmation enabled
    // With a session, the auth guard sends the user straight to onboarding.
  }

  if (sentTo) {
    return (
      <AmAuthShell>
        <AmEmptyState
          icon={MailCheck}
          title="Check your inbox"
          description={`We sent a confirmation link to ${sentTo}. Open it to finish setting up your profile.`}
          action={
            <Link to="/login" className="text-sm font-medium text-brand-cyan hover:underline">
              Back to sign in
            </Link>
          }
        />
      </AmAuthShell>
    );
  }

  return (
    <AmAuthShell>
      <AmStepper steps={['Account', 'About you', 'Subjects']} current={0} />
      <h1 className="mt-6 text-3xl font-bold text-white">Create your account</h1>
      <p className="mt-2 text-slate-400">It takes about a minute. Then we&apos;ll find your first match.</p>

      <AmButton variant="secondary" size="lg" className="mt-8 w-full" onClick={amSignInWithGoogle}>
        <AmGoogleIcon />
        Sign up with Google
      </AmButton>
      <div className="my-6 flex items-center gap-3 text-xs text-slate-500" aria-hidden>
        <span className="h-px flex-1 bg-white/10" /> or with email <span className="h-px flex-1 bg-white/10" />
      </div>

      <form onSubmit={onSubmit} className="space-y-4" noValidate>
        <AmField label="Full name" autoComplete="name" icon={UserRound} value={form.name} onChange={set('name')} error={errors.name} maxLength={60} />
        <AmField label="Email" type="email" autoComplete="email" icon={Mail} value={form.email} onChange={set('email')} error={errors.email} />
        <AmField
          label="Password"
          type="password"
          autoComplete="new-password"
          icon={Lock}
          value={form.password}
          onChange={set('password')}
          error={errors.password}
          hint="At least 8 characters, with letters and numbers."
        />
        {errors.form ? (
          <p className="text-sm text-rose-300" role="alert">
            {errors.form}
          </p>
        ) : null}
        <AmButton type="submit" size="lg" className="w-full" loading={busy} iconRight={ArrowRight}>
          Continue
        </AmButton>
      </form>
      <p className="mt-6 text-center text-sm text-slate-400">
        Already have an account?{' '}
        <Link to="/login" className="font-medium text-brand-cyan hover:underline">
          Sign in
        </Link>
      </p>
    </AmAuthShell>
  );
}
