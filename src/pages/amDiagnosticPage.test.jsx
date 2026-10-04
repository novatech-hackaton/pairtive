import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';

const am = vi.hoisted(() => ({ calls: [], refreshProfile: null, masteryRefresh: null, predictFailures: 0 }));
const AM_USER = { id: 'u1' };

vi.mock('../lib/amAuth.jsx', () => ({
  useAmAuth: () => ({ user: AM_USER, refreshProfile: am.refreshProfile }),
}));
vi.mock('../lib/amMastery.jsx', () => ({
  useAmMastery: () => ({ records: [], count: 0, loading: false, error: null, refresh: am.masteryRefresh }),
}));
vi.mock('../lib/amDiagnostic.js', () => {
  const log = (name) => (...args) => am.calls.push([name, ...args]);
  return {
    amFetchSubjects: vi.fn(async () => [{ id: 's1', subject_name: 'Programming' }]),
    amFetchTopics: vi.fn(async () => [
      { id: 't1', topic_name: 'Loops', description: 'for and while', questionCount: 1 },
      { id: 't2', topic_name: 'Graphs', description: null, questionCount: 0 },
    ]),
    amFetchQuestions: vi.fn(async () => [
      { id: 'q1', topic_id: 't1', question: 'Which keyword starts a loop?', choice_a: 'for', choice_b: 'if', choice_c: 'let', choice_d: 'try', correct_answer: 'A', difficulty: 2 },
    ]),
    amStartAttempts: vi.fn(async (...args) => {
      log('start')(...args);
      return { t1: 'a1' };
    }),
    amSaveAnswers: vi.fn(async (...args) => log('save')(...args)),
    amPredictTopic: vi.fn(async (...args) => {
      log('predict')(...args);
      if (am.predictFailures > 0) {
        am.predictFailures -= 1;
        throw new Error('Service down');
      }
      return { mastery_probability: 0.82, predicted_label: 'Proficient', confidence: 0.9 };
    }),
    amCompleteAttempt: vi.fn(async (...args) => log('complete')(...args)),
    amUpsertMastery: vi.fn(async (...args) => log('mastery')(...args)),
    amApplyBridge: vi.fn(async () => log('bridge')()),
  };
});

const { default: AmDiagnosticPage, amElapsedSeconds, AM_MIN_RESPONSE_SECONDS } = await import('./amDiagnosticPage.jsx');

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/diagnostic']}>
      <Routes>
        <Route path="/diagnostic" element={<AmDiagnosticPage />} />
        <Route path="/skillgps" element={<p>SkillGPS page</p>} />
      </Routes>
    </MemoryRouter>,
  );
}

async function answerOneTopic(user) {
  await user.click(await screen.findByRole('button', { name: 'Programming' }));
  expect(await screen.findByRole('checkbox', { name: /Graphs/ })).toBeDisabled();
  expect(screen.getByText('Unavailable')).toBeInTheDocument();
  await user.click(screen.getByRole('checkbox', { name: /Loops/ }));
  await user.click(screen.getByRole('button', { name: /Start diagnostic/ }));
  const group = await screen.findByRole('group', { name: 'Which keyword starts a loop?' });
  expect(group).toBeInTheDocument();
  // Keyboard: Tab into the radio group and pick the first option with Space.
  screen.getByRole('radio', { name: 'A. for' }).focus();
  await user.keyboard(' ');
  expect(screen.getByRole('radio', { name: 'A. for' })).toBeChecked();
  await user.click(screen.getByRole('button', { name: /Submit diagnostic/ }));
}

beforeEach(() => {
  am.calls = [];
  am.predictFailures = 0;
  am.refreshProfile = vi.fn(async () => {});
  am.masteryRefresh = vi.fn(async () => []);
});

describe('amElapsedSeconds', () => {
  it('clamps to a small positive minimum', () => {
    expect(amElapsedSeconds(1000, 1000)).toBe(AM_MIN_RESPONSE_SECONDS);
    expect(amElapsedSeconds(2000, 1000)).toBe(AM_MIN_RESPONSE_SECONDS);
    expect(amElapsedSeconds(0, 2500)).toBe(2.5);
  });
});

describe('AmDiagnosticPage', () => {
  it('runs the submit pipeline in order with the auth user, then opens SkillGPS', async () => {
    const user = userEvent.setup();
    renderPage();
    await answerOneTopic(user);

    expect(await screen.findByText('SkillGPS page')).toBeInTheDocument();
    expect(am.calls.map((c) => c[0])).toEqual(['start', 'save', 'predict', 'complete', 'mastery', 'bridge']);
    expect(am.calls[0][1]).toBe(AM_USER);
    expect(am.calls[0][2]).toEqual({ subjectId: 's1', topicIds: ['t1'] });
    const [, saveUser, saveArgs] = am.calls[1];
    expect(saveUser).toBe(AM_USER);
    expect(saveArgs.attemptId).toBe('a1');
    expect(saveArgs.answers[0]).toMatchObject({ question_id: 'q1', selected_answer: 'A', is_correct: true });
    expect(saveArgs.answers[0].response_time).toBeGreaterThan(0);
    expect(am.refreshProfile).toHaveBeenCalledTimes(1);
    expect(am.masteryRefresh).toHaveBeenCalledTimes(1);
  });

  it('shows an alert on predict failure and retries from the failed step', async () => {
    am.predictFailures = 1;
    const user = userEvent.setup();
    renderPage();
    await answerOneTopic(user);

    expect(await screen.findByRole('alert')).toHaveTextContent(/mastery prediction.*Service down/);
    expect(am.refreshProfile).not.toHaveBeenCalled();
    await user.click(screen.getByRole('button', { name: /Retry/ }));

    expect(await screen.findByText('SkillGPS page')).toBeInTheDocument();
    expect(am.calls.map((c) => c[0])).toEqual(['start', 'save', 'predict', 'predict', 'complete', 'mastery', 'bridge']);
    // The retried predict used the same answers the user submitted.
    expect(am.calls[3][1].answers).toEqual(am.calls[2][1].answers);
  });
});
