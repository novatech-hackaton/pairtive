// npm run demo:match - prints sample matches from a fake queue using the real matcher.
import { amBuildBlockSet, amCreateCooldownIndex, amTeachLearnCopy } from '../shared/amMatchScore.js';
import { amPlanMatches } from '../shared/amGroupBuilder.js';

const now = Date.now();
const u = (id, mode, weak, strong, extra = {}) => ({
  id,
  name: id,
  mode,
  sameSchoolOnly: false,
  joinedAt: now - (extra.waitS ?? 5) * 1000,
  lastSeen: now - 1000,
  status: 'waiting',
  weak,
  strong,
  languages: extra.languages ?? ['English'],
  school: extra.school ?? 'UP Diliman',
  ratingAvg: extra.rating ?? 0,
  ratingCount: extra.ratings ?? 0,
  successCount: 0,
  sessionsCount: 0,
  suspendedUntil: 0,
});

const queue = [
  u('Ana', 'buddy', ['Math'], ['English'], { waitS: 40, languages: ['Filipino', 'English'] }),
  u('Ben', 'buddy', ['English'], ['Math'], { rating: 4.8, ratings: 12 }),
  u('Cara', 'buddy', ['English'], ['Math', 'Science'], { languages: ['Filipino'] }),
  u('Dan', 'buddy', ['History'], ['Programming']),
  u('Eli', 'peers', ['Math'], ['English'], { waitS: 50 }),
  u('Fay', 'peers', ['English'], ['Science']),
  u('Gio', 'peers', ['Science'], ['Math']),
  u('Hana', 'peers', ['Programming'], ['History']),
];

const ctx = { now, blockSet: amBuildBlockSet([]), cooldowns: amCreateCooldownIndex([]) };
const byId = new Map(queue.map((x) => [x.id, x]));

for (const p of amPlanMatches(queue, ctx)) {
  console.log(`\n${p.mode === 'buddy' ? 'Study Buddy' : 'Study Peers'}: ${p.memberIds.join(' + ')}${p.score ? `  (score ${p.score.toFixed(3)})` : ''}`);
  for (const id of p.memberIds) {
    const me = byId.get(id);
    const copy = amTeachLearnCopy(me, p.memberIds.filter((x) => x !== id).map((x) => byId.get(x)));
    console.log(`  ${id}: ${[...copy.teach, ...copy.learn].map((c) => c.text).join(' | ')}`);
  }
}
console.log('\nUnmatched:', queue.filter((q) => !amPlanMatches(queue, ctx).some((p) => p.memberIds.includes(q.id))).map((q) => q.id).join(', ') || 'none');
