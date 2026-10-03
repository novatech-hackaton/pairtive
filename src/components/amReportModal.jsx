import { useState } from 'react';
import { Flag } from 'lucide-react';
import { AM_REPORT_REASONS } from '../../shared/amModeration.js';
import { AmModal } from './amModal.jsx';
import { AmButton } from './amButton.jsx';

export function AmReportModal({ open, onClose, reportedName, onSubmit }) {
  const [reason, setReason] = useState(null);
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit() {
    if (!reason) return;
    setBusy(true);
    try {
      await onSubmit({ reason, note });
      setReason(null);
      setNote('');
    } finally {
      setBusy(false);
    }
  }

  return (
    <AmModal
      open={open}
      onClose={onClose}
      icon={Flag}
      title={'Report ' + (reportedName || 'this user')}
      description="You'll both be blocked from matching right away. Our AI reviews every report."
      footer={
        <>
          <AmButton variant="ghost" onClick={onClose}>Cancel</AmButton>
          <AmButton variant="danger" loading={busy} disabled={!reason} onClick={submit}>Submit report</AmButton>
        </>
      }
    >
      <fieldset>
        <legend className="mb-2 text-sm font-medium text-slate-200">What happened?</legend>
        <div className="space-y-2">
          {AM_REPORT_REASONS.map((r) => (
            <label key={r.id} className={'flex cursor-pointer items-start gap-3 rounded-xl p-3 ring-1 transition ' + (reason === r.id ? 'bg-white/10 ring-brand-violet' : 'bg-white/[0.03] ring-white/10 hover:bg-white/[0.06]')}>
              <input type="radio" name="am-report-reason" value={r.id} checked={reason === r.id} onChange={() => setReason(r.id)} className="mt-1 size-4 accent-rose-400" />
              <span>
                <span className="block text-sm font-medium text-white">{r.label}</span>
                <span className="block text-xs text-slate-400">{r.hint}</span>
              </span>
            </label>
          ))}
        </div>
      </fieldset>
      <label className="mt-4 block">
        <span className="mb-1.5 block text-sm font-medium text-slate-200">Add a note (optional)</span>
        <textarea
          value={note}
          onChange={(e) => setNote(e.target.value.slice(0, 500))}
          rows={3}
          className="w-full rounded-2xl bg-white/[0.04] p-3 text-sm text-white ring-1 ring-white/10 focus:ring-2 focus:ring-brand-violet focus:outline-none"
          placeholder="Anything that helps us understand…"
        />
      </label>
    </AmModal>
  );
}
