import 'dart:io';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui' as ui;
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
        builder: (BuildContext context) => _CleanupFullscreenGalleryPage(
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
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                  style: TextStyle(color: AppColors.accentDanger, fontWeight: FontWeight.w600),
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
                    children: const <String, Widget>{
                      'before': Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text('Before'),
                      ),
                      'after': Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      ? _BeforeTab(
                          key: const ValueKey<String>('before'),
                          event: event,
                          buildImage: _buildImage,
                        )
                      : _AfterTab(
                          key: const ValueKey<String>('after'),
                          afterImages: _afterImages,
                          selectedIndex: _selectedIndex,
                          isPicking: _isPicking,
                          maxImages: _maxAfterImages,
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
                        borderRadius: BorderRadius.circular(28),
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
                            style: const TextStyle(
                              fontSize: 19,
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

class _BeforeTab extends StatelessWidget {
  const _BeforeTab({
    super.key,
    required this.event,
    required this.buildImage,
  });

  final EcoEvent event;
  final Widget Function(String path, {double? height, BoxFit fit}) buildImage;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: buildImage(
              event.siteImageUrl,
              height: _EventCleanupEvidenceScreenState._heroHeight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Site reference photo',
            style:
                textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reference taken before cleanup. Use the After tab to add photos of the cleaned site.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AfterTab extends StatelessWidget {
  const _AfterTab({
    super.key,
    required this.afterImages,
    required this.selectedIndex,
    required this.isPicking,
    required this.maxImages,
    required this.onPick,
    required this.onRemove,
    required this.onSelect,
    required this.onImageTap,
    required this.onThumbnailLongPress,
    required this.buildImage,
  });

  final List<String> afterImages;
  final int selectedIndex;
  final bool isPicking;
  final int maxImages;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onImageTap;
  final ValueChanged<int> onThumbnailLongPress;
  final Widget Function(String path, {double? height, BoxFit fit}) buildImage;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (isPicking) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (afterImages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Semantics(
          button: true,
          label: 'Upload after photos',
          child: _AddPhotosEmptyState(
            maxImages: maxImages,
            onTap: onPick,
            textTheme: textTheme,
          ),
        ),
      );
    }

    final String selectedPath = afterImages[selectedIndex.clamp(0, afterImages.length - 1)];
    final int remaining = maxImages - afterImages.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Semantics(
                button: true,
                label: 'View photo fullscreen',
                child: GestureDetector(
                  onTap: () => onImageTap(selectedIndex.clamp(0, afterImages.length - 1)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: buildImage(
                      selectedPath,
                      height: _EventCleanupEvidenceScreenState._heroHeight,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  onPressed: () => onRemove(
                    selectedIndex.clamp(0, afterImages.length - 1),
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.trash,
                      size: 18,
                      color: AppColors.accentDanger,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Upload more photos',
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${afterImages.length} uploaded',
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '$remaining more slot${remaining == 1 ? '' : 's'} available',
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: _EventCleanupEvidenceScreenState._thumbStripHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: afterImages.length + (remaining > 0 ? 1 : 0),
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0 && remaining > 0) {
                  return Semantics(
                    button: true,
                    label: 'Add more photos',
                    child: GestureDetector(
                      onTap: onPick,
                      child: Container(
                        width: _EventCleanupEvidenceScreenState._thumbSize,
                        height: _EventCleanupEvidenceScreenState._thumbSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.plus,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }
                final int imageIndex = remaining > 0 ? index - 1 : index;
                final String path = afterImages[imageIndex];
                final bool isSelected = imageIndex == selectedIndex;
                return GestureDetector(
                  onTap: () => onSelect(imageIndex),
                  onLongPress: () => onThumbnailLongPress(imageIndex),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Container(
                        width: _EventCleanupEvidenceScreenState._thumbSize,
                        height: _EventCleanupEvidenceScreenState._thumbSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryDark
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image(
                            image: path.startsWith('assets/')
                                ? AssetImage(path) as ImageProvider
                                : FileImage(File(path)),
                            fit: BoxFit.cover,
                            errorBuilder: (BuildContext context, Object error,
                                StackTrace? stackTrace) {
                              return Container(
                                color: AppColors.inputFill,
                                child: const Icon(
                                  CupertinoIcons.photo,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Semantics(
                          button: true,
                          label: 'Remove photo',
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(24, 24),
                            onPressed: () => onRemove(imageIndex),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.panelBackground,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.12),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.minus_circle_fill,
                                size: 20,
                                color: AppColors.accentDanger,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotosEmptyState extends StatefulWidget {
  const _AddPhotosEmptyState({
    required this.maxImages,
    required this.onTap,
    required this.textTheme,
  });

  final int maxImages;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  State<_AddPhotosEmptyState> createState() => _AddPhotosEmptyStateState();
}

class _AddPhotosEmptyStateState extends State<_AddPhotosEmptyState>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = widget.textTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: FadeTransition(
        opacity: _pulseAnimation,
        child: AnimatedContainer(
        duration: AppMotion.xFast,
        curve: AppMotion.emphasized,
        transform: Matrix4.diagonal3Values(
          _pressed ? 0.98 : 1.0,
          _pressed ? 0.98 : 1.0,
          1.0,
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.primary.withValues(alpha: 0.45),
            borderRadius: 20,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.photo_on_rectangle,
                      size: 32,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Add photos of the cleaned site',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Up to ${widget.maxImages} photos',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.touch_app_rounded,
                        size: 14,
                        color: AppColors.primaryDark.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to select from gallery',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ),
      ),
      ),
    );
  }
}

class _CleanupFullscreenGalleryPage extends StatelessWidget {
  const _CleanupFullscreenGalleryPage({
    required this.imagePaths,
    required this.initialIndex,
  });

  final List<String> imagePaths;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: PageController(initialPage: initialIndex.clamp(0, imagePaths.length - 1)),
            itemCount: imagePaths.length,
            itemBuilder: (BuildContext context, int index) {
              final String path = imagePaths[index];
              final ImageProvider provider = path.startsWith('assets/')
                  ? AssetImage(path)
                  : FileImage(File(path)) as ImageProvider;
              return InteractiveViewer(
                child: Center(
                  child: Image(
                    image: provider,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
                      return const Icon(
                        CupertinoIcons.photo,
                        size: 48,
                        color: Colors.white54,
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                  color: Colors.white,
                  iconSize: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  final Color color;
  final double borderRadius;
  static const double _dashWidth = 6.0;
  static const double _dashGap = 4.0;
  static const double _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rRect);
    final List<ui.PathMetric> metrics = path.computeMetrics().toList();
    for (final ui.PathMetric metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double end =
            (distance + _dashWidth).clamp(0, metric.length).toDouble();
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance += _dashWidth + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      borderRadius != oldDelegate.borderRadius;
}
