import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';

/// iOS-style bounce vs Android clamping for the chat message list.
class EventChatScrollBehavior extends MaterialScrollBehavior {
  const EventChatScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.iOS => const BouncingScrollPhysics(),
      _ => const ClampingScrollPhysics(),
    };
  }
}

/// Typing indicator entry keyed by user id.
class EventChatTypingPeer {
  EventChatTypingPeer({required this.displayName, required this.until});

  final String displayName;
  final DateTime until;
}

class EventChatScrollToBottomFab extends StatefulWidget {
  const EventChatScrollToBottomFab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<EventChatScrollToBottomFab> createState() => _EventChatScrollToBottomFabState();
}

class _EventChatScrollToBottomFabState extends State<EventChatScrollToBottomFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.standard);
    _curve = CurvedAnimation(parent: _controller, curve: AppMotion.smooth);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.82, end: 1).animate(_curve),
      child: FadeTransition(
        opacity: _curve,
        child: Material(
          color: AppColors.panelBackground,
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: AppColors.shadowLight,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
