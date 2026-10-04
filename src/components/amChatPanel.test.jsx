import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

vi.mock('../lib/amChat.js', () => ({ amAttachmentUrl: async () => null }));

const { AmChatPanel } = await import('./amChatPanel.jsx');

// jsdom has no scrollIntoView.
Element.prototype.scrollIntoView = () => {};

function renderPanel(props = {}) {
  const onSend = props.onSend ?? vi.fn(async () => {});
  render(<AmChatPanel messages={[]} loading={false} members={[]} selfId="u1" onSend={onSend} {...props} />);
  return { onSend, input: screen.getByRole('textbox', { name: 'Message' }), send: screen.getByRole('button', { name: 'Send message' }) };
}

describe('AmChatPanel', () => {
  it('disables send while the message is empty', () => {
    const { input, send } = renderPanel();
    expect(send).toBeDisabled();
    expect(input).toBeEnabled();
  });

  it('sends once when typing and submitting', async () => {
    const user = userEvent.setup();
    const { onSend, input, send } = renderPanel();
    await user.type(input, 'hello');
    expect(send).toBeEnabled();
    await user.click(send);
    expect(onSend).toHaveBeenCalledTimes(1);
    expect(onSend).toHaveBeenCalledWith({ body: 'hello', file: null });
    expect(input).toHaveValue('');
  });

  it('disables input and send until the chat is ready', () => {
    const { input, send } = renderPanel({ ready: false });
    expect(input).toBeDisabled();
    expect(input).toHaveAttribute('placeholder', 'Connecting chat…');
    expect(send).toBeDisabled();
  });
});
