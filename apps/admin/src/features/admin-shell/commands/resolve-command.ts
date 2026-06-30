import type { CommandDefinition, ResolvedCommand } from './types';

type CommandTranslator = (key: string) => string;

function tokenizeLabel(label: string): string[] {
  return label
    .toLowerCase()
    .split(/[\s/._-]+/)
    .filter((token) => token.length > 1);
}

export function resolveCommand(
  command: CommandDefinition,
  tNav: CommandTranslator,
  tCommon: CommandTranslator,
  tPalette: CommandTranslator,
): ResolvedCommand {
  const isEntity = command.id.startsWith('entity-');
  const t =
    command.messageNamespace === 'common'
      ? tCommon
      : command.messageNamespace === 'commandPalette'
        ? tPalette
        : tNav;

  const label = isEntity ? command.labelKey : t(command.labelKey);
  const description =
    command.descriptionKey != null
      ? isEntity
        ? command.descriptionKey
        : t(command.descriptionKey)
      : undefined;

  const searchKeywords = [
    ...(command.keywords ?? []),
    ...tokenizeLabel(label),
    ...(description ? tokenizeLabel(description) : []),
    ...(command.href ? tokenizeLabel(command.href) : []),
  ];

  return {
    ...command,
    label,
    ...(description ? { description } : {}),
    searchKeywords: [...new Set(searchKeywords)],
  };
}

export function resolveCommands(
  commands: readonly CommandDefinition[],
  tNav: CommandTranslator,
  tCommon: CommandTranslator,
  tPalette: CommandTranslator,
): ResolvedCommand[] {
  return commands.map((command) => resolveCommand(command, tNav, tCommon, tPalette));
}
