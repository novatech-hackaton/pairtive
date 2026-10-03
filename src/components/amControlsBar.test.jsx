import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { AmControlsBar } from './amControlsBar.jsx';

const noop = () => {};
const base = {
  micOn: true, camOn: true, screenOn: false, recording: false, canScreenShare: true, unread: 0, mode: 'buddy',
  onToggleMic: noop, onToggleCam: noop, onToggleScreen: noop, onToggleChat: noop, onToggleNotes: noop, onRecord: noop, onNext: noop, onStop: noop,
};

describe('AmControlsBar', () => {
  it('labels every icon control for screen readers', () => {
    render(<AmControlsBar {...base} />);
    expect(screen.getByLabelText('Mute')).toBeInTheDocument();
    expect(screen.getByLabelText('Turn camera off')).toBeInTheDocument();
    expect(screen.getByLabelText('Share screen')).toBeInTheDocument();
    expect(screen.getByLabelText('Record session')).toBeInTheDocument();
    expect(screen.getByLabelText('Stop and finish')).toBeInTheDocument();
  });

  it('hides the screen-share control when unsupported', () => {
    render(<AmControlsBar {...base} canScreenShare={false} />);
    expect(screen.queryByLabelText('Share screen')).not.toBeInTheDocument();
  });

  it('reflects muted/recording state in labels', () => {
    render(<AmControlsBar {...base} micOn={false} recording />);
    expect(screen.getByLabelText('Unmute')).toBeInTheDocument();
    expect(screen.getByLabelText('Recording in progress')).toBeInTheDocument();
  });

  it('fires callbacks on click', async () => {
    const onToggleMic = vi.fn();
    render(<AmControlsBar {...base} onToggleMic={onToggleMic} />);
    await userEvent.click(screen.getByLabelText('Mute'));
    expect(onToggleMic).toHaveBeenCalled();
  });
});
