// One camera/mic stream shared by the match page (preview) and the session (Daily call),
// so the camera is never restarted between "searching", "joining" and "in call".

let current = null;
let pending = null;

export const amMediaSupported = () => typeof navigator !== 'undefined' && !!navigator.mediaDevices?.getUserMedia;

export function amCanScreenShare() {
  if (typeof navigator === 'undefined' || !navigator.mediaDevices?.getDisplayMedia) return false;
  // Mobile browsers expose the API on some versions but it always fails there.
  const ua = navigator.userAgent || '';
  const mobile = /Android|iPhone|iPad|iPod|Mobile/i.test(ua) || (navigator.maxTouchPoints > 1 && /Macintosh/.test(ua));
  return !mobile;
}

export const amIsIOS = () =>
  typeof navigator !== 'undefined' &&
  (/iPhone|iPad|iPod/i.test(navigator.userAgent) || (navigator.maxTouchPoints > 1 && /Macintosh/.test(navigator.userAgent)));

export const amIsMobile = () => typeof navigator !== 'undefined' && /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent);

function amAlive(stream) {
  return stream && stream.getTracks().some((t) => t.readyState === 'live');
}

export async function amGetLocalStream() {
  if (amAlive(current)) return current;
  if (pending) return pending;
  pending = navigator.mediaDevices
    .getUserMedia({
      video: { width: { ideal: 1280 }, height: { ideal: 720 }, facingMode: 'user' },
      audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true },
    })
    .then((s) => {
      current = s;
      return s;
    })
    .finally(() => {
      pending = null;
    });
  return pending;
}

export const amPeekLocalStream = () => (amAlive(current) ? current : null);

export function amSetTrackEnabled(kind, enabled) {
  current?.getTracks().forEach((t) => {
    if (t.kind === kind) t.enabled = enabled;
  });
}

export function amStopLocalStream() {
  current?.getTracks().forEach((t) => t.stop());
  current = null;
}

export function amMediaErrorMessage(err) {
  const name = err?.name || '';
  if (name === 'NotAllowedError' || name === 'SecurityError') return 'Camera or mic permission was blocked. Allow access in your browser settings, then try again.';
  if (name === 'NotFoundError' || name === 'OverconstrainedError') return 'No camera or microphone was found on this device.';
  if (name === 'NotReadableError') return 'Your camera is being used by another app. Close it and try again.';
  return 'Could not start your camera. Please try again.';
}
