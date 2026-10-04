import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Compass, Handshake, Lightbulb, LogOut, RotateCcw, Save, Star, Target, Video } from 'lucide-react';
import { amValidateBasics } from '../../shared/amSubjects.js';
import { useAmAuth } from '../lib/amAuth.jsx';
import { amSupabase, amFriendlyError } from '../lib/amSupabase.js';
import { AmButton } from '../components/amButton.jsx';
import { AmCard, AmCardTitle } from '../components/amCard.jsx';
import { AmRatingBadge } from '../components/amStars.jsx';
import { AmSubjectChip } from '../components/amSubjectChip.jsx';
import { amToast } from '../components/amToast.jsx';
import { AmAvatarPicker, AmBasicsFields, amUploadAvatar } from '../components/amProfileFields.jsx';

/** Read-only list of diagnostic-derived topic names (Req 5.6, 5.8). */
function AmTopicChipList({ id, title, icon: Icon, topics, empty }) {
  return (
    <section aria-labelledby={id}>
      <div className="mb-3 flex items-center gap-2">
        <Icon className="size-5 text-brand-cyan" aria-hidden />
        <h3 id={id} className="font-semibold text-white">
          {title}
        </h3>
        <span className="ml-auto text-xs text-slate-400">{topics.length}</span>
      </div>
      {topics.length ? (
        <ul aria-labelledby={id} className="flex flex-wrap gap-2">
          {topics.map((t) => (
            <li key={t}>
              <AmSubjectChip subject={t} size="sm" />
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-sm text-slate-400">{empty}</p>
      )}
    </section>
  );
}

/** Strong/weak topics are read-only for everyone; only the diagnostic (Mastery_Bridge) changes them. */
function AmSkillTopics({ weak, strong, diagnostic }) {
  return (
    <div>
      <AmCardTitle
        icon={Compass}
        title="Your SkillGPS topics"
        subtitle={diagnostic ? 'Set from your diagnostic results.' : 'Take the diagnostic to set your strong and weak topics.'}
        action={
          <Link to="/diagnostic" className="inline-flex items-center gap-1.5 text-sm text-slate-300 hover:text-white">
            {diagnostic ? <RotateCcw className="size-3.5" aria-hidden /> : <Compass className="size-3.5" aria-hidden />}
            {diagnostic ? 'Retake diagnostic' : 'Take diagnostic'}
          </Link>
        }
      />
      <div className="grid gap-6 md:grid-cols-2">
        <AmTopicChipList id="am-diag-weak-title" title="I want help with" icon={Lightbulb} topics={weak} empty="No weak topics right now." />
        <AmTopicChipList id="am-diag-strong-title" title="I can help with" icon={Handshake} topics={strong} empty="No proficient topics yet." />
      </div>
      {diagnostic && !weak.length && !strong.length ? (
        <p className="mt-4 text-sm text-slate-400">
          All topics are Developing, so matching needs at least one strong or weak topic. Retake to update.
        </p>
      ) : null}
    </div>
  );
}

export default function AmProfilePage() {
  const { profile, user, refreshProfile, signOut } = useAmAuth();
  const diagnostic = profile.subjects_source === 'diagnostic';
  const [basics, setBasics] = useState({ name: profile.name, school: profile.school, languages: profile.languages });
  const [avatarFile, setAvatarFile] = useState(null);
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);

  async function save() {
    const e = amValidateBasics(basics);
    setErrors(e);
    if (Object.keys(e).length) {
      amToast.error('Please fix the highlighted fields.');
      return;
    }
    setBusy(true);
    try {
      let avatar_url = profile.avatar_url;
      if (avatarFile) avatar_url = await amUploadAvatar(user.id, avatarFile);
      // Never send weak/strong_subjects: only the Mastery_Bridge writes them.
      const payload = { name: basics.name.trim(), school: basics.school.trim(), languages: basics.languages, avatar_url };
      const { error } = await amSupabase.from('profiles').update(payload).eq('id', user.id);
      if (error) throw error;
      await refreshProfile();
      setAvatarFile(null);
      amToast.success('Profile saved');
    } catch (err) {
      amToast.error(amFriendlyError(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mx-auto max-w-4xl">
      <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white">Your profile</h1>
          <p className="mt-1 text-slate-400">This is what your matches see before joining.</p>
        </div>
        <div className="flex items-center gap-3 text-sm text-slate-300">
          <AmRatingBadge avg={profile.rating_avg} count={profile.rating_count} />
          <span className="inline-flex items-center gap-1.5">
            <Video className="size-4 text-cyan-300" aria-hidden /> {profile.sessions_count} sessions
          </span>
          {profile.sessions_count ? (
            <span className="inline-flex items-center gap-1.5">
              <Target className="size-4 text-emerald-300" aria-hidden /> {Math.round(profile.success_rate * 100)}% success
            </span>
          ) : null}
        </div>
      </div>

      <div className="space-y-5">
        <AmCard>
          <AmCardTitle icon={Star} title="About you" />
          <div className="space-y-6">
            <AmAvatarPicker name={basics.name} src={profile.avatar_url} file={avatarFile} onFile={setAvatarFile} />
            <AmBasicsFields value={basics} onChange={setBasics} errors={errors} />
          </div>
        </AmCard>
        <AmCard>
          <AmSkillTopics weak={profile.weak_subjects ?? []} strong={profile.strong_subjects ?? []} diagnostic={diagnostic} />
        </AmCard>
        <div className="flex flex-col-reverse gap-3 sm:flex-row sm:justify-between">
          <AmButton variant="ghost" icon={LogOut} onClick={signOut}>
            Sign out
          </AmButton>
          <AmButton size="lg" icon={Save} loading={busy} onClick={save}>
            Save changes
          </AmButton>
        </div>
      </div>
    </div>
  );
}
