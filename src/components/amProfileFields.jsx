import { useEffect, useMemo, useRef, useState } from 'react';
import { Camera, GraduationCap, Handshake, Lightbulb, UserRound } from 'lucide-react';
import { AM_LANGUAGES, AM_MAX_PICKS, AM_SUBJECTS, amToggleSubject } from '../../shared/amSubjects.js';
import { amSupabase } from '../lib/amSupabase.js';
import { AmAvatar } from './amAvatar.jsx';
import { AmField, AmPillGroup } from './amField.jsx';
import { AmSubjectToggle } from './amSubjectChip.jsx';
import { amToast } from './amToast.jsx';

const AM_AVATAR_TYPES = ['image/png', 'image/jpeg', 'image/webp', 'image/gif'];

/** Upload an avatar into avatars/<uid>/ and return its public URL. */
export async function amUploadAvatar(userId, file) {
  if (!AM_AVATAR_TYPES.includes(file.type)) throw new Error('Use a PNG, JPG, WEBP or GIF image.');
  if (file.size > 2 * 1024 * 1024) throw new Error('Avatar must be 2 MB or smaller.');
  const ext = file.type.split('/')[1].replace('jpeg', 'jpg');
  const path = `${userId}/avatar-${Date.now()}.${ext}`;
  const { error } = await amSupabase.storage.from('avatars').upload(path, file, { upsert: true, contentType: file.type });
  if (error) throw new Error(error.message);
  return amSupabase.storage.from('avatars').getPublicUrl(path).data.publicUrl;
}

export function AmAvatarPicker({ name, src, file, onFile }) {
  const input = useRef(null);
  const objectUrl = useMemo(() => (file ? URL.createObjectURL(file) : null), [file]);
  useEffect(() => () => objectUrl && URL.revokeObjectURL(objectUrl), [objectUrl]);
  const preview = objectUrl ?? src;
  return (
    <div className="flex items-center gap-4">
      <AmAvatar name={name || 'You'} src={preview} size="lg" ring />
      <div>
        <button
          type="button"
          onClick={() => input.current?.click()}
          className="inline-flex h-10 items-center gap-2 rounded-xl bg-white/[0.06] px-3.5 text-sm font-medium text-white ring-1 ring-white/10 hover:bg-white/10"
        >
          <Camera className="size-4" aria-hidden /> {preview ? 'Change photo' : 'Add a photo'}
        </button>
        <p className="mt-1 text-xs text-slate-500">Optional · PNG/JPG up to 2 MB</p>
        <input
          ref={input}
          type="file"
          accept={AM_AVATAR_TYPES.join(',')}
          className="am-sr-only"
          aria-label="Upload avatar"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (!f) return;
            if (!AM_AVATAR_TYPES.includes(f.type) || f.size > 2 * 1024 * 1024) {
              amToast.error('Use a PNG, JPG, WEBP or GIF up to 2 MB.');
              return;
            }
            onFile(f);
          }}
        />
      </div>
    </div>
  );
}

export function AmBasicsFields({ value, onChange, errors = {} }) {
  const set = (k) => (v) => onChange({ ...value, [k]: v });
  return (
    <div className="space-y-5">
      <AmField label="Your name" icon={UserRound} value={value.name} onChange={(e) => set('name')(e.target.value)} error={errors.name} maxLength={60} autoComplete="name" />
      <AmField
        label="School or organization"
        icon={GraduationCap}
        value={value.school}
        onChange={(e) => set('school')(e.target.value)}
        error={errors.school}
        maxLength={120}
        placeholder="e.g. University of the Philippines Diliman"
        autoComplete="organization"
      />
      <AmPillGroup
        label="Languages you're comfortable studying in"
        options={AM_LANGUAGES}
        value={value.languages}
        onChange={set('languages')}
        max={5}
        error={errors.languages}
        hint="Pick up to 5. We use this to suggest buddies you can easily talk with."
      />
    </div>
  );
}

function AmSubjectColumn({ which, title, subtitle, icon: Icon, list, other, onToggle }) {
  return (
    <section aria-labelledby={`am-${which}-title`}>
      <div className="mb-3 flex items-center gap-2">
        <Icon className="size-5 text-brand-cyan" aria-hidden />
        <h3 id={`am-${which}-title`} className="font-semibold text-white">
          {title}
        </h3>
        <span className="ml-auto text-xs text-slate-400">
          {list.length}/{AM_MAX_PICKS}
        </span>
      </div>
      <p className="mb-3 text-sm text-slate-400">{subtitle}</p>
      <div className="grid gap-2.5">
        {AM_SUBJECTS.map((s) => (
          <AmSubjectToggle
            key={s}
            subject={s}
            selected={list.includes(s)}
            onToggle={() => onToggle(which, s)}
            hint={other.includes(s) ? (which === 'weak' ? 'Currently in "I can help"' : 'Currently in "I want help"') : undefined}
          />
        ))}
      </div>
    </section>
  );
}

export function AmSubjectsFields({ weak, strong, onChange, error }) {
  const [hint, setHint] = useState('');
  const toggle = (which, subject) => {
    const list = which === 'weak' ? weak : strong;
    const other = which === 'weak' ? strong : weak;
    const r = amToggleSubject(list, other, subject);
    setHint(r.error ?? '');
    if (which === 'weak') onChange({ weak: r.list, strong: r.other });
    else onChange({ weak: r.other, strong: r.list });
  };
  return (
    <div>
      <div className="grid gap-6 md:grid-cols-2">
        <AmSubjectColumn which="weak" title="I want help with" subtitle="Subjects you find hard." icon={Lightbulb} list={weak} other={strong} onToggle={toggle} />
        <AmSubjectColumn which="strong" title="I can help with" subtitle="Subjects you're confident in." icon={Handshake} list={strong} other={weak} onToggle={toggle} />
      </div>
      <p className="mt-4 min-h-5 text-sm text-rose-300" role="alert">
        {error || hint}
      </p>
    </div>
  );
}
