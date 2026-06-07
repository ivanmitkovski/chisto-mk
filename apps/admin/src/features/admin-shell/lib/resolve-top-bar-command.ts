import type { TopBarCommand, TopBarCommandDefinition } from '../types/top-bar';

type CommandTranslator = (key: string) => string;

export function resolveTopBarCommand(
  command: TopBarCommandDefinition,
  tNav: CommandTranslator,
  tCommon: CommandTranslator,
): TopBarCommand {
  const t = command.messageNamespace === 'common' ? tCommon : tNav;

  return {
    ...command,
    label: t(command.labelKey),
    ...(command.descriptionKey ? { description: t(command.descriptionKey) } : {}),
  };
}
