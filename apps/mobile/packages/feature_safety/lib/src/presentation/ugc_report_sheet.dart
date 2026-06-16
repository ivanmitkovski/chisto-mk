import 'package:chisto_infrastructure/core/concurrency/single_flight.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/forms/form_validation_mixin.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_safety/src/application/safety_providers.dart';
import 'package:feature_safety/src/data/ugc_moderation_repository.dart';
import 'package:feature_safety/src/domain/safety_domain.dart';
import 'package:feature_safety/src/presentation/ugc_report_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet to report UGC (comment, chat message, user, etc.).
Future<bool?> showUgcReportSheet(
  BuildContext context, {
  required String subjectType,
  required String subjectId,
  String? title,
  UgcModerationRepository? repository,
}) {
  final UgcModerationRepository repo =
      repository ??
      ProviderScope.containerOf(context).read(ugcModerationRepositoryProvider);
  return AppBottomSheet.show<bool>(
    context: context,
    maxHeightFactor: 0.82,
    keyboardInsetMode: SheetKeyboardInsetMode.lift,
    builder: (BuildContext ctx) => _UgcReportSheetBody(
      subjectType: subjectType,
      subjectId: subjectId,
      title: title,
      repository: repo,
    ),
  );
}

/// Typography for [showUgcReportSheet] — aligned with other profile/report sheets.
abstract final class UgcReportSheetTypography {
  static TextStyle title(TextTheme theme) => AppTypography.sheetTitle(theme);

  static TextStyle reasonLabel(TextTheme theme) =>
      (theme.bodyLarge ?? AppTypography.textTheme.bodyLarge!).copyWith(
        color: AppColors.textPrimary,
        letterSpacing: -0.1,
      );
}

class _UgcReportSheetBody extends StatefulWidget {
  const _UgcReportSheetBody({
    required this.subjectType,
    required this.subjectId,
    this.title,
    required this.repository,
  });

  final String subjectType;
  final String subjectId;
  final String? title;
  final UgcModerationRepository repository;

  @override
  State<_UgcReportSheetBody> createState() => _UgcReportSheetBodyState();
}

class _UgcReportSheetBodyState extends State<_UgcReportSheetBody>
    with FormValidationMixin {
  static const String _detailsFieldId = 'details';

  String _reason = 'spam';
  bool _submitting = false;
  final SingleFlight<void> _submitFlight = SingleFlight<void>();
  final TextEditingController _details = TextEditingController();
  final FocusNode _detailsFocus = FocusNode();
  final GlobalKey _detailsFieldKey = GlobalKey();

  bool get _isOtherReason => _reason == 'other';

  @override
  void initState() {
    super.initState();
    registerFormField(
      _detailsFieldId,
      focusNode: _detailsFocus,
      fieldKey: _detailsFieldKey,
    );
    _details.addListener(_onDetailsChanged);
  }

  @override
  void dispose() {
    _details
      ..removeListener(_onDetailsChanged)
      ..dispose();
    _detailsFocus.dispose();
    super.dispose();
  }

  void _onDetailsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int get _detailsLength => _details.text.characters.length;

  String? _detailsFieldError(AppLocalizations l10n) {
    if (_detailsLength > kUgcReportDetailsMaxLength) {
      return l10n.safetyReportDetailsTooLong(kUgcReportDetailsMaxLength);
    }
    if (_isOtherReason && _details.text.trim().isEmpty) {
      return l10n.safetyReportDetailsRequiredWhenOther;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final AppLocalizations l10n = context.l10n;
    final bool invalid = await handleInvalidSubmit(
      context,
      l10n,
      <String>[_detailsFieldId],
      <String, String? Function()>{
        _detailsFieldId: () => _detailsFieldError(l10n),
      },
    );
    if (invalid || !mounted) {
      return;
    }

    await _submitFlight.run(() async {
      if (!mounted || _submitting) return;
      setState(() => _submitting = true);
      try {
        final String trimmed = _details.text.trim();
        await SubmitUgcReportUseCase(repository: widget.repository).call(
          subjectType: widget.subjectType,
          subjectId: widget.subjectId,
          reason: _reason,
          details: trimmed.isEmpty ? null : trimmed,
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
        AppSnack.show(
          context,
          message: context.l10n.safetyReportSubmitted,
          type: AppSnackType.success,
        );
      } on AppError catch (e) {
        if (!mounted) return;
        AppSnack.failure(context, error: e);
      } on Object {
        if (!mounted) return;
        AppSnack.show(
          context,
          message: context.l10n.safetyReportFailed,
          type: AppSnackType.error,
        );
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    });
  }

  Color _counterColor({required String? detailsError}) {
    if (detailsError != null || _detailsLength >= kUgcReportDetailsMaxLength) {
      return AppColors.error;
    }
    if (_detailsLength >= kUgcReportDetailsCounterWarningThreshold) {
      return AppColors.accentWarning;
    }
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? detailsError = validateIfVisible(
      _detailsFieldId,
      () => _detailsFieldError(l10n),
    );
    final String counterLabel = l10n.safetyReportDetailsCharCount(
      _detailsLength,
      kUgcReportDetailsMaxLength,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(
          context,
        ).clamp(maxScaleFactor: 1.34),
      ),
      child: AppSheetScaffold(
        title: widget.title ?? l10n.safetyReportTitle,
        useModalRouteShape: true,
        fitToContent: true,
        addBottomInset: true,
        trailing: AppCircleIconButton(
          icon: Icons.close_rounded,
          semanticLabel: l10n.commonClose,
          onTap: () => Navigator.of(context).pop(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),
            ...<String>[
              'spam',
              'harassment',
              'hate',
              'violence',
              'nudity',
              'other',
            ].map(
              (String value) => RadioListTile<String>(
                value: value,
                // ignore: deprecated_member_use -- RadioGroup migration tracked separately
                groupValue: _reason,
                // ignore: deprecated_member_use -- RadioGroup migration tracked separately
                onChanged: _submitting
                    ? null
                    : (String? v) => setState(() => _reason = v!),
                title: Text(
                  _reasonLabel(l10n, value),
                  style: UgcReportSheetTypography.reasonLabel(textTheme),
                ),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                activeColor: AppColors.primaryDark,
              ),
            ),
            KeyedSubtree(
              key: _detailsFieldKey,
              child: AppTextField(
                controller: _details,
                focusNode: _detailsFocus,
                hintText: _isOtherReason
                    ? l10n.safetyReportDetailsHintRequired
                    : l10n.safetyReportDetailsHint,
                maxLines: 3,
                minLines: 3,
                enabled: !_submitting,
                textCapitalization: TextCapitalization.sentences,
                errorText: detailsError,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(kUgcReportDetailsMaxLength),
                ],
                onChanged: (_) => markFieldTouched(_detailsFieldId),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                liveRegion: detailsError != null,
                label: counterLabel,
                child: Text(
                  counterLabel,
                  style: AppTypographySurfaces.homeCommentsComposerCounter(
                    textTheme,
                    color: _counterColor(detailsError: detailsError),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: l10n.safetyReportSubmit,
              onPressed: _submitting ? null : _submit,
              isLoading: _submitting,
            ),
            SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
          ],
        ),
      ),
    );
  }

  String _reasonLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'harassment':
        return l10n.safetyReportReasonHarassment;
      case 'hate':
        return l10n.safetyReportReasonHate;
      case 'violence':
        return l10n.safetyReportReasonViolence;
      case 'nudity':
        return l10n.safetyReportReasonNudity;
      case 'other':
        return l10n.safetyReportReasonOther;
      default:
        return l10n.safetyReportReasonSpam;
    }
  }
}
