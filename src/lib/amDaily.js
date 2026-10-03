import DailyIframe from '@daily-co/daily-js';
import { amPeekLocalStream } from './amMedia.js';

/**
 * Thin wrapper over a Daily call object (not Daily Prebuilt - we render our own UI).
 * Reuses the camera/mic stream already opened on the match page so it never restarts.
 */
export function amCreateCall() {
  const existing = DailyIframe.getCallInstance?.();
  if (existing) return existing;
  const stream = amPeekLocalStream();
  const videoTrack = stream?.getVideoTracks?.()[0];
  const audioTrack = stream?.getAudioTracks?.()[0];
  return DailyIframe.createCallObject({
    subscribeToTracksAutomatically: true,
    dailyConfig: {},
    ...(videoTrack ? { videoSource: videoTrack } : {}),
    ...(audioTrack ? { audioSource: audioTrack } : {}),
  });
}

export const amDailyScreenSupported = () => DailyIframe.supportedBrowser?.()?.supportsScreenShare ?? false;
