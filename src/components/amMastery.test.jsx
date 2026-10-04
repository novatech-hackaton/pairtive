import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { AmMasteryBadge } from './amMasteryBadge.jsx';
import { AmMasteryBar } from './amMasteryBar.jsx';

describe('mastery badge and bar', () => {
  it('badge shows the level as text with a matching tone', () => {
    render(<AmMasteryBadge level="Weak" />);
    expect(screen.getByText('Weak').className).toMatch(/rose/);
  });

  it('badge falls back to a slate Pending pill for unknown levels', () => {
    render(<AmMasteryBadge level={null} />);
    expect(screen.getByText('Pending').className).toMatch(/slate/);
  });

  it('bar exposes progressbar semantics, coerces numeric strings and clamps', () => {
    render(
      <>
        <AmMasteryBar value="0.456" label="Fractions" />
        <AmMasteryBar value={1.7} ariaLabel="Overall mastery" />
      </>,
    );
    const fractions = screen.getByRole('progressbar', { name: 'Fractions' });
    expect(fractions).toHaveAttribute('aria-valuenow', '46');
    expect(fractions).toHaveAttribute('aria-valuemin', '0');
    expect(fractions).toHaveAttribute('aria-valuemax', '100');
    expect(screen.getByRole('progressbar', { name: 'Overall mastery' })).toHaveAttribute('aria-valuenow', '100');
  });
});
