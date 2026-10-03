// One-off migration runner. Usage: AM_DB_URL=... node scripts/amMigrate.mjs
// Runs each supabase/migrations/*.sql in order, each in its own transaction.
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import pg from 'pg';

const url = process.env.AM_DB_URL;
if (!url) {
  console.error('Set AM_DB_URL');
  process.exit(1);
}
const dir = join(process.cwd(), 'supabase', 'migrations');
const files = readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();

const client = new pg.Client({ connectionString: url, ssl: { rejectUnauthorized: false }, statement_timeout: 120000 });

async function main() {
  await client.connect();
  await client.query('create table if not exists public._am_migrations (name text primary key, run_at timestamptz default now())');
  const done = new Set((await client.query('select name from public._am_migrations')).rows.map((r) => r.name));
  for (const file of files) {
    if (done.has(file)) {
      console.log('skip (already applied):', file);
      continue;
    }
    const sql = readFileSync(join(dir, file), 'utf8');
    process.stdout.write('applying ' + file + ' ... ');
    try {
      await client.query('begin');
      await client.query(sql);
      await client.query('insert into public._am_migrations(name) values ($1)', [file]);
      await client.query('commit');
      console.log('OK');
    } catch (e) {
      await client.query('rollback');
      console.error('FAILED\n', e.message);
      throw e;
    }
  }
  console.log('\nAll migrations applied.');
}

main()
  .then(() => client.end())
  .catch(async () => {
    await client.end();
    process.exit(1);
  });
