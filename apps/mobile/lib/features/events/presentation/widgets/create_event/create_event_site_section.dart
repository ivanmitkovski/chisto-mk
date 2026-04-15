import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_sites_map.dart';

class CreateEventSiteSection extends StatelessWidget {
  const CreateEventSiteSection({
    super.key,
    required this.sectionKey,
    required this.site,
    required this.showValidationErrors,
    required this.onSelectSiteTap,
    required this.onMapPreviewTap,
  });

  final Key sectionKey;
  final EventSiteSummary? site;
  final bool showValidationErrors;
  final Future<void> Function() onSelectSiteTap;
  final Future<void> Function() onMapPreviewTap;

  @override
  Widget build(BuildContext context) {
    final bool hasError = showValidationErrors && site == null;
    final bool hasCoords =
        site != null && site!.latitude != null && site!.longitude != null;

    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.createEventCleanupSiteTitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hasError
                ? AppColors.accentDanger.withValues(alpha: 0.04)
                : AppColors.panelBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radius18),
            border: Border.all(
              color: hasError
                  ? AppColors.accentDanger
                  : site == null
                      ? AppColors.divider
                      : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radius14),
                  onTap: () => unawaited(onSelectSiteTap()),
                  child: Semantics(
                    button: true,
                    label: context.l10n.createEventSelectSiteSemantic,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: AppSpacing.avatarMd,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radius14,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.location_solid,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                site?.title ??
                                    context.l10n.createEventChooseSitePlaceholder,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: site == null
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                site == null
                                    ? context.l10n.createEventSiteAnchorHint
                                    : context.l10n.createEventSiteDistanceAway(
                                        site!.distanceKm.toStringAsFixed(1),
                                        site!.description,
                                      ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textMuted,
                                      height: 1.35,
                                    ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasCoords && site != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  button: true,
                  label: context.l10n.createEventSiteMapPreviewSemantic,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      onTap: () => unawaited(onMapPreviewTap()),
                      child: CreateEventSitesMap(
                        sites: <EventSiteSummary>[site!],
                        selectedSiteId: site!.id,
                        height: 112,
                        interactive: false,
                        onSiteTap: (_) {},
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              context.l10n.createEventSiteRequiredError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accentDanger,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
      ],
    );
  }
}
