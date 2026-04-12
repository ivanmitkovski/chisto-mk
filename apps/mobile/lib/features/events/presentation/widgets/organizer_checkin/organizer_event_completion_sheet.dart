import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Result of the organizer completion sheet — drives post-pop navigation.
enum OrganizerEventCompletionAction {
  /// User chose "Back to event" (or dismissed).
  dismissed,

  /// User chose to open cleanup evidence after the check-in screen is popped.
  openEvidence,
}

/// Premium completion sheet after ending an event: metrics, next steps, CTAs.
///
/// Interactive pop / discard is handled by the check-in screen; this sheet only
/// collects the organizer's choice before that screen pops.
Future<OrganizerEventCompletionAction> showOrganizerEventCompletionSheet({
  required BuildContext context,
  required int checkedInCount,
  required int participantCount,
  int? maxParticipants,
}) async {
  final OrganizerEventCompletionAction? action =
      await showModalBottomSheet<OrganizerEventCompletionAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    builder: (BuildContext sheetCtx) {
      return _OrganizerEventCompletionSheetBody(
        checkedInCount: checkedInCount,
        participantCount: participantCount,
        maxParticipants: maxParticipants,
      );
    },
  );
  return action ?? OrganizerEventCompletionAction.dismissed;
}

class _OrganizerEventCompletionSheetBody extends StatefulWidget {
  const _OrganizerEventCompletionSheetBody({
    required this.checkedInCount,
    required this.participantCount,
    this.maxParticipants,
  });

  final int checkedInCount;
  final int participantCount;
  final int? maxParticipants;

  @override
  State<_OrganizerEventCompletionSheetBody> createState() =>
      _OrganizerEventCompletionSheetBodyState();
}

class _OrganizerEventCompletionSheetBodyState
    extends State<_OrganizerEventCompletionSheetBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _markController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _startedMarkAnimation = false;

  @override
  void initState() {
    super.initState();
    _markController = AnimationController(
      vsync: this,
      duration: AppMotion.emphasizedDuration,
    );
    _scale = CurvedAnimation(
      parent: _markController,
      curve: AppMotion.spring,
    );
    _opacity = CurvedAnimation(
      parent: _markController,
      curve: AppMotion.smooth,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedMarkAnimation) {
      return;
    }
    _startedMarkAnimation = true;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    _markController.duration =
        reduceMotion ? Duration.zero : AppMotion.emphasizedDuration;
    if (reduceMotion) {
      _markController.value = 1;
    } else {
      unawaited(_markController.forward());
    }
  }

  @override
  void dispose() {
    _markController.dispose();
    super.dispose();
  }

  String _checkInSummary(AppLocalizations l10n) {
    final int n = widget.checkedInCount;
    if (n == 0) {
      return l10n.eventsOrganizerCompletionCheckedInNone;
    }
    if (n == 1) {
      return l10n.eventsOrganizerEndSummaryOneAttendee;
    }
    return l10n.eventsOrganizerEndSummaryManyAttendees(n);
  }

  String? _joinedLine(AppLocalizations l10n) {
    if (widget.maxParticipants != null) {
      return l10n.eventsOrganizerCompletionJoinedOfCap(
        widget.participantCount,
        widget.maxParticipants!,
      );
    }
    if (widget.participantCount > 0) {
      return l10n.eventsOrganizerCompletionJoinedLine(widget.participantCount);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String summary = _checkInSummary(l10n);
    final String? joined = _joinedLine(l10n);

    return Semantics(
      label: l10n.eventsOrganizerCompletionSheetSemantic,
      child: ReportSheetScaffold(
        title: l10n.eventsOrganizerEndedTitle,
        subtitle: summary,
        fitToContent: false,
        maxHeightFactor: 0.88,
        trailing: ReportCircleIconButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: l10n.commonClose,
          onTap: () {
            AppHaptics.tap(context);
            Navigator.of(context).pop(OrganizerEventCompletionAction.dismissed);
          },
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PrimaryButton(
              label: l10n.eventsOrganizerCompletionBackToEvent,
              enabled: true,
              onPressed: () {
                AppHaptics.tap(context);
                Navigator.of(context).pop(OrganizerEventCompletionAction.dismissed);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () {
                  AppHaptics.tap(context);
                  Navigator.of(context).pop(OrganizerEventCompletionAction.openEvidence);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: Text(
                  l10n.eventsOrganizerCompletionAddPhotosNow,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1).animate(_scale),
                child: FadeTransition(
                  opacity: _opacity,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      size: 40,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.eventsOrganizerThanksOrganizing,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.eventsOrganizerCompletionWhatNextIntro,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (joined != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _MetricPill(text: joined),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.eventsOrganizerCompletionNextStepsHeading,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NextStepRow(
              icon: CupertinoIcons.photo_on_rectangle,
              title: l10n.eventsOrganizerCompletionStepPhotosTitle,
              body: l10n.eventsOrganizerCompletionStepPhotosBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            _NextStepRow(
              icon: CupertinoIcons.chart_bar_fill,
              title: l10n.eventsOrganizerCompletionStepImpactTitle,
              body: l10n.eventsOrganizerCompletionStepImpactBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            _NextStepRow(
              icon: CupertinoIcons.heart_fill,
              title: l10n.eventsOrganizerCompletionStepVisibilityTitle,
              body: l10n.eventsOrganizerCompletionStepVisibilityBody,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NextStepRow extends StatelessWidget {
  const _NextStepRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$title. $body',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 22, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    body,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
