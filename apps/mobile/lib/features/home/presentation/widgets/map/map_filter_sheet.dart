import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class MapFilterSheet extends StatefulWidget {
  const MapFilterSheet({
    super.key,
    required this.activeStatuses,
    required this.activePollutionTypes,
    required this.visibleCount,
    required this.totalCount,
    required this.allPollutionTypes,
    required this.onToggleStatus,
    required this.onTogglePollutionType,
    required this.onDismiss,
  });

  final Set<String> activeStatuses;
  final Set<String> activePollutionTypes;
  final int visibleCount;
  final int totalCount;
  final List<String> allPollutionTypes;
  final void Function(String status) onToggleStatus;
  final void Function(String type) onTogglePollutionType;
  final VoidCallback onDismiss;

  @override
  State<MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<MapFilterSheet> {
  late Set<String> _activeStatuses;
  late Set<String> _activePollutionTypes;

  @override
  void initState() {
    super.initState();
    _activeStatuses = Set<String>.from(widget.activeStatuses);
    _activePollutionTypes = Set<String>.from(widget.activePollutionTypes);
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_activeStatuses.contains(status)) {
        if (_activeStatuses.length == 1) return;
        _activeStatuses.remove(status);
      } else {
        _activeStatuses.add(status);
      }
    });
    widget.onToggleStatus(status);
    AppHaptics.light();
  }

  void _toggleType(String type) {
    setState(() {
      if (_activePollutionTypes.contains(type)) {
        if (_activePollutionTypes.length == 1) return;
        _activePollutionTypes.remove(type);
      } else {
        _activePollutionTypes.add(type);
      }
    });
    widget.onTogglePollutionType(type);
    AppHaptics.light();
  }

  @override
  Widget build(BuildContext context) {
    final int visibleCount = widget.visibleCount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Filter sites',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: AppColors.textMuted,
                    tooltip: 'Close filters',
                    onPressed: () {
                      AppHaptics.sheetDismiss();
                      widget.onDismiss();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilterSection(
                title: 'Severity',
                child: Row(
                  children: <Widget>[
                    StatusChip(
                      label: 'High',
                      color: AppColors.accentDanger,
                      isActive: _activeStatuses.contains('High'),
                      onTap: () => _toggleStatus('High'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusChip(
                      label: 'Medium',
                      color: AppColors.accentWarning,
                      isActive: _activeStatuses.contains('Medium'),
                      onTap: () => _toggleStatus('Medium'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusChip(
                      label: 'Low',
                      color: AppColors.primary,
                      isActive: _activeStatuses.contains('Low'),
                      onTap: () => _toggleStatus('Low'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilterSection(
                title: 'Pollution type',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: widget.allPollutionTypes.map((String type) {
                    final bool isActive = _activePollutionTypes.contains(type);
                    return TypeChip(
                      label: type,
                      isActive: isActive,
                      onTap: () => _toggleType(type),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '$visibleCount of ${widget.totalCount} sites visible',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterSection extends StatelessWidget {
  const FilterSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class TypeChip extends StatelessWidget {
  const TypeChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: 'Filter $label sites',
      hint: isActive
          ? 'Double tap to hide this type'
          : 'Double tap to show this type',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.radius14,
            vertical: AppSpacing.radius10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isActive
        ? AppColors.textPrimary
        : AppColors.textMuted.withValues(alpha: 0.85);
    final Color background = isActive
        ? color.withValues(alpha: 0.12)
        : AppColors.white.withValues(alpha: 0.35);

    return Semantics(
      button: true,
      selected: isActive,
      label: 'Filter $label severity sites',
      hint: isActive
          ? 'Double tap to hide this severity'
          : 'Double tap to show this severity',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.5)
                  : AppColors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isActive ? 1 : 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
