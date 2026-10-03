// Subject catalog + profile validation. Shared by client, API and tests.

export const AM_SUBJECTS = ['Math', 'English', 'Science', 'Filipino', 'History', 'Programming'];

export const AM_SUBJECT_META = {
  Math: { icon: 'Sigma', color: '#818cf8', soft: 'rgba(129,140,248,0.16)' },
  English: { icon: 'BookOpen', color: '#f472b6', soft: 'rgba(244,114,182,0.16)' },
  Science: { icon: 'FlaskConical', color: '#34d399', soft: 'rgba(52,211,153,0.16)' },
  Filipino: { icon: 'Languages', color: '#fbbf24', soft: 'rgba(251,191,36,0.16)' },
  History: { icon: 'Landmark', color: '#fb923c', soft: 'rgba(251,146,60,0.16)' },
  Programming: { icon: 'Code2', color: '#22d3ee', soft: 'rgba(34,211,238,0.16)' },
};

export const AM_LANGUAGES = [
  'English',
  'Filipino',
  'Cebuano',
  'Ilocano',
  'Hiligaynon',
  'Spanish',
  'Mandarin',
  'Japanese',
  'Korean',
  'Arabic',
  'Hindi',
  'Indonesian',
  'Vietnamese',
  'French',
  'German',
];

export const AM_MIN_PICKS = 1;
export const AM_MAX_PICKS = 3;

/** Returns an error message or null. */
export function amValidateSubjects(weak = [], strong = []) {
  const allowed = new Set(AM_SUBJECTS);
  if (!Array.isArray(weak) || !Array.isArray(strong)) return 'Pick your subjects.';
  if ([...weak, ...strong].some((s) => !allowed.has(s))) return 'Unknown subject selected.';
  if (new Set(weak).size !== weak.length || new Set(strong).size !== strong.length) return 'Each subject can only be picked once.';
  if (weak.length < AM_MIN_PICKS) return 'Pick at least 1 subject you want help with.';
  if (strong.length < AM_MIN_PICKS) return 'Pick at least 1 subject you can help with.';
  if (weak.length > AM_MAX_PICKS || strong.length > AM_MAX_PICKS) return `Pick up to ${AM_MAX_PICKS} subjects in each list.`;
  if (weak.some((s) => strong.includes(s))) return "A subject can't be in both lists.";
  return null;
}

/** Toggle a subject in one list while keeping the other list consistent. */
export function amToggleSubject(list, other, subject) {
  if (list.includes(subject)) return { list: list.filter((s) => s !== subject), other };
  if (list.length >= AM_MAX_PICKS) return { list, other, error: `You can pick up to ${AM_MAX_PICKS}.` };
  return { list: [...list, subject], other: other.filter((s) => s !== subject) };
}

/** Step 1 of onboarding: name, languages, school. Returns { field: message } (empty = valid). */
export function amValidateBasics({ name = '', languages = [], school = '' } = {}) {
  const errors = {};
  const trimmed = name.trim();
  if (trimmed.length < 2) errors.name = 'Enter your name (at least 2 characters).';
  else if (trimmed.length > 60) errors.name = 'Name must be 60 characters or fewer.';
  if (!Array.isArray(languages) || languages.length === 0) errors.languages = 'Pick at least one language.';
  else if (languages.length > 5) errors.languages = 'Pick up to 5 languages.';
  const sch = school.trim();
  if (sch.length < 2) errors.school = 'Enter your school or organization.';
  else if (sch.length > 120) errors.school = 'School must be 120 characters or fewer.';
  return errors;
}

export function amIsProfileComplete(profile) {
  if (!profile || !profile.onboarded) return false;
  const basics = amValidateBasics({
    name: profile.name ?? '',
    languages: profile.languages ?? [],
    school: profile.school ?? '',
  });
  return Object.keys(basics).length === 0 && amValidateSubjects(profile.weak_subjects, profile.strong_subjects) === null;
}

/** Normalize a school name for "same school only" comparisons. */
export function amSchoolKey(school = '') {
  return school
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}
