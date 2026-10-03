import { CircleDot, Download } from 'lucide-react';
import { AM_REC } from '../lib/amRecordConsent.js';
import { AmModal } from './amModal.jsx';
import { AmButton } from './amButton.jsx';

/** Renders the right consent prompt for the local user based on the shared record state. */
export function AmRecordConsentModal({ state, requesterName, onRespond, onCopyChoice, onCancel }) {
  const open = [AM_REC.REQUESTING, AM_REC.INVITED, AM_REC.COPY_PROMPT, AM_REC.DENIED].includes(state.phase);

  let content = null;
  if (state.phase === AM_REC.REQUESTING) {
    const others = state.participants.filter((id) => id !== state.selfId);
    const yes = others.filter((id) => state.responses[id] === true).length;
    content = {
      title: 'Asking everyone to record',
      description: 'Recording starts only when everyone agrees.',
      body: <p className="text-sm text-slate-300">{yes} of {others.length} have accepted…</p>,
      footer: <AmButton variant="ghost" onClick={onCancel}>Cancel request</AmButton>,
    };
  } else if (state.phase === AM_REC.INVITED) {
    content = {
      title: (requesterName || 'Someone') + ' wants to record',
      description: 'The session is recorded on each device that keeps a copy. Nothing is uploaded to Pairtive.',
      footer: (
        <>
          <AmButton variant="ghost" onClick={() => onRespond(false)}>Decline</AmButton>
          <AmButton variant="success" onClick={() => onRespond(true)}>Allow recording</AmButton>
        </>
      ),
    };
  } else if (state.phase === AM_REC.COPY_PROMPT) {
    content = {
      title: 'Want your own copy?',
      description: 'Recording has started. We can also save a copy to your device when it ends.',
      footer: (
        <>
          <AmButton variant="ghost" onClick={() => onCopyChoice(false)}>No thanks</AmButton>
          <AmButton icon={Download} onClick={() => onCopyChoice(true)}>Save my copy</AmButton>
        </>
      ),
    };
  } else if (state.phase === AM_REC.DENIED) {
    content = {
      title: 'Recording declined',
      description: 'Someone chose not to be recorded, so recording was cancelled.',
      footer: <AmButton onClick={onCancel}>Okay</AmButton>,
    };
  }

  if (!content) return null;
  return (
    <AmModal open={open} onClose={onCancel} dismissible={false} icon={CircleDot} title={content.title} description={content.description} footer={content.footer}>
      {content.body}
    </AmModal>
  );
}
