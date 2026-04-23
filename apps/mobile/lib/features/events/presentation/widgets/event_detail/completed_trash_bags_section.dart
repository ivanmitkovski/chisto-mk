import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Organizer-only: record how many trash bags were collected after completion.
class CompletedTrashBagsSection extends StatefulWidget {
  const CompletedTrashBagsSection({
    super.key,
    required this.initialBags,
    required this.onSave,
  });

  final int initialBags;
  final Future<void> Function(int bagsCollected) onSave;

  static const int _maxBags = 9999;

  @override
  State<CompletedTrashBagsSection> createState() =>
      _CompletedTrashBagsSectionState();
}

class _CompletedTrashBagsSectionState extends State<CompletedTrashBagsSection> {
  late int _bags;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bags = widget.initialBags.clamp(0, CompletedTrashBagsSection._maxBags);
  }

  @override
  void didUpdateWidget(covariant CompletedTrashBagsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBags != widget.initialBags && !_saving) {
      _bags = widget.initialBags.clamp(0, CompletedTrashBagsSection._maxBags);
    }
  }

  Future<void> _commit() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(_bags);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: context.l10n.eventsCompletedBagsSectionTitle,
      child: DecoratedBox(
        decoration: EventDetailSurfaceDecoration.detailModule(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context.l10n.eventsCompletedBagsSectionTitle,
                style: AppTypography.eventsPanelTitle(textTheme),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    onPressed: _saving || _bags <= 0
                        ? null
                        : () {
                            AppHaptics.tap();
                            setState(() => _bags -= 1);
                          },
                    icon: const Icon(CupertinoIcons.minus_circle_fill),
                    color: AppColors.textSecondary,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      '$_bags',
                      style: AppTypography.eventsDisplayStat(textTheme),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _saving || _bags >= CompletedTrashBagsSection._maxBags
                        ? null
                        : () {
                            AppHaptics.tap();
                            setState(() => _bags += 1);
                          },
                    icon: const Icon(CupertinoIcons.plus_circle_fill),
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: context.l10n.eventsCompletedBagsSave,
                enabled: !_saving,
                isLoading: _saving,
                onPressed: () => unawaited(_commit()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
