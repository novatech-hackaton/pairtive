import { useState } from 'react';
import { LogOut, Save, Star, Target, Video } from 'lucide-react';
import { amValidateBasics, amValidateSubjects } from '../../shared/amSubjects.js';
import { useAmAuth } from '../lib/amAuth.jsx';
import { amSupabase, amFriendlyError } from '../lib/amSupabase.js';
import { AmButton } from '../components/amButton.jsx';
import { AmCard, AmCardTitle } from '../components/amCard.jsx';
import { AmRatingBadge } from '../components/amStars.jsx';
import { amToast } from '../components/amToast.jsx';
import { AmAvatarPicker, AmBasicsFields, AmSubjectsFields, amUploadAvatar } from '../components/amProfileFields.jsx';

export default function AmProfilePage() {
  const { profile, user, refreshProfile, signOut } = useAmAuth();
  const [basics, setBasics] = useState({ name: profile.name, school: profile.school, languages: profile.languages });
  const [subjects, setSubjects] = useState({ weak: profile.weak_subjects, strong: profile.strong_subjects });
  const [avatarFile, setAvatarFile] = useState(null);
  const [errors, setErrors] = useState({});
  const [busy, setBusy] = useState(false);

  async function save() {
    const e = amValidateBasics(basics);
    const s = amValidateSubjects(subjects.weak, subjects.strong);
    if (s) e.subjects = s;
    setErrors(e);
    if (Object.keys(e).length) {
      amToast.error('Please fix the highlighted fields.');
      return;
    }
    setBusy(true);
    try {
      let avatar_url = profile.avatar_url;
      if (avatarFile) avatar_url = await amUploadAvatar(user.id, avatarFile);
      const { error } = await amSupabase
        .from('profiles')
        .update({
          name: basics.name.trim(),
          school: basics.school.trim(),
          languages: basics.languages,
          weak_subjects: subjects.weak,
          strong_subjects: subjects.strong,
          avatar_url,
        })
        .eq('id', user.id);
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
          <AmSubjectsFields weak={subjects.weak} strong={subjects.strong} onChange={setSubjects} error={errors.subjects} />
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
