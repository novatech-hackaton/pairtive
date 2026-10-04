import { useEffect, useRef, useState } from 'react';
import { CameraOff, Mic, MicOff, RefreshCw, Video, VideoOff } from 'lucide-react';
import { amGetLocalStream, amMediaErrorMessage, amMediaSupported, amSetTrackEnabled } from '../lib/amMedia.js';
import { AmIconButton } from './amButton.jsx';

/**
 * Auto-opens the camera and keeps the same stream alive for the session page.
 * Full-width responsive card; `aspect` sets the Tailwind aspect-ratio classes (default 16:9).
 */
export function AmCameraPreview({ name, aspect = 'aspect-video', className = '' }) {
  const videoRef = useRef(null);
  const [stream, setStream] = useState(null);
  const [error, setError] = useState('');
  const [camOn, setCamOn] = useState(true);
  const [micOn, setMicOn] = useState(true);
  const [level, setLevel] = useState(0);

  async function start() {
    setError('');
    if (!amMediaSupported()) {
      setError('This browser does not support video calls. Try Chrome, Edge, Firefox or Safari.');
      return;
    }
    try {
      const s = await amGetLocalStream();
      setStream(s);
      setCamOn(s.getVideoTracks().some((t) => t.enabled));
      setMicOn(s.getAudioTracks().some((t) => t.enabled));
    } catch (err) {
      setError(amMediaErrorMessage(err));
    }
  }

  useEffect(() => {
    start();
  }, []);

  useEffect(() => {
    if (videoRef.current && stream) videoRef.current.srcObject = stream;
  }, [stream]);

  // Tiny mic level meter so users know they're audible.
  useEffect(() => {
    if (!stream || !stream.getAudioTracks().length || typeof AudioContext === 'undefined') return undefined;
    const ctx = new AudioContext();
    const src = ctx.createMediaStreamSource(stream);
    const analyser = ctx.createAnalyser();
    analyser.fftSize = 256;
    src.connect(analyser);
    const data = new Uint8Array(analyser.frequencyBinCount);
    let raf;
    const tick = () => {
      analyser.getByteFrequencyData(data);
      const avg = data.reduce((a, b) => a + b, 0) / data.length;
      setLevel(Math.min(1, avg / 60));
      raf = requestAnimationFrame(tick);
    };
    tick();
    return () => {
      cancelAnimationFrame(raf);
      ctx.close();
    };
  }, [stream]);

  const toggleCam = () => {
    amSetTrackEnabled('video', !camOn);
    setCamOn(!camOn);
  };
  const toggleMic = () => {
    amSetTrackEnabled('audio', !micOn);
    setMicOn(!micOn);
  };

  return (
    <div
      className={`relative w-full overflow-hidden rounded-3xl bg-ink-800 shadow-[0_20px_60px_-30px_rgb(0_0_0/0.8)] ring-1 ring-white/10 ${aspect} ${className}`}
      aria-label="Your camera preview"
      role="region"
    >
      <video ref={videoRef} autoPlay playsInline muted className={`am-mirror absolute inset-0 size-full object-cover ${stream && camOn ? '' : 'invisible'}`} />
      {stream && camOn ? null : (
        <div className="absolute inset-0 grid place-items-center">
          <div className="flex flex-col items-center gap-2 px-4 text-center sm:gap-3 sm:px-6">
            <CameraOff className="size-7 text-slate-500 sm:size-8" aria-hidden />
            <p className="max-w-xs text-sm text-slate-400" role={error ? 'alert' : undefined}>
              {error || (stream ? 'Your camera is off' : 'Starting camera…')}
            </p>
            {error ? (
              <button type="button" onClick={start} className="inline-flex min-h-11 items-center gap-1.5 rounded-xl px-3 text-sm font-medium text-brand-cyan hover:underline">
                <RefreshCw className="size-4" aria-hidden /> Try again
              </button>
            ) : null}
          </div>
        </div>
      )}

      <div className="absolute inset-x-0 top-0 flex items-center justify-between gap-3 bg-linear-to-b from-ink-950/70 to-transparent p-3">
        <span className="inline-flex min-w-0 items-center gap-2 rounded-full bg-ink-950/60 px-3 py-1 text-xs font-medium text-white backdrop-blur">
          <span className={`size-2 shrink-0 rounded-full ${stream && camOn ? 'bg-emerald-400' : 'bg-slate-500'}`} aria-hidden />
          <span className="truncate">{name ? `${name} (you)` : 'You'}</span>
        </span>
        {micOn && stream ? (
          <span className="flex h-4 items-end gap-0.5" aria-hidden>
            {[0.3, 0.6, 1].map((t) => (
              <span key={t} className={`w-1 rounded-full transition-all ${level >= t * 0.6 ? 'bg-emerald-400' : 'bg-white/25'}`} style={{ height: `${t * 100}%` }} />
            ))}
          </span>
        ) : null}
      </div>

      {stream ? (
        <div className="absolute inset-x-0 bottom-0 flex justify-center gap-4 bg-linear-to-t from-ink-950/70 to-transparent p-3">
          {/* size="md" = 48px touch targets */}
          <AmIconButton icon={micOn ? Mic : MicOff} label={micOn ? 'Mute microphone' : 'Unmute microphone'} active={micOn} pressed={!micOn} onClick={toggleMic} size="md" />
          <AmIconButton icon={camOn ? Video : VideoOff} label={camOn ? 'Turn camera off' : 'Turn camera on'} active={camOn} pressed={!camOn} onClick={toggleCam} size="md" />
        </div>
      ) : null}
    </div>
  );
}
