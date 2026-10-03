import { describe, expect, it } from 'vitest';
import { AM_ATTACHMENT_MAX_BYTES, amMemberKey, amSafeFileName, amValidateAttachment } from './amAttachments.js';

describe('attachments', () => {
  it('accepts images and documents under the limit', () => {
    expect(amValidateAttachment({ name: 'a.png', size: 1000, type: 'image/png' })).toBeNull();
    expect(amValidateAttachment({ name: 'a.pdf', size: 1000, type: 'application/pdf' })).toBeNull();
  });
  it('rejects large, empty and unsupported files', () => {
    expect(amValidateAttachment({ name: 'big.png', size: AM_ATTACHMENT_MAX_BYTES + 1, type: 'image/png' })).toMatch(/10 MB/);
    expect(amValidateAttachment({ name: 'e.txt', size: 0, type: 'text/plain' })).toMatch(/empty/);
    expect(amValidateAttachment({ name: 'x.exe', size: 10, type: 'application/x-msdownload' })).toMatch(/not supported/);
  });
  it('sanitizes file names', () => {
    expect(amSafeFileName('../../my notes (1).pdf')).toBe('my_notes_1_.pdf');
  });
  it('builds an order-independent member key so threads never duplicate', () => {
    expect(amMemberKey(['b', 'a', 'c'])).toBe(amMemberKey(['c', 'b', 'a']));
    expect(amMemberKey(['a', 'a', 'b'])).toBe('a,b');
  });
});
