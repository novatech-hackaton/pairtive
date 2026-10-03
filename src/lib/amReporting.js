// Submit a report, capturing 3 evidence frames of the reported user's current video.
import { amSupabase } from './amSupabase.js';
import { amApi } from './amApi.js';

async function amCaptureFrames(videoTrack, count = 3) {
  if (!videoTrack) return [];
  const video = document.createElement('video');
  video.srcObject = new MediaStream([videoTrack]);
  video.muted = true;
  video.playsInline = true;
  await video.play().catch(() => {});
  await new Promise((r) => setTimeout(r, 150));
  const canvas = document.createElement('canvas');
  const frames = [];
  for (let i = 0; i < count; i++) {
    canvas.width = video.videoWidth || 320;
    canvas.height = video.videoHeight || 240;
    canvas.getContext('2d').drawImage(video, 0, 0, canvas.width, canvas.height);
    const blob = await new Promise((res) => canvas.toBlob(res, 'image/jpeg', 0.8));
    if (blob) frames.push(blob);
    await new Promise((r) => setTimeout(r, 350));
  }
  video.srcObject = null;
  return frames;
}

/**
 * Creates the report row (which blocks both users immediately), uploads evidence frames
 * if a live video track is available, then triggers server-side AI verification.
 */
export async function amSubmitReport({ reportedId, reason, note, sessionId, conversationId, videoTrack }) {
  const { data: reportId, error } = await amSupabase.rpc('am_create_report', {
    p_reported: reportedId,
    p_reason: reason,
    p_note: note || null,
    p_session: sessionId ?? null,
    p_conversation: conversationId ?? null,
  });
  if (error) throw new Error(error.message);

  if (reason === 'inappropriate' || reason === 'no_show') {
    try {
      const frames = await amCaptureFrames(videoTrack);
      for (let i = 0; i < frames.length; i++) {
        await amSupabase.storage.from('report-evidence').upload(reportId + '/' + i + '.jpg', frames[i], { contentType: 'image/jpeg' });
      }
    } catch {
      /* evidence is best-effort */
    }
  }
  // Fire-and-forget verification; the server enforces strikes/suspensions.
  amApi('amReportVerify', { reportId }).catch(() => {});
  return reportId;
}
