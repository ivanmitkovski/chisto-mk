import 'dart:math' as math;

import 'package:chisto_mobile/core/cache/image_cache_diagnostics.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppSmartImageDecodePreset { auto, feed, fullQuality }

class AppSmartImage extends StatefulWidget {
  const AppSmartImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.decodePreset = AppSmartImageDecodePreset.auto,
    this.maxDecodeWidth,
    this.maxDecodeHeight,
    this.enableRetry = true,
  });

  final ImageProvider image;
  final BoxFit fit;
  final String? semanticLabel;
  final AppSmartImageDecodePreset decodePreset;
  final int? maxDecodeWidth;
  final int? maxDecodeHeight;
  final bool enableRetry;

  @override
  State<AppSmartImage> createState() => _AppSmartImageState();
}

class _AppSmartImageState extends State<AppSmartImage> {
  int _imageVersion = 0;
  int _errorCount = 0;
  DateTime? _nextRetryAt;
  int _lastRenderStartVersion = -1;
  int _lastRenderSuccessVersion = -1;
  int _lastRenderErrorVersion = -1;

  @override
  void initState() {
    super.initState();
    _recordRenderStart();
  }

  @override
  void didUpdateWidget(covariant AppSmartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _imageVersion = 0;
      _errorCount = 0;
      _nextRetryAt = null;
      _lastRenderStartVersion = -1;
      _lastRenderSuccessVersion = -1;
      _lastRenderErrorVersion = -1;
      _recordRenderStart();
    }
  }

  void _recordRenderStart() {
    if (_lastRenderStartVersion == _imageVersion) return;
    _lastRenderStartVersion = _imageVersion;
    ImageCacheDiagnostics.recordRenderStart();
  }

  void _recordRenderSuccess() {
    if (_lastRenderSuccessVersion == _imageVersion) return;
    _lastRenderSuccessVersion = _imageVersion;
    ImageCacheDiagnostics.recordRenderSuccess();
  }

  void _recordRenderError() {
    if (_lastRenderErrorVersion == _imageVersion) return;
    _lastRenderErrorVersion = _imageVersion;
    ImageCacheDiagnostics.recordRenderError();
    final int clamped = math.min(_errorCount, 4);
    final int seconds = 1 << clamped;
    _nextRetryAt = DateTime.now().add(Duration(seconds: seconds));
  }

  bool _canRetryNow() {
    final DateTime? nextRetryAt = _nextRetryAt;
    return nextRetryAt == null || !DateTime.now().isBefore(nextRetryAt);
  }

  void _retry() {
    if (!widget.enableRetry || !_canRetryNow()) return;
    setState(() {
      _errorCount += 1;
      _imageVersion += 1;
      _nextRetryAt = null;
      _lastRenderStartVersion = -1;
      _lastRenderSuccessVersion = -1;
      _lastRenderErrorVersion = -1;
    });
    ImageCacheDiagnostics.recordRetry();
    _recordRenderStart();
  }

  ImageProvider _resolveImageProvider(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (widget.decodePreset == AppSmartImageDecodePreset.fullQuality) {
      return widget.image;
    }

    // Keep default rendering path untouched unless we explicitly opt into
    // feed decode sizing. This avoids unintended visual regressions.
    if (widget.decodePreset != AppSmartImageDecodePreset.feed &&
        widget.maxDecodeWidth == null &&
        widget.maxDecodeHeight == null) {
      return widget.image;
    }

    final double width = constraints.maxWidth;
    if (!width.isFinite || width <= 0) {
      return widget.image;
    }
    final double dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final double decodeScale = dpr.clamp(1.0, 2.5);
    const int feedMaxWidth = 1280;

    final int decodeWidth = math.max(
      1,
      math.min(
        widget.maxDecodeWidth ?? feedMaxWidth,
        (width * decodeScale).round(),
      ),
    );

    // Prefer width-based downsampling for feed to preserve intrinsic aspect ratio.
    final int? decodeHeight = widget.maxDecodeHeight;
    return ResizeImage.resizeIfNeeded(decodeWidth, decodeHeight, widget.image);
  }

  Widget _buildError(BuildContext context) {
    _recordRenderError();
    final bool canRetry = _canRetryNow();
    final int secondsLeft = _nextRetryAt == null
        ? 0
        : math.max(1, _nextRetryAt!.difference(DateTime.now()).inSeconds);
    return ColoredBox(
      color: AppColors.inputFill,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textMuted,
              size: AppSpacing.iconLg,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              context.l10n.appSmartImageUnavailable,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
            ),
            if (widget.enableRetry) ...<Widget>[
              const SizedBox(height: AppSpacing.xxs),
              TextButton(
                onPressed: canRetry ? _retry : null,
                child: Text(
                  canRetry
                      ? context.l10n.appSmartImageRetry
                      : context.l10n.appSmartImageRetryIn(secondsLeft),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ImageProvider resolved = _resolveImageProvider(
          context,
          constraints,
        );
        return DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.inputFill),
          child: Image(
            key: ValueKey<int>(_imageVersion),
            image: resolved,
            fit: widget.fit,
            semanticLabel: widget.semanticLabel,
            frameBuilder:
                (
                  BuildContext context,
                  Widget child,
                  int? frame,
                  bool wasSynchronouslyLoaded,
                ) {
                  if (wasSynchronouslyLoaded) {
                    _recordRenderSuccess();
                    return child;
                  }
                  if (frame != null) {
                    _recordRenderSuccess();
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      AnimatedOpacity(
                        opacity: frame == null ? 1 : 0,
                        duration: AppMotion.fast,
                        curve: Curves.easeOutCubic,
                        child: Container(
                          color: AppColors.inputFill,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: AppMotion.medium,
                        curve: AppMotion.emphasized,
                        child: child,
                      ),
                    ],
                  );
                },
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
                  return _buildError(context);
                },
          ),
        );
      },
    );
  }
}
