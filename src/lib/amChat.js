import { useCallback, useEffect, useRef, useState } from 'react';
import { amSupabase } from './amSupabase.js';
import { amValidateAttachment, amSafeFileName } from '../../shared/amAttachments.js';
import { useAmPostgresChanges } from './amRealtime.js';

/**
 * Chat for a conversation. The thread is created lazily on first send:
 * pass memberIds when there is no conversationId yet.
 */
export function useAmChat({ conversationId: initialId, memberIds, sessionId }) {
  const [conversationId, setConversationId] = useState(initialId ?? null);
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(!!initialId);
  const idRef = useRef(conversationId);
  idRef.current = conversationId;

  const load = useCallback(async (id) => {
    if (!id) return;
    const { data } = await amSupabase
      .from('messages')
      .select('*')
      .eq('conversation_id', id)
      .order('created_at', { ascending: true })
      .limit(500);
    setMessages(data ?? []);
    setLoading(false);
    amSupabase.from('conversation_members').update({ last_read_at: new Date().toISOString() }).eq('conversation_id', id).then(() => {});
  }, []);

  useEffect(() => {
    if (initialId) {
      setConversationId(initialId);
      load(initialId);
    }
  }, [initialId, load]);

  useAmPostgresChanges(
    'chat',
    [{ event: 'INSERT', table: 'messages', filter: conversationId ? 'conversation_id=eq.' + conversationId : undefined }],
    ({ new: msg }) => {
      setMessages((prev) => (prev.some((m) => m.id === msg.id) ? prev : [...prev, msg]));
      if (document.visibilityState === 'visible' && conversationId) {
        amSupabase.from('conversation_members').update({ last_read_at: new Date().toISOString() }).eq('conversation_id', conversationId).then(() => {});
      }
    },
    !!conversationId,
  );

  const ensureConversation = useCallback(async () => {
    if (idRef.current) return idRef.current;
    const { data, error } = await amSupabase.rpc('am_get_or_create_conversation', { p_member_ids: memberIds });
    if (error) throw new Error(error.message);
    setConversationId(data);
    idRef.current = data;
    load(data);
    return data;
  }, [memberIds, load]);

  const uploadAttachment = useCallback(async (convId, file) => {
    const path = convId + '/' + Date.now() + '-' + amSafeFileName(file.name);
    const { error } = await amSupabase.storage.from('chat-attachments').upload(path, file, { contentType: file.type });
    if (error) throw new Error(error.message);
    return path;
  }, []);

  const send = useCallback(
    async ({ body, file }) => {
      const text = (body ?? '').trim();
      if (!text && !file) return;
      if (file) {
        const err = amValidateAttachment(file);
        if (err) throw new Error(err);
      }
      const convId = await ensureConversation();
      let attachment = {};
      if (file) {
        const path = await uploadAttachment(convId, file);
        attachment = { attachment_path: path, attachment_name: file.name.slice(0, 120), attachment_type: file.type, attachment_size: file.size };
      }
      const { error } = await amSupabase.from('messages').insert({
        conversation_id: convId,
        sender_id: (await amSupabase.auth.getUser()).data.user.id,
        session_id: sessionId ?? null,
        body: text || null,
        ...attachment,
      });
      if (error) throw new Error(error.message);
    },
    [ensureConversation, uploadAttachment, sessionId],
  );

  return { conversationId, messages, loading, send };
}

export function amAttachmentUrl(path) {
  return amSupabase.storage.from('chat-attachments').createSignedUrl(path, 3600).then(({ data }) => data?.signedUrl ?? null);
}
