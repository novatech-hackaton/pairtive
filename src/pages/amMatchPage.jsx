import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AnimatePresence, motion } from 'motion/react';
import { ArrowLeft, Sparkles, Users, UserRound, X } from 'lucide-react';
import { useAmAuth } from '../lib/amAuth.jsx';
import { amSupabase } from '../lib/amSupabase.js';
import { amPeekLocalStream, amStopLocalStream } from '../lib/amMedia.js';
import { useAmQueue } from '../lib/amQueue.js';
import { useAmNow } from '../lib/amHooks.js';
import { AmButton } from '../components/amButton.jsx';
import { AmCard } from '../components/amCard.jsx';
import { AmCameraPreview } from '../components/amCameraPreview.jsx';
import { AmRulesCard } from '../components/amRulesCard.jsx';
import { AmHowMatchingWorks } from '../components/amHowMatchingWorks.jsx';
import { AmRadar } from '../components/amRadar.jsx';
import { AmPreviewCard } from '../components/amPreviewCard.jsx';
import { AmSwitch } from '../components/amField.jsx';
import { amToast } from '../components/amToast.jsx';

const AM_MODES = [
  { id: 'buddy', title: 'Study Buddy', line: '1-on-1', icon: UserRound, blurb: 'A focused two-way swap with one partner.' },
  { id: 'peers', title: 'Study Peers', line: '3 to 5', icon: Users, blurb: 'A small group where everyone teaches and learns.' },
];

export default function AmMatchPage() {
  const { user, profile, refreshProfile } = useAmAuth();
  const navigate = useNavigate();
  const q = useAmQueue(user.id);
  const [mode, setMode] = useState('buddy');
  const [sameSchool, setSameSchool] = useState(false);
  const [agreed, setAgreed] = useState(false);
  const rulesAccepted = !!profile.rules_accepted_at;
  const searchStart = useRef(Date.now());
  const now = useAmNow(1000);

  useEffect(() => {
    return () => {
      amSupabase.rpc('am_leave_queue');
      if (q.phase !== 'starting') amStopLocalStream();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (q.phase === 'starting' && q.sessionId) {
      navigate('/session/' + q.sessionId, { replace: true });
    }
  }, [q.phase, q.sessionId, navigate]);

  useEffect(() => {
    if (q.phase === 'searching') searchStart.current = Date.now();
  }, [q.phase]);

  async function onFind() {
    if (!rulesAccepted && !agreed) {
      amToast.error('Please agree to the community rules first.');
      return;
    }
    if (!rulesAccepted) {
      await amSupabase.from('profiles').update({ rules_accepted_at: new Date().toISOString() }).eq('id', user.id);
      await refreshProfile();
    }
    q.start(mode, sameSchool);
  }

  const previewMembers = q.proposal?.members ?? [];
  const expiresAt = q.proposal ? new Date(q.proposal.expires_at).getTime() : 0;
  const secondsLeft = Math.max(0, (expiresAt - now) / 1000);
  const searchSeconds = Math.floor((now - searchStart.current) / 1000);

  return (
    <div className="mx-auto max-w-3xl">
      <div className="mb-5 flex items-center gap-3">
        <AmButton variant="ghost" size="sm" icon={ArrowLeft} onClick={() => navigate('/home')}>
          Home
        </AmButton>
        <h1 className="text-2xl font-bold text-white">Find a match</h1>
      </div>

      <div className="sticky top-20 z-10 mb-5">
        <AmCameraPreview name={profile.name} compact={q.phase === 'idle' || q.phase === 'error'} />
      </div>

      <AnimatePresence mode="wait">
        {q.phase === 'preview' && q.proposal ? (
          <AmPreviewCard
            key="preview"
            me={profile}
            myId={user.id}
            members={previewMembers}
            mode={q.proposal.mode}
            secondsLeft={secondsLeft}
            total={15}
            myResponse={q.myResponse}
            onAccept={() => q.respond(true)}
            onNext={() => q.respond(false)}
          />
        ) : q.phase === 'searching' || q.phase === 'starting' ? (
          <motion.div key="searching" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            <AmCard className="flex flex-col items-center text-center">
              <AmRadar name={profile.name} avatarUrl={profile.avatar_url} subjects={[...profile.weak_subjects, ...profile.strong_subjects]} />
              <h2 className="mt-6 text-xl font-semibold text-white" aria-live="polite">
                {q.phase === 'starting' ? 'Starting your session…' : mode === 'peers' ? 'Gathering your study group…' : 'Looking for your match…'}
              </h2>
              <p className="mt-1 text-sm text-slate-400" aria-live="polite">
                {q.waiting > 1 ? q.waiting + ' students searching right now' : 'Hang tight, this usually takes a few seconds'} · {searchSeconds}s
              </p>
              {searchSeconds >= 30 && mode === 'buddy' ? (
                <p className="mt-2 text-xs text-brand-cyan">Widening the search to one-way matches too…</p>
              ) : null}
              <AmButton variant="secondary" icon={X} className="mt-6" onClick={() => q.leave()}>
                Cancel
              </AmButton>
            </AmCard>
          </motion.div>
        ) : (
          <motion.div key="idle" initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} className="space-y-5">
            <AmCard>
              <h2 className="mb-3 text-lg font-semibold text-white">How do you want to study?</h2>
              <div className="grid gap-3 sm:grid-cols-2" role="radiogroup" aria-label="Match mode">
                {AM_MODES.map((m) => {
                  const on = mode === m.id;
                  return (
                    <button
                      key={m.id}
                      type="button"
                      role="radio"
                      aria-checked={on}
                      onClick={() => setMode(m.id)}
                      className={'rounded-3xl p-5 text-left ring-1 transition ' + (on ? 'bg-white/10 ring-2 ring-brand-violet shadow-glow' : 'bg-white/[0.03] ring-white/10 hover:bg-white/[0.06]')}
                    >
                      <div className="flex items-center gap-3">
                        <span className="grid size-11 place-items-center rounded-2xl bg-brand text-white shadow-glow">
                          <m.icon className="size-5" aria-hidden />
                        </span>
                        <div>
                          <p className="font-semibold text-white">{m.title}</p>
                          <p className="text-xs text-slate-400">{m.line}</p>
                        </div>
                      </div>
                      <p className="mt-3 text-sm text-slate-300">{m.blurb}</p>
                    </button>
                  );
                })}
              </div>
              <div className="mt-4 border-t border-white/8 pt-4">
                <AmSwitch
                  checked={sameSchool}
                  onChange={setSameSchool}
                  label="Same school only"
                  description={'Only match within ' + (profile.school || 'your school') + '.'}
                />
              </div>
            </AmCard>

            <AmButton size="xl" icon={Sparkles} className="w-full" onClick={onFind} disabled={!rulesAccepted && !agreed}>
              Find match
            </AmButton>

            <AmRulesCard accepted={rulesAccepted} agreed={agreed} onAgreeChange={setAgreed} />
            <AmHowMatchingWorks />

            {q.phase === 'error' && q.error ? (
              <p className="rounded-2xl bg-rose-500/10 p-3 text-center text-sm text-rose-200 ring-1 ring-rose-400/30" role="alert">
                {q.error}
              </p>
            ) : null}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
