import 'package:chisto_infrastructure/core/concurrency/single_flight.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/molecules/api_error_banner.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_home/src/presentation/widgets/resolution_submitted_dialog.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class SubmitResolutionSheet extends ConsumerStatefulWidget {
  const SubmitResolutionSheet({
    super.key,
    required this.siteId,
    this.siteTitle,
    this.sitesRepository,
    @visibleForTesting this.testInitialPhotos,
  });

  final String siteId;
  final String? siteTitle;
  final SitesRepository? sitesRepository;

  @visibleForTesting
  final List<XFile>? testInitialPhotos;

  static Future<bool?> show(
    BuildContext context, {
    required String siteId,
    String? siteTitle,
    SitesRepository? sitesRepository,
  }) {
    return AppBottomSheet.show<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: false,
      isScrollControlled: true,
      keyboardInsetMode: SheetKeyboardInsetMode.overlay,
      maxHeightFactor: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      builder: (BuildContext context) => SubmitResolutionSheet(
        siteId: siteId,
        siteTitle: siteTitle,
        sitesRepository: sitesRepository,
      ),
    );
  }

  @override
  ConsumerState<SubmitResolutionSheet> createState() =>
      _SubmitResolutionSheetState();
}

class _SubmitResolutionSheetState extends ConsumerState<SubmitResolutionSheet>
    with WidgetsBindingObserver {
  late final List<XFile> _photos =
      List<XFile>.from(widget.testInitialPhotos ?? const <XFile>[]);
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _noteSectionKey = GlobalKey();
  final ImagePicker _imagePicker = ImagePicker();
  final SingleFlight<void> _submitFlight = SingleFlight<void>();
  bool _isSubmitting = false;
  bool _isProcessingPhotoFlow = false;
  AppError? _submitError;

  SitesRepository get _repository =>
      widget.sitesRepository ?? ref.read(sitesRepositoryProvider);

  bool get _canSubmit =>
      _photos.isNotEmpty && !_isSubmitting && !_isProcessingPhotoFlow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _noteFocus.addListener(_scrollNoteIntoViewOnFocus);
  }

  void _scrollNoteIntoViewOnFocus() {
    if (!_noteFocus.hasFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureNoteVisible();
      _scheduleNoteVisibleAfterCollapse();
    });
  }

  void _scheduleNoteVisibleAfterCollapse() {
    Future<void>.delayed(AppMotion.medium, () {
      if (mounted) {
        _ensureNoteVisible();
      }
    });
  }

  void _ensureNoteVisible() {
    if (!mounted || !_noteFocus.hasFocus) {
      return;
    }
    final BuildContext? noteContext = _noteSectionKey.currentContext;
    if (noteContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      noteContext,
      alignment: 0.12,
      duration: AppMotion.medium,
      curve: AppMotion.smooth,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_noteFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureNoteVisible();
        _scheduleNoteVisibleAfterCollapse();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noteFocus.removeListener(_scrollNoteIntoViewOnFocus);
    _noteFocus.dispose();
    _scrollController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_isProcessingPhotoFlow ||
        _isSubmitting ||
        _photos.length >= ReportFieldLimits.maxPhotos) {
      return;
    }
    // Mark the flow active up front so Submit stays disabled while the source
    // picker and camera are open; the finally clears it whether a photo was
    // added or the picker was cancelled.
    setState(() => _isProcessingPhotoFlow = true);
    try {
      final ImageSource? source = await showPhotoSourceModal(context);
      if (source == null || !mounted) return;
      while (mounted) {
        XFile? file;
        try {
          file = await _imagePicker.pickImage(
            source: source,
            preferredCameraDevice: CameraDevice.rear,
          );
        } on PlatformException {
          if (mounted) {
            AppSnack.show(
              context,
              message: context.l10n.reportFlowCameraUnavailableSnack,
              type: AppSnackType.warning,
            );
          }
          return;
        }
        if (!mounted || file == null) return;

        final ReportUploadImageValidation validation =
            await validateReportUploadImage(file);
        if (!mounted) return;
        if (!validation.isSupported) {
          if (mounted) {
            AppSnack.show(
              context,
              message: context.l10n.reportFlowUnsupportedPhotoFormatSnack,
              type: AppSnackType.warning,
            );
          }
          continue;
        }

        final PhotoReviewResult? result =
            await AppBottomSheet.show<PhotoReviewResult>(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.transparent,
              builder: (_) => PhotoReviewSheet(file: file!),
            );
        if (!mounted) return;

        if (result == PhotoReviewResult.retake) {
          continue;
        }
        if (result == PhotoReviewResult.use) {
          AppHaptics.tap();
          setState(() => _photos.add(file!));
        }
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPhotoFlow = false);
      }
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  String _submitErrorMessage(AppLocalizations l10n) {
    final AppError error = _submitError!;
    if (error.code == 'SERVER_ERROR' ||
        error.code == 'UNKNOWN' ||
        error.code == 'HTTP_ERROR') {
      return l10n.submitResolutionErrorBody;
    }
    return localizedAppErrorMessage(l10n, error);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    await _submitFlight.run(() async {
      if (!mounted || !_canSubmit) return;
      final NavigatorState navigator = Navigator.of(context);
      final NavigatorState rootNavigator =
          Navigator.of(context, rootNavigator: true);
      setState(() {
        _isSubmitting = true;
        _submitError = null;
      });
      try {
        final AppLocalizations l10n = context.l10n;
        final List<String> paths =
            _photos.map((XFile f) => f.path).toList(growable: false);
        final List<String> mediaUrls = await _repository.uploadResolutionPhotos(
          widget.siteId,
          paths,
        );
        if (mediaUrls.isEmpty) {
          throw AppError.validation(message: l10n.submitResolutionErrorBody);
        }
        await _repository.submitSiteResolution(
          siteId: widget.siteId,
          mediaUrls: mediaUrls,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
        if (!mounted) return;
        final ResolutionSubmittedDialogResult? dialogResult =
            await ResolutionSubmittedDialog.show(rootNavigator.context);
        if (!mounted) return;
        navigator.pop(true);
        await handleResolutionSubmittedDialogResult(context, dialogResult);
      } on AppError catch (error) {
        if (!mounted) return;
        setState(() => _submitError = error);
      } catch (_) {
        if (!mounted) return;
        setState(() => _submitError = AppError.unknown());
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    });
  }

  Widget _buildPhotoGrid() {
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PhotoGrid(
      photos: _photos,
      onAddPhoto: _addPhoto,
      onRemovePhoto: _removePhoto,
      reportId: 'resolution-${widget.siteId}',
      compact: _photos.isNotEmpty,
      showExpandedAddCard: true,
      hideExpandedAddCard: keyboardOpen && _photos.isNotEmpty,
    );
  }

  Widget _buildNoteSection(TextTheme textTheme, AppLocalizations l10n) {
    return KeyedSubtree(
      key: _noteSectionKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.submitResolutionNoteLabel,
            style: AppTypographySurfaces.reportsFormFieldLabel(textTheme),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            controller: _noteController,
            focusNode: _noteFocus,
            hintText: l10n.submitResolutionNoteHint,
            maxLines: 3,
            minLines: 2,
            maxLength: 500,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.newline,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollBody(TextTheme textTheme, AppLocalizations l10n) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      controller: _scrollController,
      clipBehavior: Clip.none,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildPhotoGrid(),
          const SizedBox(height: AppSpacing.md),
          if (_submitError != null) ...<Widget>[
            ApiErrorBanner(
              message: _submitErrorMessage(l10n),
              onDismiss: () => setState(() => _submitError = null),
              onRetry: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _buildNoteSection(textTheme, l10n),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PrimaryButton(
          label: l10n.submitResolutionSubmitButton,
          isLoading: _isSubmitting,
          onPressed: _canSubmit ? _submit : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.submitResolutionHelpText,
          style: AppTypographySurfaces.reportsBannerBody(textTheme),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;
    final String? title = widget.siteTitle?.trim();

    return ReportSheetScaffold(
      addBottomInset: true,
      maxHeightFactor: 1,
      fillAvailableHeight: true,
      shrinkForKeyboard: false,
      padFooterForKeyboard: false,
      useModalRouteShape: true,
      animateHandleFadeIn: true,
      headerDividerGap: AppSpacing.md,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      dragHandleSemanticLabel: l10n.semanticClose,
      titleTextStyle: AppTypographySurfaces.reportsSheetTitle(textTheme),
      subtitleTextStyle: AppTypographySurfaces.reportsSheetSubtitle(textTheme),
      title: l10n.submitResolutionSheetTitle,
      subtitle: title != null && title.isNotEmpty
          ? l10n.submitResolutionSheetSubtitle(title)
          : l10n.submitResolutionSheetSubtitleGeneric,
      subtitleMaxLines: 2,
      footer: _buildFooter(l10n, textTheme),
      trailing: ReportCircleIconButton(
        icon: Icons.close_rounded,
        semanticLabel: l10n.semanticClose,
        onTap: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
      child: _buildScrollBody(textTheme, l10n),
    );
  }
}
