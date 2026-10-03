import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';

// The pages read Supabase on mount; stub the client so the router test does
// not touch the network. getSupabase returns null -> pages render their shells.
vi.mock('../src/lib/dsSupabaseClient.js', () => ({
  getSupabase: () => null,
  getConfigErrors: () => [],
}));

// eslint-disable-next-line import/first
import DsApp from '../src/dsApp.jsx';

function renderAt(path) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <DsApp />
    </MemoryRouter>,
  );
}

describe('Router (no login; two modules only)', () => {
  it('maps /diagnostic to the Diagnostic_Page', () => {
    renderAt('/diagnostic');
    expect(screen.getByRole('heading', { name: 'Diagnostic' })).toBeInTheDocument();
  });

  it('maps /skillgps to the SkillGPS_Page', () => {
    renderAt('/skillgps');
    expect(screen.getByRole('heading', { name: 'SkillGPS' })).toBeInTheDocument();
  });

  it('redirects / to /diagnostic', () => {
    renderAt('/');
    expect(screen.getByRole('heading', { name: 'Diagnostic' })).toBeInTheDocument();
  });

  it('redirects an unmatched path to /diagnostic', () => {
    renderAt('/does-not-exist');
    expect(screen.getByRole('heading', { name: 'Diagnostic' })).toBeInTheDocument();
  });
});
