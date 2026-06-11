import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    if (initial != null &&
        !CreateEventVolunteerCapPickerSheet.presets.contains(initial)) {
      _customController.text = '$initial';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _apply() {
    _dismissKeyboard();
    if (_customController.text.trim().isNotEmpty) {
      _applyCustom();
      return;
    }
    setState(() => _customError = null);
    widget.onApply(_selected);
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

  void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AppSheetScaffold(
      title: context.l10n.createEventVolunteerCapSheetTitle,
      subtitle: context.l10n.createEventVolunteerCapSheetSubtitle,
      trailing: AppCircleIconButton(
        icon: CupertinoIcons.xmark,
        semanticLabel: context.l10n.commonClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      maxHeightFactor: 0.88,
      fillAvailableHeight: true,
      padFooterForKeyboard: true,
      addBottomInset: true,
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
            AppButton.primary(
              label: context.l10n.createEventVolunteerCapApply,
              onPressed: _apply,
              expand: true,
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: AppSpacing.md + keyboardInset,
                ),
                children: <Widget>[
                  AppGroupedActionList(
                    children: <Widget>[
                      AppActionTile(
                        variant: AppActionTileVariant.grouped,
                        icon: CupertinoIcons.infinite,
                        title: context.l10n.createEventVolunteerCapNoLimit,
                        tone: _selected == null
                            ? AppSurfaceTone.accent
                            : AppSurfaceTone.neutral,
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
                          setState(() {
                            _selected = null;
                            _customError = null;
                          });
                          widget.onApply(null);
                        },
                      ),
                      ...CreateEventVolunteerCapPickerSheet.presets.map((int n) {
                        final bool isActive = _selected == n;
                        return AppActionTile(
                          variant: AppActionTileVariant.grouped,
                          icon: CupertinoIcons.person_3_fill,
                          title: '$n',
                          tone: isActive
                              ? AppSurfaceTone.accent
                              : AppSurfaceTone.neutral,
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
                            setState(() {
                              _selected = n;
                              _customError = null;
                            });
                            widget.onApply(n);
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.createEventVolunteerCapCustomLabel,
                    style: AppTypography.eventsFormLeadHeading(textTheme),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DesignSystemTextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() => _customError = null),
                    onSubmitted: (_) => _dismissKeyboard(),
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
            ),
          ],
        ),
      ),
    );
  }
}
