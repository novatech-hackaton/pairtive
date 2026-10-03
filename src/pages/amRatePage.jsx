import { useEffect, useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import confetti from 'canvas-confetti';
import { Flag, SkipForward, Star } from 'lucide-react';
import { useAmAuth } from '../lib/amAuth.jsx';
import { amSupabase } from '../lib/amSupabase.js';
import { amStopLocalStream } from '../lib/amMedia.js';
import { amSubmitReport } from '../lib/amReporting.js';
import { AmButton } from '../components/amButton.jsx';
import { AmCard } from '../components/amCard.jsx';
import { AmAvatar } from '../components/amAvatar.jsx';
import { AmStarInput } from '../components/amStars.jsx';
import { AmReportModal } from '../components/amReportModal.jsx';
import { AmLogo, AmFullScreenLoader } from '../components/amLogo.jsx';
import { amToast } from '../components/amToast.jsx';

const AM_TAGS = ['Helpful', 'Patient', 'Clear', 'Knowledgeable'];

function AmRateCard({ person, value, onChange }) {
  const toggleTag = (t) => onChange({ ...value, tags: value.tags.includes(t) ? value.tags.filter((x) => x !== t) : [...value.tags, t] });
  return (
    <AmCard>
      <div className="flex items-center gap-3">
        <AmAvatar name={person.name} src={person.avatar_url} size="md" ring />
        <div className="flex-1">
          <p className="font-semibold text-white">{person.name}</p>
          <p className="text-xs text-slate-400">How was studying together?</p>
        </div>
      </div>
      <div className="mt-4"><AmStarInput value={value.stars} onChange={(stars) => onChange({ ...value, stars })} label={'Rating for ' + person.name} /></div>
      <div className="mt-4 flex flex-wrap gap-2">
        {AM_TAGS.map((t) => (
          <button key={t} type="button" onClick={() => toggleTag(t)} className={'h-9 rounded-full px-3.5 text-sm font-medium transition ' + (value.tags.includes(t) ? 'bg-brand text-white shadow-glow' : 'bg-white/[0.05] text-slate-300 ring-1 ring-white/10 hover:bg-white/10')}>
            {t}
          </button>
        ))}
      </div>
      <textarea
        value={value.comment}
        onChange={(e) => onChange({ ...value, comment: e.target.value.slice(0, 500) })}
        rows={2}
        placeholder="Leave a note (optional)"
        className="mt-3 w-full rounded-2xl bg-white/[0.04] p-3 text-sm text-white ring-1 ring-white/10 focus:ring-2 focus:ring-brand-violet focus:outline-none"
      />
    </AmCard>
  );
}

export default function AmRatePage() {
  const { sessionId } = useParams();
  const [params] = useSearchParams();
  const goNext = params.get('next') === '1';
  const { user } = useAmAuth();
  const navigate = useNavigate();
  const [peers, setPeers] = useState(null);
  const [ratings, setRatings] = useState({});
  const [busy, setBusy] = useState(false);
  const [reportTarget, setReportTarget] = useState(null);

  useEffect(() => {
    (async () => {
      const { data: m } = await amSupabase.from('session_members').select('user_id').eq('session_id', sessionId).neq('user_id', user.id);
      const ids = (m ?? []).map((x) => x.user_id);
      if (!ids.length) { finish(); return; }
      const { data: profs } = await amSupabase.from('profiles').select('id, name, avatar_url').in('id', ids);
      setPeers(profs ?? []);
      setRatings(Object.fromEntries((profs ?? []).map((p) => [p.id, { stars: 0, tags: [], comment: '' }])));
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sessionId]);

  function finish() {
    amStopLocalStream();
    navigate(goNext ? '/match' : '/home', { replace: true });
  }

  async function submit() {
    setBusy(true);
    try {
      const rows = Object.entries(ratings)
        .filter(([, r]) => r.stars > 0)
        .map(([ratee_id, r]) => ({ session_id: sessionId, rater_id: user.id, ratee_id, stars: r.stars, tags: r.tags, comment: r.comment.trim() || null }));
      if (rows.length) {
        const { error } = await amSupabase.from('ratings').insert(rows);
        if (error) throw error;
        if (rows.some((r) => r.stars >= 4)) confetti({ particleCount: 90, spread: 70, origin: { y: 0.7 }, colors: ['#6366f1', '#8b5cf6', '#22d3ee'] });
        amToast.success('Thanks for the feedback!');
      }
      setTimeout(finish, rows.some((r) => r.stars >= 4) ? 700 : 0);
    } catch (e) {
      amToast.error(e.message);
      setBusy(false);
    }
  }

  if (!peers) return <AmFullScreenLoader label="Wrapping up…" />;

  return (
    <div className="mx-auto max-w-lg px-4 py-8">
      <AmLogo className="mb-6" />
      <h1 className="text-2xl font-bold text-white">Rate your {peers.length > 1 ? 'study peers' : 'study buddy'}</h1>
      <p className="mt-1 text-slate-400">Honest ratings help us make better matches. You can skip.</p>
      <div className="mt-6 space-y-4">
        {peers.map((p) => (
          <div key={p.id}>
            <AmRateCard person={p} value={ratings[p.id]} onChange={(v) => setRatings((r) => ({ ...r, [p.id]: v }))} />
            <button type="button" onClick={() => setReportTarget(p)} className="mt-1.5 ml-1 inline-flex items-center gap-1 text-xs text-slate-500 hover:text-rose-300">
              <Flag className="size-3.5" aria-hidden /> Report {p.name}
            </button>
          </div>
        ))}
      </div>
      <div className="mt-6 flex items-center justify-between gap-3">
        <AmButton variant="ghost" onClick={finish}>Skip</AmButton>
        <AmButton size="lg" icon={goNext ? SkipForward : Star} loading={busy} onClick={submit}>
          {goNext ? 'Submit & find next' : 'Submit'}
        </AmButton>
      </div>
      <AmReportModal
        open={!!reportTarget}
        onClose={() => setReportTarget(null)}
        reportedName={reportTarget?.name}
        onSubmit={async ({ reason, note }) => {
          try {
            await amSubmitReport({ reportedId: reportTarget.id, reason, note, sessionId });
            amToast.success('Report sent.');
            setReportTarget(null);
          } catch (e) { amToast.error(e.message); }
        }}
      />
    </div>
  );
}
