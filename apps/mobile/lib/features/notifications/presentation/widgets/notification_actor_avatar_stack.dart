import 'package:cached_network_image/cached_network_image.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/notifications/domain/models/notification_actor.dart';
import 'package:flutter/material.dart';

/// Overlapping actor avatars (Instagram / iOS style), up to [maxVisible] + overflow badge.
class NotificationActorAvatarStack extends StatelessWidget {
  const NotificationActorAvatarStack({
    super.key,
    required this.actors,
    this.size = 28,
    this.maxVisible = 3,
    this.overflowCount = 0,
  });

  final List<NotificationActor> actors;
  final double size;
  final int maxVisible;
  final int overflowCount;

  static const double _overlap = 10;

  @override
  Widget build(BuildContext context) {
    final List<NotificationActor> visible =
        actors.take(maxVisible).toList(growable: false);
    if (visible.isEmpty) {
      return SizedBox(width: size, height: size);
    }
    final int extra = overflowCount > 0
        ? overflowCount
        : (actors.length > maxVisible ? actors.length - maxVisible : 0);
    final int slotCount = visible.length + (extra > 0 ? 1 : 0);
    final double width = size + (slotCount - 1) * (size - _overlap);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * (size - _overlap),
              child: _AvatarRing(
                size: size,
                actor: visible[i],
              ),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * (size - _overlap),
              child: _OverflowBadge(size: size, count: extra),
            ),
        ],
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.size, required this.actor});

  final double size;
  final NotificationActor actor;

  @override
  Widget build(BuildContext context) {
    final String initials = _initials(actor.displayName);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.appBackground, width: 2),
      ),
      child: ClipOval(
        child: actor.avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: actor.avatarUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                placeholder: (_, _) => _InitialsFallback(initials: initials),
                errorWidget: (_, _, _) =>
                    _InitialsFallback(initials: initials),
              )
            : _InitialsFallback(initials: initials),
      ),
    );
  }

  static String _initials(String name) {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.inputFill,
      child: Center(
        child: Text(
          initials,
          style: AppTypography.microLabel.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({required this.size, required this.count});

  final double size;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textMuted,
        border: Border.all(color: AppColors.appBackground, width: 2),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: AppColors.appBackground,
        ),
      ),
    );
  }
}
