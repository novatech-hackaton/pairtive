import { NotebookPen, Users } from 'lucide-react';

/** Live shared notes. Controlled text area; edits propagate through amNotesSync. */
export function AmNotesPanel({ value, onChange, editorCount = 1, readOnly = false }) {
  return (
    <div className="flex h-full flex-col">
      <div className="flex items-center justify-between gap-2 border-b border-white/8 px-4 py-2.5 text-xs text-slate-400">
        <span className="inline-flex items-center gap-1.5">
          <NotebookPen className="size-4 text-brand-cyan" aria-hidden /> Everyone can edit these notes live
        </span>
        {editorCount > 1 ? (
          <span className="inline-flex items-center gap-1">
            <Users className="size-3.5" aria-hidden /> {editorCount}
          </span>
        ) : null}
      </div>
      <textarea
        value={value}
        onChange={(e) => onChange(e.target.value)}
        readOnly={readOnly}
        placeholder={readOnly ? 'No notes were taken.' : 'Start typing shared notes. Everyone sees changes instantly…'}
        aria-label="Shared session notes"
        className="min-h-0 flex-1 resize-none bg-transparent p-4 text-sm leading-relaxed text-slate-100 placeholder:text-slate-500 focus:outline-none"
      />
    </div>
  );
}
