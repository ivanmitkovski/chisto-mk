import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';

/// Frosted search bar for map search (legacy; search now uses MapSearchModal).
class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.focusNode,
    required this.results,
    required this.onResultTap,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final FocusNode focusNode;
  final List<PollutionSite> results;
  final ValueChanged<PollutionSite> onResultTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: TextField(
                focusNode: focusNode,
                controller: controller,
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  hintText: 'Search sites...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
              ),
            ),
          ),
        ),
        if (results.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (BuildContext context, int index) {
                      final PollutionSite site = results[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          site.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: site.pollutionType != null
                            ? Text(
                                site.pollutionType!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                maxLines: 1,
                              )
                            : null,
                        onTap: () => onResultTap(site),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
