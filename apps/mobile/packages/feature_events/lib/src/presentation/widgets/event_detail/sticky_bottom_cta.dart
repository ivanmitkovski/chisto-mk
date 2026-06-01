import 'dart:ui' show ImageFilter;

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/utils/event_detail_cta_presentation.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_detail_layout.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:flutter/material.dart';

class StickyBottomCTA extends StatelessWidget {
  const StickyBottomCTA({
    super.key,
    required this.event,
    required this.onToggleJoin,
    required this.onToggleReminder,
    required this.onStartEvent,
    required this.onManageCheckIn,
    required this.onOpenAttendeeCheckIn,
    required this.onOpenCleanupEvidence,
    required this.onExtendCleanupEnd,
    this.isPrimaryLoading = false,
  });

  final EcoEvent event;
  final VoidCallback onToggleJoin;
  final VoidCallback onToggleReminder;
  final VoidCallback onStartEvent;
  final VoidCallback onManageCheckIn;
  final VoidCallback onOpenAttendeeCheckIn;
  final VoidCallback onOpenCleanupEvidence;
  final VoidCallback onExtendCleanupEnd;

  /// Primary action is awaiting a network mutation (join, reminder, start, …).
  final bool isPrimaryLoading;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panelBackground.withValues(
          alpha: reduceMotion ? 1.0 : kEventDetailStickyCtaPanelAlpha,
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.45),
            width: 0.5,
          ),
        ),
        boxShadow: reduceMotion
            ? null
            : AppShadows.eventStickyCta(
                alpha: kEventDetailStickyCtaShadowAlpha,
              ),
      ),
      child: ProfilePrimaryActionBar(
        padForKeyboard: true,
        child: _CtaContent(
          event: event,
          isPrimaryLoading: isPrimaryLoading,
          onToggleJoin: onToggleJoin,
          onToggleReminder: onToggleReminder,
          onStartEvent: onStartEvent,
          onManageCheckIn: onManageCheckIn,
          onOpenAttendeeCheckIn: onOpenAttendeeCheckIn,
          onOpenCleanupEvidence: onOpenCleanupEvidence,
          onExtendCleanupEnd: onExtendCleanupEnd,
        ),
      ),
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: reduceMotion
          ? panel
          : ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: kEventDetailStickyCtaBlurSigma,
                  sigmaY: kEventDetailStickyCtaBlurSigma,
                ),
                child: panel,
              ),
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Private state machine — one place to read the CTA logic.
// ────────────────────────────────────────────────────────────────────────────

class _CtaContent extends StatelessWidget {
  const _CtaContent({
    required this.event,
    required this.isPrimaryLoading,
    required this.onToggleJoin,
    required this.onToggleReminder,
    required this.onStartEvent,
    required this.onManageCheckIn,
    required this.onOpenAttendeeCheckIn,
    required this.onOpenCleanupEvidence,
    required this.onExtendCleanupEnd,
  });

  final EcoEvent event;
  final bool isPrimaryLoading;
  final VoidCallback onToggleJoin;
  final VoidCallback onToggleReminder;
  final VoidCallback onStartEvent;
  final VoidCallback onManageCheckIn;
  final VoidCallback onOpenAttendeeCheckIn;
  final VoidCallback onOpenCleanupEvidence;
  final VoidCallback onExtendCleanupEnd;

  @override
  Widget build(BuildContext context) {
    final EventDetailCtaPresentation presentation =
        resolveEventDetailCtaPresentation(event: event, l10n: context.l10n);
    final _CtaState state = _callbacksForPresentation(
      presentation: presentation,
    );

    if (state.secondaryLabel != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PrimaryButton(
            label: state.primaryLabel,
            enabled: state.enabled,
            isLoading: isPrimaryLoading,
            onPressed: state.enabled ? state.onPrimaryPressed : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.outlined(
            label: state.secondaryLabel!,
            onPressed: state.onSecondaryPressed,
            enabled: !isPrimaryLoading,
            expand: true,
          ),
        ],
      );
    }

    return PrimaryButton(
      label: state.primaryLabel,
      enabled: state.enabled,
      isLoading: isPrimaryLoading,
      onPressed: state.enabled ? state.onPrimaryPressed : null,
    );
  }

  _CtaState _callbacksForPresentation({
    required EventDetailCtaPresentation presentation,
  }) {
    VoidCallback? onPrimary;
    VoidCallback? onSecondary;

    if (event.isOrganizer) {
      onPrimary = switch (event.status) {
        EcoEventStatus.upcoming when event.moderationApproved => onStartEvent,
        EcoEventStatus.inProgress => onManageCheckIn,
        EcoEventStatus.completed => onOpenCleanupEvidence,
        _ => null,
      };
      if (presentation.secondaryIsExtendCleanupEnd) {
        onSecondary = onExtendCleanupEnd;
      }
    } else if (event.status == EcoEventStatus.inProgress && event.isJoined) {
      if (event.canOpenAttendeeCheckIn && !event.isCheckedIn) {
        onPrimary = onOpenAttendeeCheckIn;
      }
    } else if (event.isJoined) {
      onPrimary = onToggleReminder;
      onSecondary = onToggleJoin;
    } else if (event.moderationApproved && event.isJoinable) {
      onPrimary = onToggleJoin;
    }

    return _CtaState(
      primaryLabel: presentation.primaryLabel,
      enabled: presentation.primaryEnabled,
      onPrimaryPressed: onPrimary,
      secondaryLabel: presentation.secondaryLabel,
      onSecondaryPressed: onSecondary,
    );
  }
}

class _CtaState {
  const _CtaState({
    required this.primaryLabel,
    required this.enabled,
    this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String primaryLabel;
  final bool enabled;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
}
