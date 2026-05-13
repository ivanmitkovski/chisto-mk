import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class AppAvatar extends StatefulWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size = AppSpacing.avatarMd,
    this.fontSize,
    this.imageUrl,
    this.localImagePath,
  });

  final String name;
  final double size;
  final double? fontSize;
  final String? imageUrl;

  /// On-device image (e.g. pending avatar upload). Takes precedence over [imageUrl].
  final String? localImagePath;

  @override
  State<AppAvatar> createState() => _AppAvatarState();
}

class _AppAvatarState extends State<AppAvatar> {
  Future<bool>? _localFileExists;
  int _networkLoadAttempt = 0;
  static const int _maxNetworkRetries = 2;
  static const Duration _networkRetryDelay = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    _localFileExists = _checkLocalFile(widget.localImagePath);
  }

  @override
  void didUpdateWidget(covariant AppAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localImagePath != widget.localImagePath) {
      _localFileExists = _checkLocalFile(widget.localImagePath);
    }
    final String? oldUrl = oldWidget.imageUrl?.trim();
    final String? newUrl = widget.imageUrl?.trim();
    if (oldUrl != newUrl) {
      _networkLoadAttempt = 0;
    }
  }

  Future<bool> _checkLocalFile(String? rawPath) async {
    final String? path = rawPath?.trim();
    if (path == null || path.isEmpty) return false;
    return File(path).exists();
  }

  @override
  Widget build(BuildContext context) {
    final String initials = _initials(widget.name);
    final String? path = widget.localImagePath?.trim();
    if (path != null && path.isNotEmpty) {
      return FutureBuilder<bool>(
        future: _localFileExists,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.data == true) {
            return ClipOval(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _InitialsCircle(
                    initials: initials,
                    size: widget.size,
                    fontSize: widget.fontSize,
                  ),
                ),
              ),
            );
          }
          return _buildRemoteOrFallback(initials);
        },
      );
    }
    return _buildRemoteOrFallback(initials);
  }

  Widget _buildRemoteOrFallback(String initials) {
    final String? rawUrl = widget.imageUrl?.trim();
    if (rawUrl != null && rawUrl.isNotEmpty) {
      final int cacheDim = (widget.size * 3).round().clamp(72, 256);
      return ClipOval(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CachedNetworkImage(
            imageUrl: rawUrl,
            key: ValueKey<String>('avatar_net|$_networkLoadAttempt|$rawUrl'),
            fit: BoxFit.cover,
            memCacheWidth: cacheDim,
            memCacheHeight: cacheDim,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (BuildContext context, String url) => _InitialsCircle(
              initials: initials,
              size: widget.size,
              fontSize: widget.fontSize,
              showLoadingRing: true,
            ),
            errorWidget: (BuildContext context, String url, Object error) {
              if (_networkLoadAttempt < _maxNetworkRetries) {
                Future<void>.delayed(_networkRetryDelay, () {
                  if (!mounted) return;
                  final String? still = widget.imageUrl?.trim();
                  if (still == rawUrl) {
                    setState(() => _networkLoadAttempt += 1);
                  }
                });
                return _InitialsCircle(
                  initials: initials,
                  size: widget.size,
                  fontSize: widget.fontSize,
                  showLoadingRing: true,
                );
              }
              return _InitialsCircle(
                initials: initials,
                size: widget.size,
                fontSize: widget.fontSize,
              );
            },
          ),
        ),
      );
    }

    return _InitialsCircle(
      initials: initials,
      size: widget.size,
      fontSize: widget.fontSize,
    );
  }

  static String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({
    required this.initials,
    required this.size,
    this.fontSize,
    this.showLoadingRing = false,
  });

  final String initials;
  final double size;
  final double? fontSize;
  final bool showLoadingRing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: fontSize ?? size * 0.38,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (showLoadingRing)
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size * 0.06,
              color: AppColors.white.withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }
}
