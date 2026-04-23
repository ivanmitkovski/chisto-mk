import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Bottom sheet: volunteer cap presets, no limit, or custom numeric entry.
class CreateEventVolunteerCapPickerSheet extends StatefulWidget {
  const CreateEventVolunteerCapPickerSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  final int? initial;
  final void Function(int?) onApply;

  static const List<int> presets = <int>[15, 30, 50, 100];

  @override
  State<CreateEventVolunteerCapPickerSheet> createState() =>
      _CreateEventVolunteerCapPickerSheetState();
}

class _CreateEventVolunteerCapPickerSheetState
    extends State<CreateEventVolunteerCapPickerSheet> {
  late int? _selected;
  final TextEditingController _customController = TextEditingController();
  String? _customError;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    final int? initial = widget.initial;
    if (initial != null && !CreateEventVolunteerCapPickerSheet.presets.contains(initial)) {
      _customController.text = '$initial';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _applyCustom() {
    final int? parsed = int.tryParse(_customController.text.trim());
    if (parsed == null || parsed < 2 || parsed > 5000) {
      setState(
        () => _customError = context.l10n.createEventVolunteerCapInvalid,
      );
      return;
    }
    widget.onApply(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ReportSheetScaffold(
      title: context.l10n.createEventVolunteerCapSheetTitle,
      subtitle: context.l10n.createEventVolunteerCapSheetSubtitle,
      trailing: ReportCircleIconButton(
        icon: CupertinoIcons.xmark,
        semanticLabel: context.l10n.commonClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      maxHeightFactor: 0.88,
      addBottomInset: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      footer: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_customError != null) ...<Widget>[
              Text(
                _customError!,
                style: AppTypography.eventsCaptionStrong(
                  textTheme,
                  color: AppColors.accentDanger,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _applyCustom,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: Text(
                  context.l10n.createEventVolunteerCapApply,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        children: <Widget>[
          ReportActionTile(
            icon: CupertinoIcons.infinite,
            title: context.l10n.createEventVolunteerCapNoLimit,
            tone: _selected == null
                ? ReportSurfaceTone.accent
                : ReportSurfaceTone.neutral,
            trailing: Icon(
              _selected == null
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 22,
              color: _selected == null
                  ? AppColors.primaryDark
                  : AppColors.divider,
            ),
            onTap: () {
              AppHaptics.tap();
              widget.onApply(null);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          ...CreateEventVolunteerCapPickerSheet.presets.expand((int n) {
            final bool isActive = _selected == n;
            return <Widget>[
              ReportActionTile(
                icon: CupertinoIcons.person_3_fill,
                title: '$n',
                tone: isActive
                    ? ReportSurfaceTone.accent
                    : ReportSurfaceTone.neutral,
                trailing: Icon(
                  isActive
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  size: 22,
                  color: isActive
                      ? AppColors.primaryDark
                      : AppColors.divider,
                ),
                onTap: () {
                  AppHaptics.tap();
                  widget.onApply(n);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ];
          }),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.createEventVolunteerCapCustomLabel,
            style: AppTypography.eventsFormLeadHeading(textTheme),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _customError = null),
            decoration: InputDecoration(
              hintText: context.l10n.createEventVolunteerCapCustomHint,
              filled: true,
              fillColor: AppColors.panelBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radius14),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radius14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
