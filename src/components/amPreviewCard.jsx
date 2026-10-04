import { motion } from 'motion/react';
import { Check, Clock, Globe, GraduationCap, Handshake, Lightbulb, SkipForward, Sparkles, Users } from 'lucide-react';
import { amTeachLearnCopy } from '../../shared/amMatchScore.js';
import { AmAvatar } from './amAvatar.jsx';
import { AmButton } from './amButton.jsx';
import { AmCountdownRing } from './amCountdownRing.jsx';
import { AmRatingBadge } from './amStars.jsx';
import { AmSubjectIcon } from './amSubjectChip.jsx';

function AmCopyRow({ item, tone }) {
  // Highlight the subject where the copy template puts it ("... with Math" or "Practice Algebra together ..."),
  // so a partner name that contains the subject (e.g. "Mathilda") is not highlighted instead.
  const lead = 'Practice ' + item.subject + ' ';
  const tail = ' ' + item.subject;
  const at = item.text.startsWith(lead)
    ? 'Practice'.length
    : item.text.endsWith(tail)
      ? item.text.length - tail.length
      : item.text.indexOf(tail);
  const before = at === -1 ? item.text : item.text.slice(0, at + 1);
  const after = at === -1 ? '' : item.text.slice(at + 1 + item.subject.length);
  return (
    <li className="flex items-center gap-3 rounded-2xl bg-white/[0.04] p-3 ring-1 ring-white/8">
      <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-white/6">
        <AmSubjectIcon subject={item.subject} className="size-5" />
      </span>
      <span className="min-w-0 text-sm break-words text-slate-200">
        {before}
        <strong className={tone}>{item.subject}</strong>
        {after}
      </span>
    </li>
  );
}

/**
 * Match preview: who they are, what you will swap, and 15s to Accept or Next.
 * members: [{ user_id, accepted, profile }]
 */
export function AmPreviewCard({ me, myId, members, mode, secondsLeft, total = 15, myResponse, busy, onAccept, onNext }) {
  const others = members.filter((m) => m.user_id !== myId);
  const otherProfiles = others.map((m) => ({
    name: m.profile?.name ?? 'Student',
    weak: m.profile?.weak_subjects ?? [],
    strong: m.profile?.strong_subjects ?? [],
  }));
  const copy = amTeachLearnCopy({ weak: me.weak_subjects, strong: me.strong_subjects }, otherProfiles);
  const practice = copy.practice ?? [];
  const myLangs = new Set((me.languages ?? []).map((l) => l.toLowerCase()));
  const waitingOn = others.filter((m) => m.accepted !== true).map((m) => m.profile?.name ?? 'Student');

  return (
    <motion.section
      initial={{ y: 40, opacity: 0, scale: 0.96 }}
      animate={{ y: 0, opacity: 1, scale: 1 }}
      exit={{ y: 30, opacity: 0 }}
      transition={{ type: 'spring', stiffness: 300, damping: 26 }}
      className="@container glass-strong relative scroll-mb-32 overflow-hidden rounded-[2rem] p-4 shadow-glow sm:p-7 md:scroll-mb-8"
      aria-labelledby="am-preview-title"
      aria-describedby="am-preview-headline"
    >
      <div className="absolute -top-20 -right-20 size-56 rounded-full bg-brand-violet/30 blur-3xl" aria-hidden />
      <div className="relative flex items-start justify-between gap-3 sm:gap-4">
        <div className="min-w-0 flex-1">
          <p className="inline-flex items-center gap-1.5 rounded-full bg-emerald-400/15 px-3 py-1 text-xs font-semibold text-emerald-300 ring-1 ring-emerald-400/30">
            <Sparkles className="size-3.5" aria-hidden /> {mode === 'peers' ? 'Study group found' : 'Match found'}
          </p>
          <h2 id="am-preview-title" className="mt-3 text-xl font-bold break-words text-white sm:text-3xl">
            {mode === 'peers' ? 'You + ' + others.length + ' study peers' : 'Meet ' + (others[0]?.profile?.name ?? 'your buddy')}
          </h2>
          <p id="am-preview-headline" className="mt-1 text-sm text-slate-300 sm:text-base">{copy.headline}</p>
        </div>
        <AmCountdownRing secondsLeft={secondsLeft} total={total} className="size-12 sm:size-16" />
      </div>

      <ul className={'relative mt-5 grid gap-3 sm:mt-6 ' + (others.length > 1 ? '@lg:grid-cols-2' : '')}>
        {others.map((m) => {
          const p = m.profile ?? {};
          return (
            <li key={m.user_id} className="flex min-w-0 items-center gap-3 rounded-3xl bg-white/[0.04] p-3 ring-1 ring-white/10 sm:gap-4 sm:p-4">
              <span className="relative shrink-0">
                <AmAvatar name={p.name} src={p.avatar_url} size="lg" ring />
                {m.accepted ? (
                  <span className="absolute -right-1 -bottom-1 grid size-6 place-items-center rounded-full bg-emerald-400 text-ink-950 ring-2 ring-ink-900" title="Accepted">
                    <Check className="size-3.5" strokeWidth={3} aria-hidden />
                    <span className="am-sr-only">accepted</span>
                  </span>
                ) : null}
              </span>
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <p className="max-w-full min-w-0 truncate text-base font-semibold text-white sm:text-lg">{p.name}</p>
                  <AmRatingBadge avg={p.rating_avg} count={p.rating_count} />
                </div>
                <p className="mt-1 flex min-w-0 items-center gap-1.5 text-sm text-slate-400">
                  <GraduationCap className="size-4 shrink-0" aria-hidden /> <span className="min-w-0 truncate">{p.school}</span>
                </p>
                <p className="mt-1.5 flex flex-wrap items-center gap-1.5 text-xs">
                  <Globe className="size-3.5 shrink-0 text-slate-400" aria-hidden />
                  <span className="am-sr-only">Languages:</span>
                  {(p.languages ?? []).map((l) => (
                    <span key={l} className={'rounded-full px-2 py-0.5 ' + (myLangs.has(l.toLowerCase()) ? 'bg-brand-cyan/15 text-cyan-200 ring-1 ring-brand-cyan/40' : 'bg-white/6 text-slate-300')}>
                      {l}
                      {myLangs.has(l.toLowerCase()) ? <span className="am-sr-only"> (you share this)</span> : null}
                    </span>
                  ))}
                </p>
              </div>
            </li>
          );
        })}
      </ul>

      <div className="relative mt-5 grid gap-4 @xl:grid-cols-2">
        <div>
          <p className="mb-2 flex items-center gap-2 text-xs font-semibold tracking-wide text-emerald-300 uppercase">
            <Handshake className="size-4" aria-hidden /> You are the tutor for
          </p>
          <ul className="space-y-2">
            {copy.teach.length ? copy.teach.map((t) => <AmCopyRow key={t.subject} item={t} tone="text-emerald-300" />) : <li className="text-sm text-slate-500">Nothing this time: just enjoy learning.</li>}
          </ul>
        </div>
        <div>
          <p className="mb-2 flex items-center gap-2 text-xs font-semibold tracking-wide text-amber-300 uppercase">
            <Lightbulb className="size-4" aria-hidden /> You will learn
          </p>
          <ul className="space-y-2">
            {copy.learn.length ? copy.learn.map((t) => <AmCopyRow key={t.subject} item={t} tone="text-amber-300" />) : <li className="text-sm text-slate-500">Nothing this time: you get to share what you know.</li>}
          </ul>
        </div>
      </div>

      {practice.length > 0 ? (
        <div className="relative mt-4">
          <p className="mb-2 flex items-center gap-2 text-xs font-semibold tracking-wide text-cyan-300 uppercase">
            <Users className="size-4" aria-hidden /> You'll practice together
          </p>
          <ul className="space-y-2">
            {practice.map((t) => <AmCopyRow key={t.subject} item={t} tone="text-cyan-300" />)}
          </ul>
        </div>
      ) : null}

      <div className="relative mt-6">
        {myResponse === true ? (
          <p className="flex items-center justify-center gap-2 rounded-2xl bg-white/[0.04] p-4 text-sm text-slate-300" role="status">
            <Clock className="size-4 text-brand-cyan" aria-hidden />
            {waitingOn.length ? 'You are in! Waiting for ' + waitingOn.join(', ') + '…' : 'Everyone accepted. Joining…'}
          </p>
        ) : (
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <AmButton variant="secondary" size="lg" icon={SkipForward} onClick={onNext} disabled={busy} className="w-full scroll-mb-32 md:scroll-mb-8">Next</AmButton>
            <AmButton variant="success" size="lg" icon={Check} onClick={onAccept} loading={busy} data-autofocus className="w-full scroll-mb-32 md:scroll-mb-8">Accept</AmButton>
          </div>
        )}
      </div>
    </motion.section>
  );
}
