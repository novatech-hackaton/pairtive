import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { AmModal } from './amModal.jsx';
import { AmButton } from './amButton.jsx';

describe('AmModal', () => {
  it('exposes dialog semantics and a labelled title', () => {
    render(<AmModal open onClose={() => {}} title="Record session" description="Everyone must agree." />);
    const dialog = screen.getByRole('dialog');
    expect(dialog).toHaveAttribute('aria-modal', 'true');
    expect(dialog).toHaveAccessibleName('Record session');
  });

  it('closes on Escape when dismissible', async () => {
    const onClose = vi.fn();
    render(<AmModal open onClose={onClose} title="X" />);
    await userEvent.keyboard('{Escape}');
    expect(onClose).toHaveBeenCalled();
  });

  it('does not close on Escape when not dismissible', async () => {
    const onClose = vi.fn();
    render(<AmModal open onClose={onClose} title="X" dismissible={false} />);
    await userEvent.keyboard('{Escape}');
    expect(onClose).not.toHaveBeenCalled();
  });

  it('keeps Tab focus inside the dialog', async () => {
    render(
      <AmModal open onClose={() => {}} title="X" footer={<AmButton>Only</AmButton>}>
        <button type="button">Inside</button>
      </AmModal>,
    );
    await userEvent.tab();
    expect(screen.getByRole('dialog').contains(document.activeElement)).toBe(true);
  });
});
