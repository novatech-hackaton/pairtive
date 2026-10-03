import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent, within } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import DsDiagnostic from '../src/pages/dsDiagnostic.jsx';
import { getSupabase } from '../src/lib/dsSupabaseClient.js';

// Mock the Supabase client module so no real network request is ever sent.
vi.mock('../src/lib/dsSupabaseClient.js', () => ({
  getSupabase: vi.fn(),
}));

/**
 * Builds a Supabase Test_Double whose chained query builder resolves the
 * reference-table reads the selection UI performs: programs → subjects →
 * topics → diagnostic_questions.
 *
 * @param {object} data
 * @param {Array} data.programs   rows returned for `programs`
 * @param {Array} data.subjects   rows returned for `subjects`
 * @param {Array} data.topics     rows returned for `topics`
 * @param {Array} data.questions  rows returned for `diagnostic_questions`
 */
function makeSupabase({ programs = [], subjects = [], topics = [], questions = [] } = {}) {
  const rowsByTable = {
    programs,
    subjects,
    topics,
    diagnostic_questions: questions,
  };

  function from(table) {
    // Each builder is a thenable that ignores the filter/order chain and
    // resolves to the configured rows for the table.
    const result = { data: rowsByTable[table] ?? [], error: null };
    const builder = {
      select: () => builder,
      eq: () => builder,
      in: () => builder,
      order: () => builder,
      limit: () => builder,
      then: (resolve) => resolve(result),
    };
    return builder;
  }

  return { from: vi.fn(from) };
}

const PROGRAMS = [{ id: 1, program_name: 'BSCS', program_code: 'BSCS' }];
const SUBJECTS = [
  { id: 10, subject_name: 'Introduction to Programming' },
  { id: 20, subject_name: 'Operating Systems' },
];
const TOPICS = [
  { id: 100, topic_name: 'Variables and Data Types', description: 'Storing values.' },
  { id: 101, topic_name: 'Loops', description: 'Repeating work.' },
  { id: 102, topic_name: 'Empty Topic', description: 'No questions yet.' },
];
// 100 and 101 have questions; 102 has none (unavailable).
const QUESTIONS = [
  ...Array.from({ length: 20 }, () => ({ topic_id: 100 })),
  ...Array.from({ length: 20 }, () => ({ topic_id: 101 })),
];

function renderDiagnostic() {
  return render(
    <MemoryRouter initialEntries={['/diagnostic']}>
      <DsDiagnostic />
    </MemoryRouter>,
  );
}

beforeEach(() => {
  vi.clearAllMocks();
});

describe('Diagnostic_Page subject loading (Req 8.1)', () => {
  it('loads and displays one selectable entry per BSCS subject', async () => {
    getSupabase.mockReturnValue(makeSupabase({ programs: PROGRAMS, subjects: SUBJECTS }));
    renderDiagnostic();

    expect(await screen.findByRole('button', { name: 'Introduction to Programming' }))
      .toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Operating Systems' })).toBeInTheDocument();
  });
});

describe('Diagnostic_Page topic display (Req 8.2, 8.5)', () => {
  it('shows the selected subject topics with descriptions and marks zero-question topics unavailable', async () => {
    getSupabase.mockReturnValue(
      makeSupabase({ programs: PROGRAMS, subjects: SUBJECTS, topics: TOPICS, questions: QUESTIONS }),
    );
    renderDiagnostic();

    fireEvent.click(await screen.findByRole('button', { name: 'Introduction to Programming' }));

    expect(await screen.findByText('Variables and Data Types')).toBeInTheDocument();
    expect(screen.getByText('Storing values.')).toBeInTheDocument();
    expect(screen.getByText('Repeating work.')).toBeInTheDocument();

    // The zero-question topic is shown but unavailable / non-selectable.
    const emptyTopic = screen.getByRole('checkbox', { name: /Empty Topic/ });
    expect(emptyTopic).toBeDisabled();
    expect(within(emptyTopic).getByText('Unavailable')).toBeInTheDocument();
  });

  it('clears previously selected topics when a new subject is selected', async () => {
    getSupabase.mockReturnValue(
      makeSupabase({ programs: PROGRAMS, subjects: SUBJECTS, topics: TOPICS, questions: QUESTIONS }),
    );
    renderDiagnostic();

    fireEvent.click(await screen.findByRole('button', { name: 'Introduction to Programming' }));
    const loops = await screen.findByRole('checkbox', { name: /Loops/ });
    fireEvent.click(loops);
    expect(loops).toHaveAttribute('aria-checked', 'true');

    // Selecting another subject reloads topics and clears selection; start is
    // disabled again because zero topics are selected (Req 8.2, 8.4).
    fireEvent.click(screen.getByRole('button', { name: 'Operating Systems' }));
    await waitFor(() =>
      expect(screen.getByRole('button', { name: 'Start diagnostic' })).toBeDisabled(),
    );
  });
});

describe('Diagnostic_Page topic toggling and start control (Req 8.3, 8.4, 8.5)', () => {
  it('toggles an available topic and enables/disables the start control', async () => {
    getSupabase.mockReturnValue(
      makeSupabase({ programs: PROGRAMS, subjects: SUBJECTS, topics: TOPICS, questions: QUESTIONS }),
    );
    renderDiagnostic();

    fireEvent.click(await screen.findByRole('button', { name: 'Introduction to Programming' }));

    const start = await screen.findByRole('button', { name: 'Start diagnostic' });
    // Zero topics selected: disabled (Req 8.4).
    expect(start).toBeDisabled();

    const variables = screen.getByRole('checkbox', { name: /Variables and Data Types/ });
    fireEvent.click(variables);
    expect(variables).toHaveAttribute('aria-checked', 'true');
    // One topic selected: enabled (Req 8.4).
    expect(start).toBeEnabled();

    // Toggling off returns to disabled (Req 8.3, 8.4).
    fireEvent.click(variables);
    expect(variables).toHaveAttribute('aria-checked', 'false');
    expect(start).toBeDisabled();
  });

  it('does not change the selected state of an unavailable topic when activated (Req 8.5)', async () => {
    getSupabase.mockReturnValue(
      makeSupabase({ programs: PROGRAMS, subjects: SUBJECTS, topics: TOPICS, questions: QUESTIONS }),
    );
    renderDiagnostic();

    fireEvent.click(await screen.findByRole('button', { name: 'Introduction to Programming' }));

    const emptyTopic = await screen.findByRole('checkbox', { name: /Empty Topic/ });
    expect(emptyTopic).toHaveAttribute('aria-checked', 'false');
    // Disabled buttons do not fire onClick, so the state stays unchanged and
    // the start control stays disabled.
    fireEvent.click(emptyTopic);
    expect(emptyTopic).toHaveAttribute('aria-checked', 'false');
    expect(screen.getByRole('button', { name: 'Start diagnostic' })).toBeDisabled();
  });
});
