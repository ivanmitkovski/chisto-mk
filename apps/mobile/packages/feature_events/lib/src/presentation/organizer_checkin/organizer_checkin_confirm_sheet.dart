part of 'package:feature_events/src/presentation/organizer_checkin/organizer_checkin_screen.dart';

class _CheckInConfirmSheet extends StatelessWidget {
  const _CheckInConfirmSheet({
    required this.fullName,
    required this.avatarSeed,
    this.avatarUrl,
    required this.isResolving,
    required this.onConfirm,
    required this.onReject,
  });

  final String fullName;
  final String avatarSeed;
  final String? avatarUrl;
  final bool isResolving;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: AppRadii.chatMicro,
            ),
          ),
          const SizedBox(height: 20),
          UserAvatarCircle(
            displayName: fullName,
            imageUrl: avatarUrl,
            size: 80,
            seed: avatarSeed,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.eventsOrganizerConfirmTitle,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            fullName,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.eventsOrganizerConfirmSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton.outlined(
                  label: l10n.eventsOrganizerConfirmReject,
                  onPressed: onReject,
                  enabled: !isResolving,
                  expand: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton.primary(
                  label: l10n.eventsOrganizerConfirmApprove,
                  onPressed: onConfirm,
                  enabled: !isResolving,
                  isLoading: isResolving,
                  expand: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
