// Pure reducer for the recording-consent handshake, driven by Daily app-messages.
// Flow: a requester asks -> every OTHER participant accepts or declines ->
// if all accept, each non-requester is asked whether they also want a personal copy ->
// recording runs until anyone stops it.

export const AM_REC = Object.freeze({
  IDLE: 'idle',
  REQUESTING: 'requesting', // I asked; waiting for others
  INVITED: 'invited', // someone asked me to consent
  COPY_PROMPT: 'copy_prompt', // consent granted; asked if I want my own copy
  RECORDING: 'recording',
  DENIED: 'denied',
});

export function amRecordInitial(selfId) {
  return { phase: AM_REC.IDLE, selfId, requesterId: null, participants: [], responses: {}, wantsCopy: {}, startedAt: null };
}

function allResponded(state) {
  const others = state.participants.filter((id) => id !== state.requesterId);
  return others.length > 0 && others.every((id) => state.responses[id] != null);
}
function allAccepted(state) {
  const others = state.participants.filter((id) => id !== state.requesterId);
  return others.length > 0 && others.every((id) => state.responses[id] === true);
}

export function amRecordReducer(state, action) {
  switch (action.type) {
    case 'participants':
      return { ...state, participants: action.ids };
    case 'request': // { by, participants }
      if (state.phase === AM_REC.RECORDING) return state;
      return {
        ...state,
        phase: action.by === state.selfId ? AM_REC.REQUESTING : AM_REC.INVITED,
        requesterId: action.by,
        participants: action.participants ?? state.participants,
        responses: {},
        wantsCopy: {},
      };
    case 'respond': { // { from, accept }
      const responses = { ...state.responses, [action.from]: action.accept };
      const next = { ...state, responses };
      if (action.accept === false) {
        return { ...next, phase: next.selfId === next.requesterId ? AM_REC.DENIED : AM_REC.IDLE };
      }
      if (allResponded(next)) {
        if (allAccepted(next)) {
          const isRequester = next.selfId === next.requesterId;
          return { ...next, phase: isRequester ? AM_REC.RECORDING : AM_REC.COPY_PROMPT, startedAt: Date.now() };
        }
        return { ...next, phase: next.selfId === next.requesterId ? AM_REC.DENIED : AM_REC.IDLE };
      }
      return next;
    }
    case 'copyChoice': // { from, wants }
      return { ...state, wantsCopy: { ...state.wantsCopy, [action.from]: action.wants }, phase: state.phase === AM_REC.COPY_PROMPT && action.from === state.selfId ? AM_REC.RECORDING : state.phase };
    case 'started':
      return { ...state, phase: AM_REC.RECORDING, startedAt: state.startedAt ?? Date.now() };
    case 'stopped':
      return { ...state, phase: AM_REC.IDLE, requesterId: null, responses: {}, startedAt: null };
    case 'reset':
      return amRecordInitial(state.selfId);
    default:
      return state;
  }
}

export function amPickMimeType() {
  if (typeof MediaRecorder === 'undefined') return '';
  const candidates = ['video/mp4;codecs=h264,aac', 'video/mp4', 'video/webm;codecs=vp9,opus', 'video/webm;codecs=vp8,opus', 'video/webm'];
  return candidates.find((t) => MediaRecorder.isTypeSupported?.(t)) ?? '';
}
