// Client-side session recorder: composite all video tiles on a canvas and mix all
// audio tracks with WebAudio, then capture to a single MediaRecorder file.
import { amPickMimeType } from './amRecordConsent.js';
import { amIsIOS } from './amMedia.js';

export class AmRecorder {
  constructor() {
    this.canvas = null;
    this.ctx = null;
    this.audioCtx = null;
    this.recorder = null;
    this.chunks = [];
    this.raf = null;
    this.sources = []; // { id, video }
    this.mime = amPickMimeType();
    this.width = 1280;
    this.height = 720;
  }

  start(tiles) {
    this.canvas = document.createElement('canvas');
    this.canvas.width = this.width;
    this.canvas.height = this.height;
    this.ctx = this.canvas.getContext('2d');
    this.sources = tiles.map((t) => {
      const video = document.createElement('video');
      video.srcObject = new MediaStream([t.videoTrack].filter(Boolean));
      video.muted = true;
      video.playsInline = true;
      video.play().catch(() => {});
      return { id: t.id, name: t.name, video };
    });

    this.audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const dest = this.audioCtx.createMediaStreamDestination();
    for (const t of tiles) {
      if (t.audioTrack) {
        try {
          this.audioCtx.createMediaStreamSource(new MediaStream([t.audioTrack])).connect(dest);
        } catch { /* track not usable */ }
      }
    }

    this.draw();
    const canvasStream = this.canvas.captureStream(25);
    const mixed = new MediaStream([...canvasStream.getVideoTracks(), ...dest.stream.getAudioTracks()]);
    this.recorder = new MediaRecorder(mixed, this.mime ? { mimeType: this.mime } : undefined);
    this.chunks = [];
    this.recorder.ondataavailable = (e) => e.data.size && this.chunks.push(e.data);
    this.recorder.start(1000);
    this.startedAt = Date.now();
  }

  draw = () => {
    const { ctx, width, height, sources } = this;
    ctx.fillStyle = '#0b0b22';
    ctx.fillRect(0, 0, width, height);
    const n = sources.length || 1;
    const cols = Math.ceil(Math.sqrt(n));
    const rows = Math.ceil(n / cols);
    const cw = width / cols;
    const ch = height / rows;
    sources.forEach((s, i) => {
      const x = (i % cols) * cw;
      const y = Math.floor(i / cols) * ch;
      const v = s.video;
      if (v.videoWidth) {
        const scale = Math.max(cw / v.videoWidth, ch / v.videoHeight);
        const dw = v.videoWidth * scale;
        const dh = v.videoHeight * scale;
        ctx.save();
        ctx.beginPath();
        ctx.rect(x + 4, y + 4, cw - 8, ch - 8);
        ctx.clip();
        ctx.drawImage(v, x + (cw - dw) / 2, y + (ch - dh) / 2, dw, dh);
        ctx.restore();
      }
      ctx.fillStyle = 'rgba(0,0,0,0.5)';
      ctx.fillRect(x + 10, y + ch - 34, ctx.measureText(s.name || 'Guest').width + 20, 24);
      ctx.fillStyle = '#fff';
      ctx.font = '16px Inter, sans-serif';
      ctx.fillText(s.name || 'Guest', x + 20, y + ch - 17);
    });
    this.raf = requestAnimationFrame(this.draw);
  };

  async stop() {
    if (!this.recorder) return null;
    const done = new Promise((resolve) => {
      this.recorder.onstop = () => resolve(new Blob(this.chunks, { type: this.mime || 'video/webm' }));
    });
    this.recorder.stop();
    const blob = await done;
    cancelAnimationFrame(this.raf);
    this.sources.forEach((s) => (s.video.srcObject = null));
    this.audioCtx?.close();
    return blob;
  }

  get elapsedMs() {
    return this.startedAt ? Date.now() - this.startedAt : 0;
  }
}

export async function amSaveRecording(blob, mime) {
  const ext = (mime || blob.type).includes('mp4') ? 'mp4' : 'webm';
  const file = new File([blob], 'pairtive-session-' + new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-') + '.' + ext, { type: blob.type });
  if (amIsIOS() && navigator.canShare?.({ files: [file] })) {
    try {
      await navigator.share({ files: [file], title: 'Pairtive session recording' });
      return 'shared';
    } catch { /* fall through to download */ }
  }
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = file.name;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 10000);
  return 'downloaded';
}
