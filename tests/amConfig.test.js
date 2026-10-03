// @vitest-environment node
// Config smoke test for the SkillGPS integration (Req 7.1, 8.1, 8.3, 9.1, 9.3, 10.1).
// Reads files from disk only; no network.
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const SKIP_DIRS = new Set(['node_modules', 'dist', '.ds-branch', '.git']);
const APP_DIRS = ['src', 'shared', 'api', 'server'];
const APP_FILES = ['.env.example', 'vercel.json'];
const TEST_FILE = /\.test\.[cm]?[jt]sx?$/;

/** Every file under `dir` (relative to repo root, forward slashes), skipping build/vendor dirs. */
function amWalk(dir) {
  const abs = join(ROOT, dir);
  if (!existsSync(abs)) return [];
  const out = [];
  for (const name of readdirSync(abs)) {
    if (SKIP_DIRS.has(name)) continue;
    const child = join(abs, name);
    const rel = relative(ROOT, child).split(sep).join('/');
    if (statSync(child).isDirectory()) out.push(...amWalk(rel));
    else out.push(rel);
  }
  return out;
}

const read = (rel) => readFileSync(join(ROOT, rel), 'utf8');
const basename = (rel) => rel.split('/').pop();

const appFiles = [...APP_DIRS.flatMap(amWalk), ...APP_FILES.filter((f) => existsSync(join(ROOT, f)))];

describe('amConfig smoke test', () => {
  it('reads the expected config files', () => {
    expect(existsSync(join(ROOT, '.env.example'))).toBe(true);
    expect(existsSync(join(ROOT, 'vercel.json'))).toBe(true);
  });

  it.each(['VITE_PREDICTION_API_URL', 'VITE_RECOMMENDATION_SERVICE_URL', '__DS_USER_ID__'])(
    'has no %s in the app or its config',
    (token) => {
      const hits = appFiles.filter((f) => read(f).includes(token));
      expect(hits).toEqual([]);
    },
  );

  it('keeps SUPABASE_SERVICE_ROLE_KEY and createClient out of src/ (except amSupabase.js)', () => {
    const hits = amWalk('src')
      .filter((f) => f !== 'src/lib/amSupabase.js' && !TEST_FILE.test(f))
      .filter((f) => /SUPABASE_SERVICE_ROLE_KEY|createClient/.test(read(f)));
    expect(hits).toEqual([]);
  });

  it('documents the service role key as server-only in .env.example', () => {
    const env = read('.env.example');
    expect(env).toMatch(/^SUPABASE_SERVICE_ROLE_KEY=/m);
    expect(env).not.toMatch(/VITE_SUPABASE_SERVICE_ROLE_KEY/);
  });

  it('has no Python under api/', () => {
    expect(amWalk('api').filter((f) => f.endsWith('.py'))).toEqual([]);
  });

  it('has every ported file, am-prefixed', () => {
    const ported = [
      'shared/amMasteryThresholds.js',
      'shared/amMasteryClassifier.js',
      'shared/amBkt.js',
      'shared/amBktParams.js',
      'shared/amResponseSequence.js',
      'shared/amScorer.js',
      'shared/amRecommendations.js',
      'shared/amRecommendationContent.js',
      'shared/amMasterySummary.js',
      'shared/amMasteryBridge.js',
      'shared/amIds.js',
      'api/amPredict.js',
      'src/lib/amDiagnostic.js',
      'src/lib/amMastery.jsx',
      'src/pages/amDiagnosticPage.jsx',
      'src/pages/amSkillGpsPage.jsx',
      'src/components/amSkillSummaryCard.jsx',
    ];
    const missing = ported.filter((f) => !existsSync(join(ROOT, f)));
    expect(missing).toEqual([]);
    for (const f of ported) expect(basename(f)).toMatch(/^am/);

    const masteryComponents = amWalk('src/components').filter(
      (f) => /^amMastery.*\.jsx$/.test(basename(f)) && !TEST_FILE.test(f),
    );
    expect(masteryComponents.length).toBeGreaterThan(0);
  });

  it('has no ds-prefixed source files under src/, shared/, api/ or server/', () => {
    const ds = APP_DIRS.flatMap(amWalk).filter((f) => /^ds/i.test(basename(f)));
    expect(ds).toEqual([]);
  });
});
