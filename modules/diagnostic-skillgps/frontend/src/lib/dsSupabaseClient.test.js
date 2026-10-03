import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import fc from 'fast-check';

// Capture the args passed to createClient so we can assert the Anon_Key is used
// and that the client is never created when config is incomplete.
const createClientMock = vi.fn(() => ({ __fakeClient: true }));
vi.mock('@supabase/supabase-js', () => ({
  createClient: (...args) => createClientMock(...args),
}));

const REQUIRED = [
  'VITE_SUPABASE_URL',
  'VITE_SUPABASE_ANON_KEY',
  'VITE_PREDICTION_API_URL',
  'VITE_RECOMMENDATION_SERVICE_URL',
];

const VALID = {
  VITE_SUPABASE_URL: 'https://example.supabase.co',
  VITE_SUPABASE_ANON_KEY: 'anon-key-123',
  VITE_PREDICTION_API_URL: 'http://localhost:8000',
  VITE_RECOMMENDATION_SERVICE_URL: 'http://localhost:8001',
};

function setEnv(values) {
  for (const name of REQUIRED) {
    vi.stubEnv(name, values[name] === undefined ? '' : values[name]);
  }
}

/**
 * The module caches a singleton client, so re-import it fresh per test to
 * observe behavior under different env configurations.
 */
async function loadModule() {
  vi.resetModules();
  return import('./dsSupabaseClient.js');
}

beforeEach(() => {
  createClientMock.mockClear();
});

afterEach(() => {
  vi.unstubAllEnvs();
});

describe('getConfigErrors (Req 7.10)', () => {
  it('returns an empty list when all four variables are present', async () => {
    setEnv(VALID);
    const { getConfigErrors } = await loadModule();
    expect(getConfigErrors()).toEqual([]);
  });

  it('names a single undefined variable', async () => {
    setEnv({ ...VALID, VITE_SUPABASE_URL: undefined });
    const { getConfigErrors } = await loadModule();
    expect(getConfigErrors()).toEqual(['VITE_SUPABASE_URL']);
  });

  it('treats an empty string as missing', async () => {
    setEnv({ ...VALID, VITE_SUPABASE_ANON_KEY: '' });
    const { getConfigErrors } = await loadModule();
    expect(getConfigErrors()).toEqual(['VITE_SUPABASE_ANON_KEY']);
  });

  it('treats a whitespace-only value as missing', async () => {
    setEnv({ ...VALID, VITE_PREDICTION_API_URL: '   ' });
    const { getConfigErrors } = await loadModule();
    expect(getConfigErrors()).toEqual(['VITE_PREDICTION_API_URL']);
  });

  it('names every missing variable when several are absent', async () => {
    setEnv({
      ...VALID,
      VITE_SUPABASE_URL: '',
      VITE_RECOMMENDATION_SERVICE_URL: '  ',
    });
    const { getConfigErrors } = await loadModule();
    expect(getConfigErrors()).toEqual([
      'VITE_SUPABASE_URL',
      'VITE_RECOMMENDATION_SERVICE_URL',
    ]);
  });
});

describe('getSupabase (Req 7.1, 7.4, 7.11, 5.11)', () => {
  it('creates the client from the URL and Anon_Key when config is complete', async () => {
    setEnv(VALID);
    const { getSupabase } = await loadModule();
    const client = getSupabase();
    expect(client).not.toBeNull();
    expect(createClientMock).toHaveBeenCalledTimes(1);
    expect(createClientMock).toHaveBeenCalledWith(
      VALID.VITE_SUPABASE_URL,
      VALID.VITE_SUPABASE_ANON_KEY,
    );
  });

  it('returns the same singleton instance across calls', async () => {
    setEnv(VALID);
    const { getSupabase } = await loadModule();
    expect(getSupabase()).toBe(getSupabase());
    expect(createClientMock).toHaveBeenCalledTimes(1);
  });

  it('does not create the client when any variable is missing', async () => {
    setEnv({ ...VALID, VITE_SUPABASE_ANON_KEY: '' });
    const { getSupabase } = await loadModule();
    expect(getSupabase()).toBeNull();
    expect(createClientMock).not.toHaveBeenCalled();
  });

  it('never uses a Service_Role_Key — only the Anon_Key is passed', async () => {
    setEnv(VALID);
    const { getSupabase } = await loadModule();
    getSupabase();
    const [, keyArg] = createClientMock.mock.calls[0];
    expect(keyArg).toBe(VALID.VITE_SUPABASE_ANON_KEY);
  });
});

describe('config guard property (Req 7.10, 7.11)', () => {
  // Validates: Requirements 7.10, 7.11
  // For any combination of present/missing values across the four variables,
  // getConfigErrors names exactly the missing ones, and whenever any is
  // missing the Supabase client is never created.
  it('names exactly the missing variables and blocks client creation when any is missing', async () => {
    const valueArb = fc.oneof(
      fc.constant(undefined),
      fc.constant(''),
      fc.constant('   '),
      fc.constant('\t\n'),
      fc.string({ minLength: 1 }).map((s) => `x${s}`), // guaranteed non-whitespace
    );

    await fc.assert(
      fc.asyncProperty(
        fc.record({
          VITE_SUPABASE_URL: valueArb,
          VITE_SUPABASE_ANON_KEY: valueArb,
          VITE_PREDICTION_API_URL: valueArb,
          VITE_RECOMMENDATION_SERVICE_URL: valueArb,
        }),
        async (env) => {
          createClientMock.mockClear();
          setEnv(env);
          const { getConfigErrors, getSupabase } = await loadModule();

          const expectedMissing = REQUIRED.filter(
            (name) =>
              typeof env[name] !== 'string' || env[name].trim().length === 0,
          );

          expect(getConfigErrors()).toEqual(expectedMissing);

          const client = getSupabase();
          if (expectedMissing.length > 0) {
            expect(client).toBeNull();
            expect(createClientMock).not.toHaveBeenCalled();
          } else {
            expect(client).not.toBeNull();
          }

          vi.unstubAllEnvs();
        },
      ),
      { numRuns: 100 },
    );
  });
});
