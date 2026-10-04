import { useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, Lock, Mail } from 'lucide-react';
import { amSupabase, amFriendlyError } from '../lib/amSupabase.js';
import { AmButton } from '../components/amButton.jsx';
import { AmField } from '../components/amField.jsx';
import { amToast } from '../components/amToast.jsx';
import { AmAuthShell } from './amAuthShell.jsx';

export default function AmLoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function onSubmit(e) {
    e.preventDefault();
    setError('');
    setBusy(true);
    const { error: err } = await amSupabase.auth.signInWithPassword({ email: email.trim(), password });
    setBusy(false);
    if (err) setError(/invalid/i.test(err.message) ? 'Wrong email or password.' : amFriendlyError(err));
  }

  async function onForgot() {
    if (!email.trim()) {
      setError('Type your email first, then tap "Forgot password".');
      return;
    }
    const { error: err } = await amSupabase.auth.resetPasswordForEmail(email.trim(), { redirectTo: `${window.location.origin}/profile` });
    if (err) amToast.error(amFriendlyError(err));
    else amToast.success('Check your inbox for a reset link.');
  }

  return (
    <AmAuthShell>
      <h1 className="text-3xl font-bold text-white">Welcome back</h1>
      <p className="mt-2 text-slate-400">Sign in to find your next study match.</p>

      <form onSubmit={onSubmit} className="mt-8 space-y-4" noValidate>
        <AmField label="Email" type="email" autoComplete="email" icon={Mail} value={email} onChange={(e) => setEmail(e.target.value)} required />
        <AmField
          label="Password"
          type="password"
          autoComplete="current-password"
          icon={Lock}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        {error ? (
          <p className="text-sm text-rose-300" role="alert">
            {error}
          </p>
        ) : null}
        <AmButton type="submit" size="lg" className="w-full" loading={busy} iconRight={ArrowRight}>
          Sign in
        </AmButton>
      </form>
      <div className="mt-6 flex items-center justify-between text-sm">
        <button type="button" onClick={onForgot} className="text-slate-400 hover:text-white">
          Forgot password?
        </button>
        <Link to="/signup" className="font-medium text-brand-cyan hover:underline">
          Create an account
        </Link>
      </div>
    </AmAuthShell>
  );
}
