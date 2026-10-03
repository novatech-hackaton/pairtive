import { Link, useNavigate } from 'react-router-dom';
import { motion } from 'motion/react';
import { ArrowRight, Handshake, Lightbulb, MessageCircle, Pencil, RotateCcw, Sparkles, Star, Target, Users, Video } from 'lucide-react';
import { useAmAuth } from '../lib/amAuth.jsx';
import { amFirstName } from '../lib/amFormat.js';
import { AmButton } from '../components/amButton.jsx';
import { AmCard, AmCardTitle } from '../components/amCard.jsx';
import { AmSkillSummaryCard } from '../components/amSkillSummaryCard.jsx';
import { AmSubjectChip } from '../components/amSubjectChip.jsx';
import { AmWarningsBanner } from '../components/amWarningsBanner.jsx';

function AmStat({ icon: Icon, label, value, tone }) {
  return (
    <div className="glass flex items-center gap-3 rounded-2xl p-4">
      <span className={`grid size-10 place-items-center rounded-xl ${tone}`}>
        <Icon className="size-5" aria-hidden />
      </span>
      <div>
        <p className="text-xl font-bold text-white">{value}</p>
        <p className="text-xs text-slate-400">{label}</p>
      </div>
    </div>
  );
}

function amGreeting() {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

export default function AmHomePage() {
  const { profile, user } = useAmAuth();
  const navigate = useNavigate();

  return (
    <div>
      <AmWarningsBanner userId={user.id} />

      <motion.section
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="relative overflow-hidden rounded-[2rem] border-gradient p-6 sm:p-10"
        aria-labelledby="am-home-title"
      >
        <div className="absolute -top-24 -right-16 size-72 rounded-full bg-brand-violet/30 blur-3xl" aria-hidden />
        <div className="absolute -bottom-24 left-10 size-64 rounded-full bg-brand-cyan/20 blur-3xl" aria-hidden />
        <div className="relative grid items-center gap-8 lg:grid-cols-[1.4fr_1fr]">
          <div>
            <p className="text-sm font-medium text-brand-cyan">
              {amGreeting()}, {amFirstName(profile.name)}
            </p>
            <h1 id="am-home-title" className="mt-2 text-3xl leading-tight font-extrabold text-white sm:text-5xl">
              Ready to <span className="text-gradient">swap skills</span> today?
            </h1>
            <p className="mt-3 max-w-lg text-slate-300">
              We&apos;ll match you with a student who&apos;s strong where you&apos;re weak, and who needs what you&apos;re great at.
            </p>
            <div className="mt-7 flex flex-wrap gap-3">
              <AmButton size="xl" icon={Sparkles} iconRight={ArrowRight} onClick={() => navigate('/match')}>
                Find match
              </AmButton>
              <AmButton size="xl" variant="secondary" icon={MessageCircle} onClick={() => navigate('/messages')}>
                Messages
              </AmButton>
            </div>
          </div>

          <div className="grid gap-3">
            <div className="glass rounded-3xl p-5">
              <p className="mb-3 flex items-center gap-2 text-sm font-medium text-slate-300">
                <Handshake className="size-4 text-emerald-300" aria-hidden /> You can help with
              </p>
              <div className="flex flex-wrap gap-2">
                {profile.strong_subjects.map((s) => (
                  <AmSubjectChip key={s} subject={s} />
                ))}
              </div>
            </div>
            <div className="glass rounded-3xl p-5">
              <p className="mb-3 flex items-center gap-2 text-sm font-medium text-slate-300">
                <Lightbulb className="size-4 text-amber-300" aria-hidden /> You want help with
              </p>
              <div className="flex flex-wrap gap-2">
                {profile.weak_subjects.map((s) => (
                  <AmSubjectChip key={s} subject={s} />
                ))}
              </div>
            </div>
            {profile.subjects_source === 'diagnostic' ? (
              <Link to="/diagnostic" className="inline-flex items-center gap-1.5 self-end text-sm text-slate-400 hover:text-white">
                <RotateCcw className="size-3.5" aria-hidden /> Retake diagnostic
              </Link>
            ) : (
              <Link to="/profile" className="inline-flex items-center gap-1.5 self-end text-sm text-slate-400 hover:text-white">
                <Pencil className="size-3.5" aria-hidden /> Edit subjects
              </Link>
            )}
          </div>
        </div>
      </motion.section>

      <div className="mt-6">
        <AmSkillSummaryCard />
      </div>

      <section className="mt-6 grid grid-cols-2 gap-3 lg:grid-cols-4" aria-label="Your stats">
        <AmStat icon={Star} label="Average rating" value={profile.rating_count ? Number(profile.rating_avg).toFixed(1) : 'New'} tone="bg-amber-300/15 text-amber-300" />
        <AmStat icon={Users} label="Ratings received" value={profile.rating_count} tone="bg-violet-400/15 text-violet-300" />
        <AmStat icon={Video} label="Sessions" value={profile.sessions_count} tone="bg-cyan-400/15 text-cyan-300" />
        <AmStat
          icon={Target}
          label="Success rate"
          value={profile.sessions_count ? `${Math.round(Number(profile.success_rate) * 100)}%` : '–'}
          tone="bg-emerald-400/15 text-emerald-300"
        />
      </section>

      <div className="mt-6 grid gap-4 md:grid-cols-2">
        <AmCard>
          <AmCardTitle icon={Users} title="Study Buddy" subtitle="1-on-1 swap" />
          <p className="text-sm text-slate-300">One partner, a perfect two-way trade. Best for focused help on a single topic.</p>
        </AmCard>
        <AmCard>
          <AmCardTitle icon={Sparkles} title="Study Peers" subtitle="Groups of 3 to 5" />
          <p className="text-sm text-slate-300">A small group where everyone teaches something and learns something. Great for review sessions.</p>
        </AmCard>
      </div>
    </div>
  );
}
