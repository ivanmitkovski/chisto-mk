import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _ManualEntrySheetHandle extends StatelessWidget {
  const _ManualEntrySheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Center(
        child: Container(
          width: AppSpacing.sheetHandle,
          height: AppSpacing.sheetHandleHeight,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(
              AppSpacing.sheetHandleHeight / 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Manual QR code entry sheet for attendees.
/// The modal host uses [MediaQueryData.fromView] + [SafeArea.minimum] so insets
/// stay correct when the bottom-sheet route’s inherited [MediaQuery] zeros out
/// [padding]/[viewPadding] (common with edge-to-edge). Cancel + Submit stay
/// pinned; the keyboard overlays the sheet (host strips bottom viewInsets).
class AttendeeManualCodeEntrySheet extends StatefulWidget {
  const AttendeeManualCodeEntrySheet({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<AttendeeManualCodeEntrySheet> createState() =>
      _AttendeeManualCodeEntrySheetState();
}

class _AttendeeManualCodeEntrySheetState
    extends State<AttendeeManualCodeEntrySheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  bool get _canSubmit => widget.controller.text.trim().isNotEmpty;

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || data?.text == null) {
      return;
    }
    widget.controller.text = data!.text!;
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomSafe = MediaQuery.paddingOf(context).bottom;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SizedBox.expand(
        child: Material(
          color: AppColors.panelBackground,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const _ManualEntrySheetHandle(),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  l10n.qrScannerManualEntryTitle,
                                  style:
                                      AppTypography.eventsScreenTitle(
                                        textTheme,
                                      ).copyWith(
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.qrScannerManualEntrySubtitle,
                                  style:
                                      AppTypography.eventsBodyMediumSecondary(
                                        textTheme,
                                      ).copyWith(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: l10n.commonClose,
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CupertinoTextField(
                        controller: widget.controller,
                        autofocus: true,
                        minLines: 4,
                        maxLines: 8,
                        placeholder: l10n.qrScannerPasteOrganizerQrHint,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        style: AppTypography.eventsEditFormFieldPrimary(
                          textTheme,
                        ).copyWith(height: 1.35),
                        placeholderStyle:
                            AppTypography.eventsSearchFieldPlaceholder(
                              textTheme,
                            ),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(
                          CupertinoIcons.doc_on_clipboard,
                          size: 20,
                          color: AppColors.primaryDark,
                        ),
                        label: Text(
                          l10n.qrScannerPasteButton,
                          style: AppTypography.eventsTextLinkEmphasis(
                            textTheme,
                          ).copyWith(color: AppColors.primaryDark),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(color: AppColors.inputBorder),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                            horizontal: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.panelBackground,
                  border: Border(
                    top: BorderSide(color: AppColors.divider, width: 0.5),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md + bottomSafe,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: AppButton.outlined(
                          label: l10n.commonCancel,
                          onPressed: () => Navigator.of(context).pop(false),
                          expand: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          label: l10n.qrScannerSubmitCode,
                          enabled: _canSubmit,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
