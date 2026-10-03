import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { AmSubjectChip, AmSubjectToggle } from './amSubjectChip.jsx';

describe('subject chips', () => {
  it('renders a labelled chip', () => {
    render(<AmSubjectChip subject="Math" />);
    expect(screen.getByText('Math')).toBeInTheDocument();
  });

  it('toggle exposes checkbox semantics and fires', async () => {
    const onToggle = vi.fn();
    render(<AmSubjectToggle subject="English" selected={false} onToggle={onToggle} />);
    const box = screen.getByRole('checkbox', { name: /English/ });
    expect(box).toHaveAttribute('aria-checked', 'false');
    await userEvent.click(box);
    expect(onToggle).toHaveBeenCalled();
  });
});
