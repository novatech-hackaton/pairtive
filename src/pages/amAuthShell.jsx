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

export function AmGoogleIcon() {
  return (
    <svg viewBox="0 0 48 48" className="size-5" aria-hidden>
      <path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3C33.7 32.7 29.2 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.4-.4-3.5z" />
      <path fill="#FF3D00" d="m6.3 14.7 6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z" />
      <path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.2 0-9.6-3.3-11.3-8l-6.5 5C9.5 39.6 16.2 44 24 44z" />
      <path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C37 38.2 44 33 44 24c0-1.3-.1-2.4-.4-3.5z" />
    </svg>
  );
}
