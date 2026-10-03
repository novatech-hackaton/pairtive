import { CircleDot, MessageCircle, Mic, MicOff, MonitorUp, MonitorX, NotebookPen, PhoneOff, SkipForward, Video, VideoOff } from 'lucide-react';
import { AmButton, AmIconButton } from './amButton.jsx';

/** The bottom control bar for a live session. Screen-share hidden when unsupported. */
export function AmControlsBar({
  micOn, camOn, screenOn, recording, canScreenShare, unread, mode,
  onToggleMic, onToggleCam, onToggleScreen, onToggleChat, onToggleNotes, onRecord, onNext, onStop,
}) {
  return (
    <div className="glass-strong flex items-center justify-center gap-2 rounded-full px-3 py-2.5 shadow-glow sm:gap-3">
      <AmIconButton icon={micOn ? Mic : MicOff} label={micOn ? 'Mute' : 'Unmute'} active={micOn} pressed={!micOn} onClick={onToggleMic} />
      <AmIconButton icon={camOn ? Video : VideoOff} label={camOn ? 'Turn camera off' : 'Turn camera on'} active={camOn} pressed={!camOn} onClick={onToggleCam} />
      {canScreenShare ? (
        <AmIconButton icon={screenOn ? MonitorX : MonitorUp} label={screenOn ? 'Stop sharing' : 'Share screen'} tone={screenOn ? 'brand' : 'default'} onClick={onToggleScreen} />
      ) : null}
      <AmIconButton icon={CircleDot} label={recording ? 'Recording in progress' : 'Record session'} tone={recording ? 'rec' : 'default'} onClick={onRecord} className={recording ? 'animate-rec' : ''} />
      <span className="hidden sm:block sm:h-8 sm:w-px sm:bg-white/10" aria-hidden />
      <AmIconButton icon={MessageCircle} label="Chat" badge={unread > 0 ? (unread > 9 ? '9+' : unread) : undefined} onClick={onToggleChat} />
      <AmIconButton icon={NotebookPen} label="Shared notes" onClick={onToggleNotes} />
      <span className="hidden sm:block sm:h-8 sm:w-px sm:bg-white/10" aria-hidden />
      <AmButton variant="secondary" icon={SkipForward} onClick={onNext} className="hidden sm:inline-flex">
        {mode === 'peers' ? 'Leave' : 'Next'}
      </AmButton>
      <AmIconButton icon={SkipForward} label={mode === 'peers' ? 'Leave group' : 'Next match'} onClick={onNext} className="sm:hidden" />
      <AmIconButton icon={PhoneOff} label="Stop and finish" tone="danger" onClick={onStop} />
    </div>
  );
}
