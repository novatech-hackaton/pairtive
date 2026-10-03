import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';

const amMock = vi.hoisted(() => ({ queue: null }));

vi.mock('../lib/amAuth.jsx', () => ({
  useAmAuth: () => ({
    user: { id: 'u1' },
    profile: { name: 'Ada', school: 'Analytical College', rules_accepted_at: '2026-01-01T00:00:00Z', weak_subjects: [], strong_subjects: [], avatar_url: null },
    refreshProfile: vi.fn(),
  }),
}));
vi.mock('../lib/amSupabase.js', () => ({ amSupabase: { rpc: vi.fn(async () => ({ error: null })) } }));
vi.mock('../lib/amMedia.js', () => ({ amPeekLocalStream: vi.fn(), amStopLocalStream: vi.fn() }));
vi.mock('../lib/amQueue.js', () => ({ useAmQueue: () => amMock.queue }));
vi.mock('../components/amCameraPreview.jsx', () => ({ AmCameraPreview: () => null }));

const { default: AmMatchPage } = await import('./amMatchPage.jsx');

function queue(overrides) {
  return { phase: 'idle', proposal: null, waiting: 0, error: '', errorReason: null, sessionId: null, myResponse: null, start: vi.fn(), respond: vi.fn(), leave: vi.fn(), ...overrides };
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/match']}>
      <Routes>
        <Route path="/match" element={<AmMatchPage />} />
        <Route path="/diagnostic" element={<p>Diagnostic page</p>} />
      </Routes>
    </MemoryRouter>,
  );
}

beforeEach(() => {
  amMock.queue = queue();
});

describe('AmMatchPage diagnostic gate', () => {
  it('redirects to /diagnostic when the queue reports diagnostic-required', async () => {
    amMock.queue = queue({ phase: 'error', error: 'Take the diagnostic before matching.', errorReason: 'diagnostic-required' });
    renderPage();
    expect(await screen.findByText('Diagnostic page')).toBeInTheDocument();
  });

  it('stays on the page and shows other 403 errors inline', () => {
    amMock.queue = queue({ phase: 'error', error: 'Your account is suspended.', errorReason: null });
    renderPage();
    expect(screen.queryByText('Diagnostic page')).not.toBeInTheDocument();
    expect(screen.getByRole('alert')).toHaveTextContent('Your account is suspended.');
  });
});
