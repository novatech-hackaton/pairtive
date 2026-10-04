import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';

// Routing tests for AmApp: the diagnostic guard on /match, legacy-user access, and AmGuard
// coverage of /diagnostic and /skillgps (Req 3.1, 3.2, 7.3, 10.3–10.5).

const am = vi.hoisted(() => ({ auth: null, mastery: null }));

vi.mock('./lib/amAuth.jsx', () => ({ useAmAuth: () => am.auth }));
vi.mock('./lib/amMastery.jsx', () => ({ useAmMastery: () => am.mastery }));
vi.mock('./lib/amSupabase.js', () => ({ amSupabaseConfigured: true, amSupabase: {} }));
vi.mock('./lib/amRealtime.js', () => ({ useAmUnread: () => ({ unread: 0 }) }));
vi.mock('./components/amInviteListener.jsx', () => ({ AmInviteListener: () => null }));
vi.mock('./pages/amSetupNotice.jsx', () => ({ AmSetupNotice: () => <p>Setup notice</p> }));

// Page stubs keep the test fast and isolate routing behaviour.
// vi.mock factories are hoisted, so the stub builder must be hoisted too.
const stub = vi.hoisted(() => (label) => () => ({ default: () => <p>{label}</p> }));
vi.mock('./pages/amLoginPage.jsx', stub('Login page'));
vi.mock('./pages/amSignupPage.jsx', stub('Signup page'));
vi.mock('./pages/amOnboardingPage.jsx', stub('Onboarding page'));
vi.mock('./pages/amHomePage.jsx', stub('Home page'));
vi.mock('./pages/amMatchPage.jsx', stub('Match page'));
vi.mock('./pages/amSessionPage.jsx', stub('Session page'));
vi.mock('./pages/amRatePage.jsx', stub('Rate page'));
vi.mock('./pages/amMessagesPage.jsx', stub('Messages page'));
vi.mock('./pages/amThreadPage.jsx', stub('Thread page'));
vi.mock('./pages/amProfilePage.jsx', stub('Profile page'));
vi.mock('./pages/amSuspendedPage.jsx', stub('Suspended page'));
vi.mock('./pages/amUiPreviewPage.jsx', stub('UI preview page'));
vi.mock('./pages/amDiagnosticPage.jsx', stub('Diagnostic page'));
vi.mock('./pages/amSkillGpsPage.jsx', stub('SkillGPS page'));

const { default: AmApp } = await import('./amApp.jsx');

const LEGACY_PROFILE = {
  name: 'Ada',
  avatar_url: null,
  subjects_source: 'onboarding',
  weak_subjects: ['Math'],
  strong_subjects: ['English'],
};

function signedIn(profile = LEGACY_PROFILE) {
  return { user: { id: 'u1' }, loading: false, profile, profileComplete: true, isSuspended: false, signOut: vi.fn() };
}

function mastery(overrides) {
  return { records: [], count: 0, loading: false, error: null, refresh: vi.fn(), ...overrides };
}

function renderAt(path) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <AmApp />
    </MemoryRouter>,
  );
}

beforeEach(() => {
  am.auth = signedIn();
  am.mastery = mastery();
});

describe('AmDiagnosticGuard on /match', () => {
  it('redirects to /diagnostic when the user has zero Mastery_Records', async () => {
    renderAt('/match');
    expect(await screen.findByText('Diagnostic page')).toBeInTheDocument();
    expect(screen.queryByText('Match page')).not.toBeInTheDocument();
  });

  it('renders /match when the user has at least one Mastery_Record', async () => {
    am.mastery = mastery({ count: 1 });
    renderAt('/match');
    expect(await screen.findByText('Match page')).toBeInTheDocument();
  });

  it('shows the loader while mastery records load', () => {
    am.mastery = mastery({ loading: true });
    renderAt('/match');
    expect(screen.getAllByRole('status').length).toBeGreaterThan(0);
    expect(screen.queryByText('Match page')).not.toBeInTheDocument();
    expect(screen.queryByText('Diagnostic page')).not.toBeInTheDocument();
  });

  it('fails closed on a load error and retries via refresh', async () => {
    const refresh = vi.fn();
    am.mastery = mastery({ count: 3, error: new Error('network'), refresh });
    renderAt('/match');
    fireEvent.click(await screen.findByRole('button', { name: /try again/i }));
    expect(refresh).toHaveBeenCalledTimes(1);
    expect(screen.queryByText('Match page')).not.toBeInTheDocument();
  });
});

describe('legacy users (onboarding-sourced, zero records)', () => {
  it.each([
    ['/home', 'Home page'],
    ['/messages', 'Messages page'],
    ['/profile', 'Profile page'],
  ])('can still reach %s', async (path, label) => {
    renderAt(path);
    expect(await screen.findByText(label)).toBeInTheDocument();
    expect(screen.queryByText('Diagnostic page')).not.toBeInTheDocument();
  });
});

describe('/diagnostic and /skillgps sit behind AmGuard', () => {
  it.each([
    ['/diagnostic', 'Diagnostic page'],
    ['/skillgps', 'SkillGPS page'],
  ])('renders %s inside the shell for signed-in users', async (path, label) => {
    renderAt(path);
    expect(await screen.findByText(label)).toBeInTheDocument();
    expect(screen.getAllByRole('link', { name: /skillgps/i }).length).toBeGreaterThan(0);
  });

  it.each(['/diagnostic', '/skillgps', '/home'])('redirects signed-out users from %s to /login', async (path) => {
    am.auth = { user: null, loading: false, profile: null, profileComplete: false, isSuspended: false, signOut: vi.fn() };
    renderAt(path);
    expect(await screen.findByText('Login page')).toBeInTheDocument();
  });

  it('redirects incomplete profiles from /skillgps to /onboarding', async () => {
    am.auth = { ...signedIn(), profileComplete: false };
    renderAt('/skillgps');
    expect(await screen.findByText('Onboarding page')).toBeInTheDocument();
  });
});
