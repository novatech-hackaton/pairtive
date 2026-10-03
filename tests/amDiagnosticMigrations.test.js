// @vitest-environment node
// Runs every Supabase migration (including the diagnostic schema + seed) against an
// in-process Postgres (PGlite) and checks the diagnostic tables: grants, RLS, constraints,
// seed idempotence, retake history, branching profile constraints and the Mastery_Bridge RPC.
// Keep `db`, the role helpers and `topics` at top level so later property tests can reuse them.
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { PGlite } from '@electric-sql/pglite';
import { beforeAll, describe, expect, it } from 'vitest';

const root = join(import.meta.dirname, '..');
const migrationsDir = join(root, 'supabase', 'migrations');
const SEED_FILE = '20261003000008_am_diagnostic_seed.sql';

const REFERENCE_TABLES = ['programs', 'subjects', 'topics', 'diagnostic_questions'];
const STUDENT_TABLES = ['diagnostic_attempts', 'diagnostic_answers', 'student_topic_mastery'];
const ALL_PRIVILEGES = ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER'];

let db;
const ids = {};
/** Seeded topics, sorted by topic_name (collate "C"): [{ id, subject_id, topic_name }]. */
let topics = [];

async function asUser(uid, sql, params = []) {
  await db.exec(`set role authenticated; select set_config('request.jwt.claim.sub', '${uid}', false);`);
  try {
    return await db.query(sql, params);
  } finally {
    await db.exec(`reset role; select set_config('request.jwt.claim.sub', '', false);`);
  }
}
async function asService(sql, params = []) {
  await db.exec('set role service_role;');
  try {
    return await db.query(sql, params);
  } finally {
    await db.exec('reset role;');
  }
}
const scalar = (res) => Object.values(res.rows[0] ?? {})[0];
const count = async (sql, params = []) => Number(scalar(await db.query(sql, params)));

async function createUser(key, { weak = ['Math'], strong = ['English'] } = {}) {
  const res = await db.query(
    `insert into auth.users (email, raw_user_meta_data) values ($1, $2) returning id`,
    [`${key}@example.com`, JSON.stringify({ full_name: key })],
  );
  const id = res.rows[0].id;
  ids[key] = id;
  await asUser(
    id,
    `update public.profiles set name = $1, school = 'UP Diliman', languages = $2, weak_subjects = $3, strong_subjects = $4,
       onboarded = true, rules_accepted_at = now() where id = auth.uid()`,
    [key, ['English'], weak, strong],
  );
  return id;
}

/** Inserts a started attempt for `uid` on `topic` (as that user) and returns its id. */
async function startAttempt(uid, topic) {
  const res = await asUser(
    uid,
    `insert into public.diagnostic_attempts (user_id, subject_id, topic_id) values (auth.uid(), $1, $2) returning id`,
    [topic.subject_id, topic.id],
  );
  return res.rows[0].id;
}

/** Upserts the caller's Mastery_Record through the UNIQUE(user_id, topic_id) constraint. */
async function upsertMastery(uid, topicId, p, level) {
  return asUser(
    uid,
    `insert into public.student_topic_mastery (user_id, topic_id, mastery_probability, mastery_level)
       values (auth.uid(), $1, $2, $3)
     on conflict (user_id, topic_id) do update
       set mastery_probability = excluded.mastery_probability,
           mastery_level = excluded.mastery_level,
           updated_at = now()`,
    [topicId, p, level],
  );
}

beforeAll(async () => {
  db = new PGlite();
  await db.exec(readFileSync(join(root, 'tests', 'amSupabaseStub.sql'), 'utf8'));
  for (const file of readdirSync(migrationsDir).filter((f) => f.endsWith('.sql')).sort()) {
    await db.exec(readFileSync(join(migrationsDir, file), 'utf8'));
  }
  topics = (
    await db.query(`select id, subject_id, topic_name from public.topics order by topic_name collate "C"`)
  ).rows;
  await createUser('ana');
  await createUser('ben');
  await createUser('cy');
  await createUser('dee');
  await createUser('eve');
}, 120_000);

describe('schema', () => {
  it('creates the reference and student tables in public', async () => {
    const res = await db.query(
      `select table_name from information_schema.tables where table_schema = 'public' and table_name = any($1)`,
      [[...REFERENCE_TABLES, ...STUDENT_TABLES]],
    );
    expect(res.rows.map((r) => r.table_name).sort()).toEqual([...REFERENCE_TABLES, ...STUDENT_TABLES].sort());
  });

  it('wires the foreign keys, with user_id referencing auth.users', async () => {
    const res = await db.query(
      `select c.conrelid::regclass::text as tbl, a.attname as col, c.confrelid::regclass::text as ref
         from pg_constraint c
         join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
        where c.contype = 'f' and c.conrelid::regclass::text = any($1)`,
      [[...REFERENCE_TABLES, ...STUDENT_TABLES].map((t) => `${t}`)],
    );
    const fks = res.rows.map((r) => `${r.tbl}.${r.col}->${r.ref}`).sort();
    expect(fks).toEqual(
      [
        'subjects.program_id->programs',
        'topics.subject_id->subjects',
        'diagnostic_questions.topic_id->topics',
        'diagnostic_attempts.user_id->auth.users',
        'diagnostic_attempts.subject_id->subjects',
        'diagnostic_attempts.topic_id->topics',
        'diagnostic_answers.attempt_id->diagnostic_attempts',
        'diagnostic_answers.user_id->auth.users',
        'diagnostic_answers.question_id->diagnostic_questions',
        'diagnostic_answers.topic_id->topics',
        'student_topic_mastery.user_id->auth.users',
        'student_topic_mastery.topic_id->topics',
      ].sort(),
    );
  });

  it('enables RLS on every diagnostic table', async () => {
    const res = await db.query(
      `select relname, relrowsecurity from pg_class where relnamespace = 'public'::regnamespace and relname = any($1)`,
      [[...REFERENCE_TABLES, ...STUDENT_TABLES]],
    );
    expect(res.rows).toHaveLength(7);
    expect(res.rows.every((r) => r.relrowsecurity)).toBe(true);
  });
});

describe('grants', () => {
  const privileges = async (role, table) => {
    const res = await db.query(
      `select p as priv, has_table_privilege($1, $2, p) as ok from unnest($3::text[]) p`,
      [role, `public.${table}`, ALL_PRIVILEGES],
    );
    return res.rows.filter((r) => r.ok).map((r) => r.priv);
  };

  it('gives anon nothing', async () => {
    for (const t of [...REFERENCE_TABLES, ...STUDENT_TABLES]) expect(await privileges('anon', t)).toEqual([]);
  });

  it('gives authenticated S/I/U on student tables and S on reference tables', async () => {
    for (const t of STUDENT_TABLES) expect(await privileges('authenticated', t)).toEqual(['SELECT', 'INSERT', 'UPDATE']);
    for (const t of REFERENCE_TABLES) expect(await privileges('authenticated', t)).toEqual(['SELECT']);
  });

  it('gives service_role every privilege', async () => {
    for (const t of [...REFERENCE_TABLES, ...STUDENT_TABLES]) expect(await privileges('service_role', t)).toEqual(ALL_PRIVILEGES);
  });

  it('lets authenticated call the bridge but not anon', async () => {
    const res = await db.query(
      `select has_function_privilege('anon', 'public.am_apply_mastery_bridge()', 'execute') as anon,
              has_function_privilege('authenticated', 'public.am_apply_mastery_bridge()', 'execute') as auth,
              has_function_privilege('service_role', 'public.am_apply_mastery_bridge()', 'execute') as svc`,
    );
    expect(res.rows[0]).toEqual({ anon: false, auth: true, svc: true });
  });
});

describe('RLS policies', () => {
  beforeAll(async () => {
    ids.anaAttempt = await startAttempt(ids.ana, topics[0]);
    await upsertMastery(ids.ana, topics[0].id, 0.5, 'Developing');
  });

  it('no policy targets anon (or public) on any table', async () => {
    expect(await count(`select count(*) from pg_policies where 'anon' = any(roles)`)).toBe(0);
    expect(
      await count(`select count(*) from pg_policies where tablename = any($1) and roles <> array['authenticated']::name[]`, [
        [...REFERENCE_TABLES, ...STUDENT_TABLES],
      ]),
    ).toBe(0);
  });

  it('cross-user reads return zero rows', async () => {
    for (const t of STUDENT_TABLES) {
      expect((await asUser(ids.ben, `select * from public.${t} where user_id = $1`, [ids.ana])).rows).toHaveLength(0);
    }
    expect((await asUser(ids.ana, `select id from public.diagnostic_attempts`)).rows).toHaveLength(1);
  });

  it('rejects inserts with another user_id', async () => {
    await expect(
      asUser(ids.ben, `insert into public.diagnostic_attempts (user_id, subject_id, topic_id) values ($1, $2, $3)`, [
        ids.ana,
        topics[0].subject_id,
        topics[0].id,
      ]),
    ).rejects.toThrow(/row-level security/);
    await expect(
      asUser(
        ids.ben,
        `insert into public.student_topic_mastery (user_id, topic_id, mastery_probability, mastery_level) values ($1, $2, 0.9, 'Proficient')`,
        [ids.ana, topics[1].id],
      ),
    ).rejects.toThrow(/row-level security/);
  });

  it("rejects answers attached to someone else's attempt", async () => {
    const q = (await db.query(`select id, correct_answer from public.diagnostic_questions where topic_id = $1 limit 1`, [topics[0].id])).rows[0];
    await expect(
      asUser(
        ids.ben,
        `insert into public.diagnostic_answers (attempt_id, user_id, question_id, topic_id, selected_answer, correct_answer, is_correct, response_time)
           values ($1, auth.uid(), $2, $3, 'A', $4, false, 3)`,
        [ids.anaAttempt, q.id, topics[0].id, q.correct_answer],
      ),
    ).rejects.toThrow(/row-level security/);
  });

  it("cannot update another user's rows or hand own rows to someone else", async () => {
    const res = await asUser(ids.ben, `update public.student_topic_mastery set mastery_probability = 1 where user_id = $1 returning id`, [ids.ana]);
    expect(res.rows).toHaveLength(0);
    const after = await db.query(`select mastery_probability::float as p from public.student_topic_mastery where user_id = $1`, [ids.ana]);
    expect(after.rows[0].p).toBe(0.5);
    await expect(
      asUser(ids.ana, `update public.diagnostic_attempts set user_id = $1 where id = $2`, [ids.ben, ids.anaAttempt]),
    ).rejects.toThrow(/row-level security/);
  });

  it("service_role sees every user's rows", async () => {
    const res = await asService(`select distinct user_id from public.diagnostic_attempts`);
    expect(res.rows.map((r) => r.user_id)).toContain(ids.ana);
  });

  it('student rows cannot be deleted by authenticated users', async () => {
    await expect(asUser(ids.ana, `delete from public.diagnostic_attempts where id = $1`, [ids.anaAttempt])).rejects.toThrow(/permission/);
  });

  it('reference tables are readable but read-only for authenticated', async () => {
    expect((await asUser(ids.ana, `select id from public.topics`)).rows).toHaveLength(49);
    await expect(asUser(ids.ana, `insert into public.programs (program_name, program_code) values ('X', 'X')`)).rejects.toThrow(/permission/);
    await expect(asUser(ids.ana, `update public.topics set description = 'x'`)).rejects.toThrow(/permission/);
    await expect(asUser(ids.ana, `delete from public.diagnostic_questions`)).rejects.toThrow(/permission/);
  });

  it('anon cannot read anything', async () => {
    await db.exec('set role anon;');
    try {
      await expect(db.query(`select id from public.topics`)).rejects.toThrow(/permission/);
      await expect(db.query(`select id from public.student_topic_mastery`)).rejects.toThrow(/permission/);
    } finally {
      await db.exec('reset role;');
    }
  });
});

describe('constraints', () => {
  it('constrains mastery_probability to [0, 1]', async () => {
    for (const p of [-0.01, 1.01]) {
      await expect(upsertMastery(ids.cy, topics[0].id, p, 'Weak')).rejects.toThrow(/student_topic_mastery_mastery_probability_check/);
    }
    for (const p of [0, 1]) await upsertMastery(ids.cy, topics[0].id, p, 'Weak');
  });

  it('constrains mastery_level to Weak / Developing / Proficient', async () => {
    await expect(upsertMastery(ids.cy, topics[0].id, 0.5, 'Expert')).rejects.toThrow(/student_topic_mastery_mastery_level_check/);
    const attempt = await startAttempt(ids.cy, topics[0]);
    await expect(
      asUser(ids.cy, `update public.diagnostic_attempts set mastery_level = 'weak' where id = $1`, [attempt]),
    ).rejects.toThrow(/diagnostic_attempts_mastery_level_check/);
    await expect(
      asUser(ids.cy, `update public.diagnostic_attempts set accuracy = 1.5 where id = $1`, [attempt]),
    ).rejects.toThrow(/diagnostic_attempts_accuracy_check/);
  });

  it('enforces UNIQUE(user_id, topic_id) on student_topic_mastery', async () => {
    await expect(
      asUser(
        ids.cy,
        `insert into public.student_topic_mastery (user_id, topic_id, mastery_probability, mastery_level) values (auth.uid(), $1, 0.2, 'Weak')`,
        [topics[0].id],
      ),
    ).rejects.toThrow(/student_topic_mastery_user_topic_unique/);
  });

  it('enforces a globally unique topic_name', async () => {
    const other = topics.find((t) => t.subject_id !== topics[0].subject_id);
    await expect(
      db.query(`insert into public.topics (subject_id, topic_name) values ($1, $2)`, [other.subject_id, topics[0].topic_name]),
    ).rejects.toThrow(/am_topics_topic_name_unique/);
    expect(await count(`select count(*) from (select topic_name from public.topics group by 1 having count(*) > 1) d`)).toBe(0);
  });
});

describe('seed', () => {
  const counts = async () => ({
    programs: await count(`select count(*) from public.programs`),
    subjects: await count(`select count(*) from public.subjects`),
    topics: await count(`select count(*) from public.topics`),
    questions: await count(`select count(*) from public.diagnostic_questions`),
  });

  it('is idempotent: running it again still gives 1 / 7 / 49 / 980', async () => {
    const expected = { programs: 1, subjects: 7, topics: 49, questions: 980 };
    expect(await counts()).toEqual(expected);
    await db.exec(readFileSync(join(migrationsDir, SEED_FILE), 'utf8'));
    expect(await counts()).toEqual(expected);
    expect(await count(`select count(*) from public.topics where id = any($1)`, [topics.map((t) => t.id)])).toBe(49);
  }, 120_000);
});

describe('retake', () => {
  it('keeps both attempts and their answers, and updates the single mastery row', async () => {
    const topic = topics[5];
    const questions = (
      await db.query(`select id, correct_answer from public.diagnostic_questions where topic_id = $1 order by id limit 3`, [topic.id])
    ).rows;
    const take = async (p, level) => {
      const attempt = await startAttempt(ids.ben, topic);
      for (const q of questions) {
        await asUser(
          ids.ben,
          `insert into public.diagnostic_answers (attempt_id, user_id, question_id, topic_id, selected_answer, correct_answer, is_correct, response_time)
             values ($1, auth.uid(), $2, $3, $4, $4, true, 2.5)`,
          [attempt, q.id, topic.id, q.correct_answer],
        );
      }
      await asUser(
        ids.ben,
        `update public.diagnostic_attempts set completed_at = now(), total_questions = 3, correct_answers = 3, accuracy = 1,
           mastery_probability = $2, mastery_level = $3 where id = $1`,
        [attempt, p, level],
      );
      await upsertMastery(ids.ben, topic.id, p, level);
      return attempt;
    };

    const first = await take(0.3, 'Weak');
    const second = await take(0.85, 'Proficient');
    expect(first).not.toBe(second);

    const attempts = await asUser(ids.ben, `select id from public.diagnostic_attempts where topic_id = $1`, [topic.id]);
    expect(attempts.rows.map((r) => r.id).sort()).toEqual([first, second].sort());
    const answers = await asUser(ids.ben, `select count(*)::int as n from public.diagnostic_answers where topic_id = $1`, [topic.id]);
    expect(answers.rows[0].n).toBe(6);
    const mastery = await asUser(
      ids.ben,
      `select mastery_probability::float as p, mastery_level from public.student_topic_mastery where topic_id = $1`,
      [topic.id],
    );
    expect(mastery.rows).toEqual([{ p: 0.85, mastery_level: 'Proficient' }]);
  });
});

describe('profiles subject constraints', () => {
  it('clients cannot write subjects_source', async () => {
    await expect(
      asUser(ids.eve, `update public.profiles set subjects_source = 'diagnostic' where id = auth.uid()`),
    ).rejects.toThrow(/permission/);
    expect(scalar(await db.query(`select subjects_source from public.profiles where id = $1`, [ids.eve]))).toBe('onboarding');
  });

  it('accepts a diagnostic profile with 10 topic names (and an empty weak list)', async () => {
    const names = topics.slice(0, 10).map((t) => t.topic_name);
    await db.query(
      `update public.profiles set subjects_source = 'diagnostic', strong_subjects = $2, weak_subjects = '{}' where id = $1`,
      [ids.dee, names],
    );
    const p = await db.query(`select strong_subjects, weak_subjects, onboarded from public.profiles where id = $1`, [ids.dee]);
    expect(p.rows[0]).toEqual({ strong_subjects: names, weak_subjects: [], onboarded: true });
  });

  it('still requires disjoint lists for diagnostic profiles', async () => {
    const name = topics[0].topic_name;
    await expect(
      db.query(`update public.profiles set weak_subjects = $2 where id = $1`, [ids.dee, [name]]),
    ).rejects.toThrow(/am_profiles_subjects_check/);
  });

  it("rejects an onboarding profile with 'Loops' or 4 subjects", async () => {
    await expect(
      asUser(ids.eve, `update public.profiles set weak_subjects = array['Loops'] where id = auth.uid()`),
    ).rejects.toThrow(/am_profiles_subjects_check/);
    await expect(
      asUser(
        ids.eve,
        `update public.profiles set strong_subjects = array['English','Science','Filipino','History'] where id = auth.uid()`,
      ),
    ).rejects.toThrow(/am_profiles_subjects_check/);
    await expect(
      asUser(ids.eve, `update public.profiles set weak_subjects = '{}' where id = auth.uid()`),
    ).rejects.toThrow(/am_profiles_onboarded_check/);
  });
});

describe('Mastery_Bridge', () => {
  it('raises diagnostic-required with zero Mastery_Records and leaves the profile alone', async () => {
    await expect(asUser(ids.eve, `select * from public.am_apply_mastery_bridge()`)).rejects.toThrow(/diagnostic-required/);
    const p = await db.query(`select weak_subjects, strong_subjects, subjects_source from public.profiles where id = $1`, [ids.eve]);
    expect(p.rows[0]).toEqual({ weak_subjects: ['Math'], strong_subjects: ['English'], subjects_source: 'onboarding' });
  });

  it('overwrites onboarding arrays with Proficient / Weak topic names, ignoring Developing', async () => {
    const [a, b, c, d] = [topics[10], topics[20], topics[30], topics[40]];
    // cy already has a Weak record on topics[0] from the constraint tests.
    await upsertMastery(ids.cy, a.id, 0.9, 'Proficient');
    await upsertMastery(ids.cy, b.id, 0.75, 'Proficient');
    await upsertMastery(ids.cy, c.id, 0.55, 'Developing');
    await upsertMastery(ids.cy, d.id, 0.1, 'Weak');

    const sortC = (arr) => [...arr].sort((x, y) => (x < y ? -1 : x > y ? 1 : 0));
    const expected = {
      out_strong: sortC([a.topic_name, b.topic_name]),
      out_weak: sortC([topics[0].topic_name, d.topic_name]),
    };
    const res = await asUser(ids.cy, `select * from public.am_apply_mastery_bridge()`);
    expect(res.rows[0]).toEqual(expected);

    const p = await db.query(`select strong_subjects, weak_subjects, subjects_source from public.profiles where id = $1`, [ids.cy]);
    expect(p.rows[0]).toEqual({ strong_subjects: expected.out_strong, weak_subjects: expected.out_weak, subjects_source: 'diagnostic' });
    expect(p.rows[0].strong_subjects).not.toContain('English');
    expect(p.rows[0].weak_subjects).not.toContain('Math');

    // Re-running is a no-op (idempotent).
    expect((await asUser(ids.cy, `select * from public.am_apply_mastery_bridge()`)).rows[0]).toEqual(expected);
  });

  it('only touches the caller, and refuses anonymous callers', async () => {
    const before = await db.query(`select strong_subjects, weak_subjects from public.profiles where id = $1`, [ids.ana]);
    await asUser(ids.cy, `select * from public.am_apply_mastery_bridge()`);
    const after = await db.query(`select strong_subjects, weak_subjects from public.profiles where id = $1`, [ids.ana]);
    expect(after.rows).toEqual(before.rows);
    await db.exec('set role anon;');
    try {
      await expect(db.query(`select * from public.am_apply_mastery_bridge()`)).rejects.toThrow(/permission/);
    } finally {
      await db.exec('reset role;');
    }
  });
});
