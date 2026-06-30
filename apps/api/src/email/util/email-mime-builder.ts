import { randomBytes } from 'crypto';

function rfc2047Subject(subject: string): string {
  if (/^[\x20-\x7E]*$/.test(subject)) {
    return subject;
  }
  return `=?UTF-8?B?${Buffer.from(subject, 'utf8').toString('base64')}?=`;
}

export type BuildRawMimeInput = {
  fromHeader: string;
  to: string;
  subject: string;
  textBody: string;
  htmlBody: string;
  listUnsubscribeUrl?: string;
};

/** multipart/alternative with base64 bodies (UTF-8 safe, avoids QP line-length rules). */
export function buildMultipartAlternativeMime(input: BuildRawMimeInput): Uint8Array {
  const boundary = `=_chisto_${randomBytes(12).toString('hex')}`;
  const subj = rfc2047Subject(input.subject);
  const textB64 = Buffer.from(input.textBody, 'utf8').toString('base64');
  const htmlB64 = Buffer.from(input.htmlBody, 'utf8').toString('base64');
  const lines: string[] = [];
  lines.push(`From: ${input.fromHeader}`);
  lines.push(`To: ${input.to}`);
  lines.push(`Subject: ${subj}`);
  lines.push('MIME-Version: 1.0');
  if (input.listUnsubscribeUrl) {
    lines.push(`List-Unsubscribe: <${input.listUnsubscribeUrl}>`);
    lines.push('List-Unsubscribe-Post: List-Unsubscribe=One-Click');
  }
  lines.push(`Content-Type: multipart/alternative; boundary="${boundary}"`);
  lines.push('');
  lines.push(`--${boundary}`);
  lines.push('Content-Type: text/plain; charset=UTF-8');
  lines.push('Content-Transfer-Encoding: base64');
  lines.push('');
  lines.push(textB64);
  lines.push('');
  lines.push(`--${boundary}`);
  lines.push('Content-Type: text/html; charset=UTF-8');
  lines.push('Content-Transfer-Encoding: base64');
  lines.push('');
  lines.push(htmlB64);
  lines.push('');
  lines.push(`--${boundary}--`);
  return Buffer.from(lines.join('\r\n'), 'utf8');
}
