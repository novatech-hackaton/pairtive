// Chat attachment rules (enforced in the UI, mirrored by the Storage bucket limits in SQL).

export const AM_ATTACHMENT_MAX_BYTES = 10 * 1024 * 1024; // 10 MB

export const AM_IMAGE_TYPES = ['image/png', 'image/jpeg', 'image/gif', 'image/webp'];
export const AM_FILE_TYPES = [
  'application/pdf',
  'text/plain',
  'application/zip',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
];
export const AM_ALLOWED_TYPES = [...AM_IMAGE_TYPES, ...AM_FILE_TYPES];

export const amIsImageType = (type = '') => AM_IMAGE_TYPES.includes(type);

export function amValidateAttachment(file) {
  if (!file) return 'No file selected.';
  if (!file.size) return 'That file is empty.';
  if (file.size > AM_ATTACHMENT_MAX_BYTES) return 'Files must be 10 MB or smaller.';
  if (!AM_ALLOWED_TYPES.includes(file.type)) return 'That file type is not supported. Try an image, PDF, Office doc, TXT or ZIP.';
  return null;
}

/** Keep storage keys safe: letters, digits, dot, dash, underscore. */
export function amSafeFileName(name = 'file') {
  const cleaned = name
    .normalize('NFKD')
    .replace(/[^\w.-]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^[_.]+/, '')
    .slice(-80);
  return cleaned || 'file';
}

export function amFormatBytes(bytes = 0) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

/** Sorted, comma-joined member ids: the unique key that prevents duplicate threads. */
export function amMemberKey(ids = []) {
  return [...new Set(ids)].sort().join(',');
}
