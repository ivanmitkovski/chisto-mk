import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/event_chat_haptics.dart';

/// Drag left to reply (Messages-style affordance) with spring release.
class ChatSwipeReplyWrapper extends StatefulWidget {
  const ChatSwipeReplyWrapper({
    super.key,
    required this.child,
    required this.enabled,
    this.onReply,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onReply;

  @override
  State<ChatSwipeReplyWrapper> createState() => _ChatSwipeReplyWrapperState();
}

class _ChatSwipeReplyWrapperState extends State<ChatSwipeReplyWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spring;
  double _dx = 0;
  bool _armed = false;
  bool _animating = false;

  static const double _trigger = 56;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController.unbounded(vsync: this);
    _spring.addListener(() {
      if (_animating) {
        setState(() => _dx = _spring.value);
      }
    });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _releaseSpring({required bool reduceMotion}) {
    if (reduceMotion) {
      setState(() {
        _dx = 0;
        _animating = false;
      });
      return;
    }
    _animating = true;
    _spring.value = _dx;
    _spring
        .animateWith(SpringSimulation(AppMotion.snappySpring, _dx, 0, 0))
        .whenComplete(() {
      if (mounted) setState(() => _animating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.onReply == null) {
      return widget.child;
    }
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Allow overshoot past [_trigger] so when motion is reduced (clamp max = -_trigger)
    // release still fires reply — strict `< -_trigger` would never succeed.
    final double maxPull = reduceMotion ? _trigger * 1.05 : _trigger * 1.2;
    final double armAt = reduceMotion ? 20 : 28;
    final double progress = (-_dx / _trigger).clamp(0.0, 1.0);
    return GestureDetector(
      onHorizontalDragUpdate: (DragUpdateDetails d) {
        final double next = (_dx + d.delta.dx).clamp(-maxPull, 0.0);
        if (next != _dx) setState(() => _dx = next);
        if (!_armed && _dx < -armAt) {
          _armed = true;
          EventChatHaptics.swipeReplyThreshold(context);
        }
      },
      onHorizontalDragEnd: (_) {
        if (_dx <= -_trigger) widget.onReply?.call();
        _armed = false;
        _releaseSpring(reduceMotion: reduceMotion);
      },
      onHorizontalDragCancel: () {
        _armed = false;
        _releaseSpring(reduceMotion: reduceMotion);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.7 + 0.3 * progress,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Semantics(
                      label: context.l10n.eventChatSwipeReplySemantic,
                      child: Icon(
                        Icons.reply_rounded,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}
