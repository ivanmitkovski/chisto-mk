import type { EmailTemplateId } from './email.types';
import type { EmailInlineAttachment } from '../util/email-logo';

/** Structured outbound message shared by all email transports. */
export type EmailSendPayload = {
  to: string;
  fromHeader: string;
  subject: string;
  text: string;
  html: string;
  listUnsubscribeUrl?: string;
  templateId: EmailTemplateId;
  inlineAttachments?: EmailInlineAttachment[];
};

export interface EmailTransport {
  send(payload: EmailSendPayload): Promise<boolean>;
}
