import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';

const amMock = vi.hoisted(() => ({ profile: null, update: null, refreshProfile: null }));

vi.mock('../lib/amAuth.jsx', () => ({
  useAmAuth: () => ({ profile: amMock.profile, user: { id: 'u1' }, refreshProfile: amMock.refreshProfile, signOut: vi.fn() }),
}));

vi.mock('../lib/amSupabase.js', () => ({
  amSupabase: {
    from: () => ({ update: (payload) => ({ eq: async () => (amMock.update(payload), { error: null }) }) }),
  },
  amFriendlyError: (e) => e?.message ?? String(e),
}));

const { default: AmProfilePage } = await import('./amProfilePage.jsx');

const base = {
  name: 'Ada Lovelace',
  school: 'Analytical College',
  languages: ['English'],
  avatar_url: null,
  rating_avg: 0,
  rating_count: 0,
  sessions_count: 0,
  success_rate: 0,
  onboarded: true,
};

function renderPage(profile) {
  amMock.profile = profile;
  return render(
    <MemoryRouter>
      <AmProfilePage />
    </MemoryRouter>,
  );
}

beforeEach(() => {
  amMock.update = vi.fn();
  amMock.refreshProfile = vi.fn(async () => {});
});

describe('AmProfilePage subjects modes', () => {
  it('diagnostic profile shows read-only topic chips, a Retake link, and saves without subject arrays', async () => {
    // Diagnostic topic names ('Loops') and 4+ entries are shown as-is.
    renderPage({
      ...base,
      subjects_source: 'diagnostic',
      weak_subjects: ['Loops', 'Fractions', 'Grammar', 'Verbs'],
      strong_subjects: ['Algebra'],
    });

    const weakList = screen.getByRole('list', { name: 'I want help with' });
    expect(within(weakList).getAllByRole('listitem').map((li) => li.textContent)).toEqual(['Loops', 'Fractions', 'Grammar', 'Verbs']);
    expect(within(screen.getByRole('list', { name: 'I can help with' })).getByText('Algebra')).toBeInTheDocument();
    // No editable AM_SUBJECTS pickers (language pills are separate checkboxes).
    expect(screen.queryByText('Math')).not.toBeInTheDocument();
    expect(screen.getByRole('link', { name: /Retake diagnostic/ })).toHaveAttribute('href', '/diagnostic');

    await userEvent.click(screen.getByRole('button', { name: /Save changes/ }));

    expect(amMock.update).toHaveBeenCalledTimes(1);
    const payload = amMock.update.mock.calls[0][0];
    expect(payload).toEqual({ name: 'Ada Lovelace', school: 'Analytical College', languages: ['English'], avatar_url: null });
    expect(payload).not.toHaveProperty('weak_subjects');
    expect(payload).not.toHaveProperty('strong_subjects');
  }, 15000);

  it('diagnostic profile with no strong or weak topics shows a short note', () => {
    renderPage({ ...base, subjects_source: 'diagnostic', weak_subjects: [], strong_subjects: [] });
    expect(screen.queryByRole('list')).not.toBeInTheDocument();
    expect(screen.getByText(/All topics are Developing/)).toBeInTheDocument();
  });

  it('onboarding profile shows read-only topics, a Take diagnostic link, and saves without subject arrays', async () => {
    renderPage({ ...base, subjects_source: 'onboarding', weak_subjects: ['Math'], strong_subjects: ['English'] });

    expect(screen.queryByText(/Retake diagnostic/)).not.toBeInTheDocument();
    expect(screen.getByText('Take diagnostic').closest('a')).toHaveAttribute('href', '/diagnostic');
    // No subject pickers for anyone.
    expect([...document.querySelectorAll('[role="checkbox"]')].some((el) => /Math/.test(el.textContent))).toBe(false);
    expect(within(screen.getByRole('list', { name: 'I want help with' })).getByText('Math')).toBeInTheDocument();

    await userEvent.click(screen.getByText('Save changes').closest('button'));

    expect(amMock.update).toHaveBeenCalledTimes(1);
    const payload = amMock.update.mock.calls[0][0];
    expect(payload).toEqual({ name: 'Ada Lovelace', school: 'Analytical College', languages: ['English'], avatar_url: null });
  }, 15000);

  it('new onboarding profile with empty arrays shows empty states and Take diagnostic', () => {
    renderPage({ ...base, subjects_source: 'onboarding', weak_subjects: [], strong_subjects: [] });
    expect(screen.getByText('No weak topics right now.')).toBeInTheDocument();
    expect(screen.getByText('No proficient topics yet.')).toBeInTheDocument();
    expect(screen.getByText('Take diagnostic')).toBeInTheDocument();
    expect(screen.queryByText(/All topics are Developing/)).not.toBeInTheDocument();
  });
});
