import 'dart:io';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/cleanup_evidence/cleanup_evidence_widgets.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class EventCleanupEvidenceScreen extends StatefulWidget {
  const EventCleanupEvidenceScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  State<EventCleanupEvidenceScreen> createState() =>
      _EventCleanupEvidenceScreenState();
}

class _EventCleanupEvidenceScreenState
    extends State<EventCleanupEvidenceScreen> {
  static const int _maxAfterImages = 8;
  static const double _heroHeight = 260;
  static const double _thumbSize = 64;
  static const double _thumbStripHeight = 74;

  final EventsRepository _eventsRepository = EventsRepositoryRegistry.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final ValueNotifier<String> _tab = ValueNotifier<String>('after');

  List<String> _afterImages = <String>[];
  int _selectedIndex = 0;
  bool _isPicking = false;
  bool _isSaving = false;

  EcoEvent? get _event => _eventsRepository.findById(widget.eventId);

  @override
  void initState() {
    super.initState();
    _eventsRepository.loadInitialIfNeeded();
    _eventsRepository.addListener(_onRepoChanged);
    _afterImages =
        List<String>.from(_event?.afterImagePaths ?? const <String>[]);
  }

  @override
  void dispose() {
    _eventsRepository.removeListener(_onRepoChanged);
    _tab.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (!mounted) return;
    void apply() {
      if (!mounted) return;
      setState(() {});
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
      return;
    }
    apply();
  }

  Future<String> _copyToDocuments(String sourcePath) async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final String basename = sourcePath.split('/').last;
    final String ext = basename.contains('.') ? '.${basename.split('.').last}' : '.jpg';
    final String name =
        'after_${widget.eventId}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final File dest = File('${docs.path}/$name');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  Future<void> _pickAfterImages() async {
    final int remaining = _maxAfterImages - _afterImages.length;
    if (remaining <= 0) {
      AppSnack.show(
        context,
        message: 'Maximum $_maxAfterImages photos reached.',
        type: AppSnackType.warning,
      );
      return;
    }

    setState(() => _isPicking = true);

    try {
      final List<XFile> picked =
          await _imagePicker.pickMultiImage(imageQuality: 86);
      if (picked.isEmpty || !mounted) {
        if (mounted) setState(() => _isPicking = false);
        return;
      }

      final List<String> next = List<String>.from(_afterImages);
      for (final XFile file in picked) {
        if (next.length >= _maxAfterImages) break;
        final String saved = await _copyToDocuments(file.path);
        if (!next.contains(saved)) {
          next.add(saved);
        }
      }
      if (!mounted) return;
      setState(() {
        _afterImages = next;
        _selectedIndex = _selectedIndex.clamp(0, _afterImages.length - 1);
        _isPicking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPicking = false);
      AppSnack.show(
        context,
        message: 'Could not pick photos. Check permissions.',
        type: AppSnackType.error,
      );
    }
  }

  void _openFullscreenGallery(int initialIndex) {
    AppHaptics.softTransition();
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (BuildContext context) => CleanupFullscreenGalleryPage(
          imagePaths: _afterImages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _removeAfterImage(int index) {
    if (index < 0 || index >= _afterImages.length) return;
    setState(() {
      _afterImages.removeAt(index);
      if (_afterImages.isEmpty) {
        _selectedIndex = 0;
      } else if (_selectedIndex >= _afterImages.length) {
        _selectedIndex = _afterImages.length - 1;
      }
    });
  }

  void _setAsCover(int index) {
    if (index < 0 || index >= _afterImages.length) return;
    if (index == 0) return;
    setState(() {
      final String path = _afterImages.removeAt(index);
      _afterImages.insert(0, path);
      _selectedIndex = 0;
    });
  }

  void _showThumbnailContextMenu(int index) {
    AppHaptics.softTransition();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(CupertinoIcons.star),
                title: const Text('Set as cover'),
                onTap: () {
                  Navigator.pop(context);
                  _setAsCover(index);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.eye),
                title: const Text('View fullscreen'),
                onTap: () {
                  Navigator.pop(context);
                  _openFullscreenGallery(index);
                },
              ),
              ListTile(
                leading: Icon(CupertinoIcons.trash, color: AppColors.accentDanger),
                title: Text(
                  'Remove',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.accentDanger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeAfterImage(index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final EcoEvent? event = _event;
    if (event == null) return;

    setState(() => _isSaving = true);
    final bool changed = _eventsRepository.setAfterImages(
      eventId: event.id,
      imagePaths: _afterImages,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    AppHaptics.success();
    AppSnack.show(
      context,
      message: changed ? 'After photos saved.' : 'No changes to save.',
      type: AppSnackType.success,
    );
    Navigator.of(context).pop();
  }

  Widget _buildImage(String path, {double? height, BoxFit fit = BoxFit.cover}) {
    return Image(
      image: path.startsWith('assets/')
          ? AssetImage(path) as ImageProvider
          : FileImage(File(path)),
      width: double.infinity,
      height: height,
      fit: fit,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
        return Container(
          width: double.infinity,
          height: height,
          color: AppColors.inputFill,
          alignment: Alignment.center,
          child: const Icon(CupertinoIcons.photo, color: AppColors.textMuted),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final EcoEvent? event = _event;
    if (event == null) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: const AppBackButton(),
          title: const Text('Photos'),
        ),
        body: const Center(child: Text('Event not found.')),
      );
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    final bool hasPendingChanges =
        !listEquals(_afterImages, event.afterImagePaths);
    final bool canSave = hasPendingChanges && !_isSaving;

    return PopScope(
      canPop: !hasPendingChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _showDiscardDialog(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: AppBackButton(onPressed: () {
            if (hasPendingChanges) {
              _showDiscardDialog(context);
            } else {
              Navigator.of(context).maybePop();
            }
          }),
          title: Text(
            'Cleanup evidence',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: _tab,
              builder: (BuildContext context, String value, Widget? child) {
                return SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: value,
                    children: <String, Widget>{
                      'before': Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.radiusXl,
                          vertical: AppSpacing.radius10,
                        ),
                        child: Text('Before'),
                      ),
                      'after': Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.radiusXl,
                          vertical: AppSpacing.radius10,
                        ),
                        child: Text('After'),
                      ),
                    },
                    onValueChanged: (String? next) {
                      if (next != null) _tab.value = next;
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _tab,
              builder: (BuildContext context, String value, Widget? child) {
                return AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: value == 'before'
                      ? BeforeTab(
                          key: const ValueKey<String>('before'),
                          event: event,
                          heroHeight: _heroHeight,
                          buildImage: _buildImage,
                        )
                      : AfterTab(
                          key: const ValueKey<String>('after'),
                          afterImages: _afterImages,
                          selectedIndex: _selectedIndex,
                          isPicking: _isPicking,
                          maxImages: _maxAfterImages,
                          heroHeight: _heroHeight,
                          thumbSize: _thumbSize,
                          thumbStripHeight: _thumbStripHeight,
                          onPick: _pickAfterImages,
                          onRemove: _removeAfterImage,
                          onSelect: (int i) =>
                              setState(() => _selectedIndex = i),
                          onImageTap: _openFullscreenGallery,
                          onThumbnailLongPress: _showThumbnailContextMenu,
                          buildImage: _buildImage,
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md + bottomSafe,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: _isSaving
                  ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const CupertinoActivityIndicator(
                            color: AppColors.textPrimary,
                            radius: 10,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Saving...',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : PrimaryButton(
                      label: 'Save',
                      enabled: canSave,
                      onPressed: canSave ? _save : null,
                    ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showDiscardDialog(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return CupertinoAlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved photos. Are you sure you want to leave?'),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Keep editing'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
  }
}
