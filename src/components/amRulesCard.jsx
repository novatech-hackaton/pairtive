import { BookOpenCheck, Camera, CircleDot, Gavel, HeartHandshake, PhoneOff, ScanEye, ShieldCheck } from 'lucide-react';

export const AM_RULES = [
  { icon: HeartHandshake, text: 'Be respectful and patient.' },
  { icon: Camera, text: 'Keep your camera and screen appropriate.' },
  { icon: BookOpenCheck, text: 'Stay on the study topic.' },
  { icon: PhoneOff, text: "Don't share personal contact info." },
  { icon: CircleDot, text: 'Recording needs everyone’s consent.' },
  { icon: ScanEye, text: 'Reports are checked by AI.' },
  { icon: Gavel, text: 'Breaking the rules leads to suspension.' },
];

function AmRuleList() {
  return (
    <ul className="grid gap-2 sm:grid-cols-2">
      {AM_RULES.map((r) => (
        <li key={r.text} className="flex items-center gap-2.5 rounded-xl bg-white/[0.03] px-3 py-2.5 text-sm text-slate-200 ring-1 ring-white/5">
          <r.icon className="size-4 shrink-0 text-brand-cyan" aria-hidden />
          {r.text}
        </li>
      ))}
    </ul>
  );
}

/**
 * First time: full list + required "I agree" checkbox.
 * Afterwards: a collapsed reminder.
 */
export function AmRulesCard({ accepted, agreed, onAgreeChange }) {
  if (accepted) {
    return (
      <details className="group glass rounded-2xl px-4 py-3">
        <summary className="flex cursor-pointer list-none items-center gap-2 text-sm text-slate-300 [&::-webkit-details-marker]:hidden">
          <ShieldCheck className="size-4 text-emerald-300" aria-hidden />
          <span>Community rules reminder</span>
          <span className="ml-auto text-xs text-slate-500 group-open:hidden">Show</span>
          <span className="ml-auto hidden text-xs text-slate-500 group-open:inline">Hide</span>
        </summary>
        <div className="mt-3">
          <AmRuleList />
        </div>
      </details>
    );
  }
  return (
    <section className="glass rounded-2xl p-4" aria-labelledby="am-rules-title">
      <h2 id="am-rules-title" className="mb-3 flex items-center gap-2 font-semibold text-white">
        <ShieldCheck className="size-5 text-emerald-300" aria-hidden /> Community rules
      </h2>
      <AmRuleList />
      <label className="mt-4 flex cursor-pointer items-center gap-3 rounded-xl bg-white/[0.04] p-3 ring-1 ring-white/10 has-[:checked]:ring-emerald-400/60">
        <input
          type="checkbox"
          checked={agreed}
          onChange={(e) => onAgreeChange(e.target.checked)}
          className="size-5 shrink-0 cursor-pointer accent-emerald-400"
        />
        <span className="text-sm font-medium text-white">I agree to follow the community rules</span>
      </label>
    </section>
  );
}
