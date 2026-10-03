import { useCallback, useEffect, useRef, useState } from 'react';
import { amCreateCall } from './amDaily.js';
import { amApi } from './amApi.js';

/**
 * Joins a Daily room and exposes participants as simple tiles for AmVideoGrid,
 * plus local media toggles, screen share and app-message signaling (recording consent).
 */
export function useAmDailyCall({ sessionId, selfName, onAppMessage }) {
  const callRef = useRef(null);
  const [participants, setParticipants] = useState([]);
  const [joined, setJoined] = useState(false);
  const [error, setError] = useState('');
  const [micOn, setMicOn] = useState(true);
  const [camOn, setCamOn] = useState(true);
  const [screenOn, setScreenOn] = useState(false);
  const msgRef = useRef(onAppMessage);
  msgRef.current = onAppMessage;

  const toTiles = useCallback((call) => {
    const raw = call.participants();
    return Object.values(raw).map((p) => ({
      id: p.local ? 'local' : p.session_id,
      sessionId: p.session_id,
      userId: p.user_id || null,
      name: p.user_name || 'Guest',
      isLocal: p.local,
      camOn: p.video,
      micOn: p.audio,
      screenOn: !!p.screenVideoTrack,
      videoTrack: p.videoTrack || null,
      audioTrack: p.audioTrack || null,
      screenTrack: p.screenVideoTrack || null,
    }));
  }, []);

  useEffect(() => {
    let call;
    let cancelled = false;
    (async () => {
      try {
        const { token, url } = await amApi('amSessionToken', { sessionId });
        if (cancelled) return;
        call = amCreateCall();
        callRef.current = call;
        const refresh = () => setParticipants(toTiles(call));
        call
          .on('joined-meeting', () => {
            setJoined(true);
            refresh();
            amApi('amMatch').catch(() => {});
          })
          .on('participant-joined', refresh)
          .on('participant-updated', refresh)
          .on('participant-left', refresh)
          .on('track-started', refresh)
          .on('track-stopped', refresh)
          .on('error', (e) => setError(e?.errorMsg || 'Call error'))
          .on('app-message', (ev) => msgRef.current?.(ev.data, ev.fromId));
        await call.join({ url, token });
        setMicOn(call.localAudio());
        setCamOn(call.localVideo());
      } catch (e) {
        if (!cancelled) setError(e.message || 'Could not join the call');
      }
    })();
    return () => {
      cancelled = true;
      try {
        call?.leave();
        call?.destroy();
      } catch {
        /* ignore */
      }
      callRef.current = null;
    };
  }, [sessionId, toTiles]);

  const toggleMic = useCallback(() => {
    const call = callRef.current;
    const next = !call.localAudio();
    call.setLocalAudio(next);
    setMicOn(next);
  }, []);
  const toggleCam = useCallback(() => {
    const call = callRef.current;
    const next = !call.localVideo();
    call.setLocalVideo(next);
    setCamOn(next);
  }, []);
  const toggleScreen = useCallback(async () => {
    const call = callRef.current;
    try {
      if (screenOn) {
        call.stopScreenShare();
        setScreenOn(false);
      } else {
        await call.startScreenShare();
        setScreenOn(true);
      }
    } catch {
      setScreenOn(false);
    }
  }, [screenOn]);

  const broadcast = useCallback((data) => callRef.current?.sendAppMessage(data, '*'), []);

  return { call: callRef, participants, joined, error, micOn, camOn, screenOn, toggleMic, toggleCam, toggleScreen, broadcast };
}
