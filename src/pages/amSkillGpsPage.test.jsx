import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';

const amMock = vi.hoisted(() => ({ state: null }));

vi.mock('../lib/amMastery.jsx', () => ({ useAmMastery: () => amMock.state }));

const { default: AmSkillGpsPage } = await import('./amSkillGpsPage.jsx');

function renderPage(state) {
  amMock.state = { records: [], count: 0, loading: false, error: null, refresh: vi.fn(), ...state };
  return render(
    <MemoryRouter initialEntries={['/skillgps']}>
      <Routes>
        <Route path="/skillgps" element={<AmSkillGpsPage />} />
        <Route path="/match" element={<p>match page</p>} />
        <Route path="/diagnostic" element={<p>diagnostic page</p>} />
      </Routes>
    </MemoryRouter>,
  );
}

const rec = (topic_id, topic_name, mastery_probability, mastery_level) => ({ topic_id, topic_name, mastery_probability, mastery_level });

beforeEach(() => {
  amMock.state = null;
});

describe('AmSkillGpsPage', () => {
  it('shows summary, skill map, ordered recommendations and continues to /match', async () => {
    const records = [rec(1, 'Loops', '0.85', 'Proficient'), rec(2, 'Recursion', '0.2', 'Weak'), rec(3, 'Functions', 0.5, 'Developing')];
    renderPage({ records, count: 3 });

    expect(screen.getByRole('heading', { level: 1, name: /SkillGPS/ })).toBeInTheDocument();
    expect(screen.getByText('52%')).toBeInTheDocument(); // round(mean(.85,.2,.5) * 100)
    expect(screen.getByRole('progressbar', { name: 'Recursion' })).toHaveAttribute('aria-valuenow', '20');
    expect(screen.getByRole('progressbar', { name: 'Loops' })).toHaveAttribute('aria-valuenow', '85');
    // Recommendations: Weak → Developing → Proficient.
    expect(screen.getAllByRole('heading', { level: 3 }).map((h) => h.textContent)).toEqual(['Recursion', 'Functions', 'Loops']);
    expect(screen.queryByText(/All topics are Developing/)).not.toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: /Continue to match/ }));
    expect(screen.getByText('match page')).toBeInTheDocument();
  });

  it('shows the all-Developing notice when the bridge yields no strong or weak topics', () => {
    renderPage({ records: [rec(1, 'Loops', '0.5', 'Developing')], count: 1 });
    expect(screen.getByText(/All topics are Developing/)).toBeInTheDocument();
  });

  it('offers Take Diagnostic with zero records', async () => {
    renderPage({});
    await userEvent.click(screen.getByRole('button', { name: /Take Diagnostic/ }));
    expect(screen.getByText('diagnostic page')).toBeInTheDocument();
  });

  it('shows an error with retry', async () => {
    const refresh = vi.fn();
    renderPage({ error: 'boom', refresh });
    expect(screen.getByRole('alert')).toHaveTextContent(/couldn.t load/i);
    await userEvent.click(screen.getByRole('button', { name: /Try again/ }));
    expect(refresh).toHaveBeenCalledTimes(1);
  });
});
