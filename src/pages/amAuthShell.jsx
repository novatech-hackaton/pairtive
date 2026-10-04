import { motion } from 'motion/react';
import { ArrowLeftRight, Sparkles, Users, Video } from 'lucide-react';
import { AmLogo } from '../components/amLogo.jsx';
import { AmSubjectChip } from '../components/amSubjectChip.jsx';

const AM_POINTS = [
  { icon: ArrowLeftRight, title: 'Swap what you know', text: "Teach your strong subject, learn your weak one." },
  { icon: Sparkles, title: 'AI matching', text: 'Paired by subjects, ratings and language.' },
  { icon: Video, title: 'Study live', text: 'Video, chat, shared notes and screen share.' },
  { icon: Users, title: 'Buddy or group', text: 'Go 1-on-1, or study with 3 to 5 peers.' },
];

export function AmAuthShell({ children }) {
  return (
    <div className="grid min-h-dvh lg:grid-cols-[1.1fr_1fr]">
      <section className="relative hidden overflow-hidden p-12 lg:flex lg:flex-col lg:justify-between" aria-label="About Pairtive">
        <div className="absolute -top-32 -left-32 size-[32rem] rounded-full bg-brand-indigo/25 blur-3xl" aria-hidden />
        <div className="absolute -right-24 bottom-0 size-[26rem] rounded-full bg-brand-cyan/15 blur-3xl" aria-hidden />
        <AmLogo className="relative" />
        <div className="relative">
          <motion.h1
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            className="max-w-xl text-5xl leading-[1.08] font-extrabold text-white"
          >
            Learn from someone <span className="text-gradient">strong where you&apos;re weak.</span>
          </motion.h1>
          <p className="mt-5 max-w-md text-lg text-slate-300">Pairtive finds your perfect study swap in seconds. You teach, they teach you back.</p>

          <div className="mt-8 flex items-center gap-3" aria-hidden>
            <div className="glass flex flex-col gap-2 rounded-2xl p-3">
              <span className="text-xs text-slate-400">You help with</span>
              <AmSubjectChip subject="English" size="sm" />
            </div>
            <ArrowLeftRight className="size-6 text-brand-cyan" />
            <div className="glass flex flex-col gap-2 rounded-2xl p-3">
              <span className="text-xs text-slate-400">They help with</span>
              <AmSubjectChip subject="Math" size="sm" />
            </div>
          </div>
        </div>
        <ul className="relative grid grid-cols-2 gap-3">
          {AM_POINTS.map((p) => (
            <li key={p.title} className="glass rounded-2xl p-4">
              <p.icon className="size-5 text-brand-cyan" aria-hidden />
              <p className="mt-2 font-semibold text-white">{p.title}</p>
              <p className="text-sm text-slate-400">{p.text}</p>
            </li>
          ))}
        </ul>
      </section>
      <section className="flex items-center justify-center p-5 sm:p-10">
        <div className="w-full max-w-md">
          <AmLogo className="mb-8 lg:hidden" />
          {children}
        </div>
      </section>
    </div>
  );
}
