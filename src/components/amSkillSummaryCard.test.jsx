import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';

const amMock = vi.hoisted(() => ({ mastery: null }));

vi.mock('../lib/amMastery.jsx', () => ({ useAmMastery: () => amMock.mastery }));

const { AmSkillSummaryCard } = await import('./amSkillSummaryCard.jsx');

function mastery(overrides) {
  return { records: [], count: 0, loading: false, error: null, refresh: vi.fn(), ...overrides };
}

function renderCard() {
  return render(
    <MemoryRouter initialEntries={['/home']}>
      <Routes>
        <Route path="/home" element={<AmSkillSummaryCard />} />
        <Route path="/diagnostic" element={<p>Diagnostic page</p>} />
      </Routes>
    </MemoryRouter>,
  );
}

beforeEach(() => {
  amMock.mastery = mastery();
});

describe('AmSkillSummaryCard', () => {
  it('shows overall %, level counts and a Retake Diagnostic button when records exist (Req 4.1, 4.2)', () => {
    const records = [
      { topic_id: 't1', mastery_probability: '0.9', mastery_level: 'Proficient' },
      { topic_id: 't2', mastery_probability: 0.5, mastery_level: 'Developing' },
      { topic_id: 't3', mastery_probability: 0.3, mastery_level: 'Weak' },
      { topic_id: 't4', mastery_probability: 0.1, mastery_level: 'Weak' },
    ];
    amMock.mastery = mastery({ records, count: records.length });
    renderCard();

    expect(screen.getByRole('progressbar', { name: 'Overall mastery' })).toHaveAttribute('aria-valuenow', '45');
    expect(screen.getByText('Proficient: 1 topic')).toBeInTheDocument();
    expect(screen.getByText('Developing: 1 topic')).toBeInTheDocument();
    expect(screen.getByText('Weak: 2 topics')).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: 'Retake Diagnostic' }));
    expect(screen.getByText('Diagnostic page')).toBeInTheDocument();
  });

  it('shows a Take Diagnostic CTA when there are no records (Req 4.3)', () => {
    renderCard();
    expect(screen.queryByRole('button', { name: 'Retake Diagnostic' })).toBeNull();
    fireEvent.click(screen.getByRole('button', { name: 'Take Diagnostic' }));
    expect(screen.getByText('Diagnostic page')).toBeInTheDocument();
  });

  it('shows a retry on load error', () => {
    const refresh = vi.fn();
    amMock.mastery = mastery({ error: 'boom', refresh });
    renderCard();
    expect(screen.getByRole('alert')).toHaveTextContent("couldn't load");
    fireEvent.click(screen.getByRole('button', { name: 'Try again' }));
    expect(refresh).toHaveBeenCalledTimes(1);
  });
});
