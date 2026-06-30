type MessageRecord = Record<string, unknown>;

let stagedMessages: MessageRecord | null = null;

export function stageRouteMessages(messages: MessageRecord): void {
  stagedMessages = messages;
}

export function consumeStagedRouteMessages(): MessageRecord | null {
  const staged = stagedMessages;
  stagedMessages = null;
  return staged;
}
