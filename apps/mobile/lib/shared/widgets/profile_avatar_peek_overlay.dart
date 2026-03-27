import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:flutter/material.dart';

/// Instagram-style press-and-hold fullscreen peek for a profile photo.
class ProfileAvatarPeek {
  ProfileAvatarPeek._();

  static OverlayEntry? _entry;

  /// Shows a circular zoomed preview. Dismisses on pointer up/cancel over the overlay.
  /// No-op if a peek is already visible.
  static void show(
    BuildContext context, {
    required ImageProvider image,
    String? semanticLabel,
  }) {
    if (_entry != null) return;
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext context) {
        return _ProfileAvatarPeekLayer(
          image: image,
          semanticLabel: semanticLabel,
          onRemove: () {
            if (_entry == entry) {
              entry.remove();
              _entry = null;
            }
          },
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// Removes any active peek immediately (e.g. route popped while holding).
  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _ProfileAvatarPeekLayer extends StatefulWidget {
  const _ProfileAvatarPeekLayer({
    required this.image,
    required this.onRemove,
    this.semanticLabel,
  });

  final ImageProvider image;
  final VoidCallback onRemove;
  final String? semanticLabel;

  @override
  State<_ProfileAvatarPeekLayer> createState() =>
      _ProfileAvatarPeekLayerState();
}

class _ProfileAvatarPeekLayerState extends State<_ProfileAvatarPeekLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
      reverseDuration: AppMotion.fast,
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.smooth,
      reverseCurve: AppMotion.sharpDecelerate.flipped,
    );
    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppMotion.smooth,
        reverseCurve: AppMotion.sharpDecelerate.flipped,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppHaptics.softTransition();
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _controller.reverse();
    if (!mounted) return;
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double diameter =
        (mq.size.width - AppSpacing.xl * 2).clamp(0.0, 340.0);
    final String a11yLabel = widget.semanticLabel?.trim().isNotEmpty == true
        ? widget.semanticLabel!.trim()
        : 'Profile photo';

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (_) => _dismiss(),
      onPointerCancel: (_) => _dismiss(),
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: AppColors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ColoredBox(color: AppColors.black.withValues(alpha: 0.55)),
              SafeArea(
                child: Center(
                  child: ScaleTransition(
                    scale: _scale,
                    child: Semantics(
                      image: true,
                      label: a11yLabel,
                      child: Container(
                        width: diameter,
                        height: diameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.35),
                            width: 2,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.35),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image(
                            image: widget.image,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            gaplessPlayback: true,
                            errorBuilder: (BuildContext context, Object error,
                                    StackTrace? stackTrace) =>
                                ColoredBox(
                                  color: AppColors.inputFill,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: diameter * 0.2,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
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
