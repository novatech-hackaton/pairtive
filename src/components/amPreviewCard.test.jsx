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
