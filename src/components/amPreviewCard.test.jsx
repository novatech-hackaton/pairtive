import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { AmPreviewCard } from './amPreviewCard.jsx';

const me = { weak_subjects: ['Math'], strong_subjects: ['English', 'Linear Equations'], languages: ['English'] };

function renderCard(partner) {
  const members = [
    { user_id: 'me', accepted: null, profile: { name: 'Me' } },
    { user_id: 'p1', accepted: null, profile: { name: 'Ana', school: 'PSHS', languages: ['English'], ...partner } },
  ];
  return render(<AmPreviewCard me={me} myId="me" members={members} mode="buddy" secondsLeft={10} onAccept={() => {}} onNext={() => {}} />);
}

describe('AmPreviewCard practice block', () => {
  it('shows shared strengths (including unknown diagnostic topics) as practice topics', () => {
    renderCard({ weak_subjects: [], strong_subjects: ['Linear Equations'] });
    expect(screen.getByText(/You'll practice together/)).toBeInTheDocument();
    const topic = screen.getByText('Linear Equations', { selector: 'strong' });
    expect(topic.parentElement).toHaveTextContent('Practice Linear Equations together with Ana');
  });

  it('omits the block when there are no shared strengths', () => {
    renderCard({ weak_subjects: ['English'], strong_subjects: ['Math'] });
    expect(screen.queryByText(/You'll practice together/)).not.toBeInTheDocument();
    expect(screen.getByText('English', { selector: 'strong' }).parentElement).toHaveTextContent("You'll help Ana with English");
  });
});

describe('AmPreviewCard match confirmation', () => {
  const card = (members, myResponse, mode = 'buddy') =>
    render(<AmPreviewCard me={me} myId="me" members={members} mode={mode} secondsLeft={10} myResponse={myResponse} onAccept={() => {}} onNext={() => {}} />);
  const m = (id, name, accepted) => ({ user_id: id, accepted, profile: { name } });

  it('after I accept, confirms the match and shows who is still waiting', () => {
    card([m('me', 'Me', true), m('p1', 'Ana', true), m('p2', 'Ben', null)], true, 'peers');
    const status = screen.getByText(/You accepted! You're matched with Ana & Ben/).closest('[role="status"]');
    expect(status).toHaveAttribute('aria-live', 'polite');
    expect(status).toHaveTextContent('Waiting for Ben to accept…');
    expect(status).toHaveTextContent(/Ana\s*Accepted ✓/);
    expect(status).toHaveTextContent(/Ben\s*Waiting…/);
  });

  it('when everyone accepted, says the buddy pair is matched', () => {
    card([m('me', 'Me', true), m('p1', 'Ana', true)], true);
    expect(screen.getByRole('status')).toHaveTextContent('You and Ana are matched! Starting your session…');
  });

  it('tells me the partner is ready before I accept', () => {
    card([m('me', 'Me', null), m('p1', 'Ana', true)], null);
    expect(screen.getByText('Ana accepted — tap Accept to start')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Accept/ })).toBeInTheDocument();
  });
});
