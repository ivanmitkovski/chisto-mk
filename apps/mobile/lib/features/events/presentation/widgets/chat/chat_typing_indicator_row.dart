import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_theme.dart';
import 'package:chisto_mobile/shared/widgets/user_avatar_circle.dart';

/// Typing indicator that renders as a ghost peer bubble inside the message list.
class ChatTypingBubble extends StatelessWidget {
  const ChatTypingBubble({
    super.key,
    required this.displayNames,
    this.primaryUserId,
    this.primaryAvatarUrl,
  });

  final List<String> displayNames;

  /// User id of the peer shown first (same sort order as [displayNames]). Used for avatar seed + cache.
  final String? primaryUserId;

  /// Profile image URL for [primaryUserId] when known (e.g. from recent messages).
  final String? primaryAvatarUrl;

  @override
  Widget build(BuildContext context) {
    if (displayNames.isEmpty) return const SizedBox.shrink();
    final List<String> names = List<String>.from(displayNames)..sort();
    final String firstName = names.first;
    final String label;
    if (names.length == 1) {
      label = context.l10n.eventChatTypingOne(firstName);
    } else if (names.length == 2) {
      label = context.l10n.eventChatTypingTwo(names.first, names[1]);
    } else {
      label = context.l10n.eventChatTypingMany(names.first, names.length - 1);
    }

    return Semantics(
      label: label,
      excludeSemantics: false,
      child: AnimatedSize(
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _TypingAvatar(
                displayName: firstName,
                userId: primaryUserId,
                imageUrl: primaryAvatarUrl,
              ),
              const SizedBox(width: ChatTheme.avatarGap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: AppTypography.eventsChatTimestamp(Theme.of(context).textTheme),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: ChatTheme.bubblePeerFill,
                      borderRadius: ChatTheme.bubbleRadius(
                        own: false,
                        isFirstInGroup: true,
                        isLastInGroup: true,
                      ).resolve(Directionality.of(context)),
                      border: Border.all(
                        color: ChatTheme.bubblePeerBorder,
                        width: 0.5,
                      ),
                      boxShadow: ChatTheme.bubblePeerShadow,
                    ),
                    child: const ChatTypingDots(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingAvatar extends StatelessWidget {
  const _TypingAvatar({
    required this.displayName,
    this.userId,
    this.imageUrl,
  });

  final String displayName;
  final String? userId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return UserAvatarCircle(
      displayName: displayName,
      imageUrl: imageUrl,
      size: ChatTheme.avatarSize,
      seed: userId,
      fallbackStyle: UserAvatarFallbackStyle.softTint,
    );
  }
}

/// Kept as a backward-compatible alias.
class ChatTypingIndicatorRow extends StatelessWidget {
  const ChatTypingIndicatorRow({
    super.key,
    required this.displayNames,
    this.primaryUserId,
    this.primaryAvatarUrl,
  });

  final List<String> displayNames;
  final String? primaryUserId;
  final String? primaryAvatarUrl;

  @override
  Widget build(BuildContext context) => ChatTypingBubble(
        displayNames: displayNames,
        primaryUserId: primaryUserId,
        primaryAvatarUrl: primaryAvatarUrl,
      );
}

class ChatTypingDots extends StatefulWidget {
  const ChatTypingDots({super.key});

  @override
  State<ChatTypingDots> createState() => _ChatTypingDotsState();
}

class _ChatTypingDotsState extends State<ChatTypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.chatTypingCycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0.33;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[_dot(0.5), _gap, _dot(0.5), _gap, _dot(0.5)],
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = AppMotion.chatTypingPhaseCurve.transform(_controller.value);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _animDot(t, 0),
            _gap,
            _animDot(t, 1),
            _gap,
            _animDot(t, 2),
          ],
        );
      },
    );
  }

  Widget _animDot(double t, int index) {
    final double phase = (t * 3 - index) % 3;
    const double opLo = 0.46;
    const double opHi = 0.96;
    final double opacity = phase < 1.0
        ? opLo + (opHi - opLo) * phase
        : opHi - (opHi - opLo) * ((phase - 1) / 2).clamp(0.0, 1.0);
    final double scale = phase < 1.0
        ? 0.92 + 0.06 * phase
        : 1.0 - 0.05 * ((phase - 1) / 2).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: _dot(opacity),
    );
  }

  static const Widget _gap = SizedBox(width: 3);

  Widget _dot(double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
