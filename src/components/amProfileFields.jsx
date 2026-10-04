import { useEffect, useMemo, useRef } from 'react';
import { Camera, GraduationCap, UserRound } from 'lucide-react';
import { AM_LANGUAGES } from '../../shared/amSubjects.js';
import { amSupabase } from '../lib/amSupabase.js';
import { AmAvatar } from './amAvatar.jsx';
import { AmField, AmPillGroup } from './amField.jsx';
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
