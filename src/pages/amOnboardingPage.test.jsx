import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';

const amMock = vi.hoisted(() => ({ profile: null, user: null, update: null, refreshProfile: null }));

vi.mock('../lib/amAuth.jsx', () => ({
  useAmAuth: () => ({ profile: amMock.profile, user: amMock.user, refreshProfile: amMock.refreshProfile }),
}));

vi.mock('../lib/amSupabase.js', () => ({
  amSupabase: {
    from: () => ({ update: (payload) => ({ eq: async () => (amMock.update(payload), { error: null }) }) }),
  },
  amFriendlyError: (e) => e?.message ?? String(e),
}));

const { default: AmOnboardingPage } = await import('./amOnboardingPage.jsx');

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/onboarding']}>
      <Routes>
        <Route path="/onboarding" element={<AmOnboardingPage />} />
        <Route path="/home" element={<p>Home page</p>} />
      </Routes>
    </MemoryRouter>,
  );
}

beforeEach(() => {
  amMock.update = vi.fn();
  amMock.refreshProfile = vi.fn(async () => {});
  amMock.user = { id: 'u1', app_metadata: { provider: 'email' }, user_metadata: { full_name: 'Ada Lovelace' } };
  amMock.profile = { name: '', school: '', languages: [], weak_subjects: [], strong_subjects: [], avatar_url: null, onboarded: false };
});

describe('AmOnboardingPage (basics only)', () => {
  it('has no subjects step and finishing basics saves without subject arrays, then goes to /home', async () => {
    renderPage();
    expect(screen.queryByText(/What do you want to swap/)).not.toBeInTheDocument();
    expect(screen.queryByText(/Subjects/)).not.toBeInTheDocument();

    await userEvent.type(screen.getByLabelText(/School or organization/), 'Analytical College');
    await userEvent.click(screen.getByText('Finish').closest('button'));

    expect(await screen.findByText('Home page')).toBeInTheDocument();
    expect(amMock.update).toHaveBeenCalledTimes(1);
    const payload = amMock.update.mock.calls[0][0];
    expect(payload).toEqual({
      name: 'Ada Lovelace',
      school: 'Analytical College',
      languages: ['English'],
      avatar_url: null,
      onboarded: true,
    });
    expect(payload).not.toHaveProperty('weak_subjects');
    expect(payload).not.toHaveProperty('strong_subjects');
    expect(amMock.refreshProfile).toHaveBeenCalledTimes(1);
  }, 15000);

  it('blocks finishing when the basics are invalid', async () => {
    renderPage();
    await userEvent.click(screen.getByText('Finish').closest('button'));
    expect(amMock.update).not.toHaveBeenCalled();
    expect(screen.getByText('Enter your school or organization.')).toBeInTheDocument();
  });
});
