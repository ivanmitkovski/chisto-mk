import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/notifications/notification_swipe_action_pane.dart';
import 'package:feature_home/src/presentation/widgets/notifications/notification_tile.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter/material.dart';

/// Horizontally swipeable notification row with flush action strips (no corner gap).
class NotificationSwipeCard extends StatefulWidget {
  const NotificationSwipeCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onSwipeMarkRead,
    required this.onSwipeArchive,
    required this.markReadIcon,
    required this.markReadSemanticLabel,
    required this.archiveIcon,
    required this.archiveSemanticLabel,
    required this.markReadColor,
    required this.archiveColor,
    this.groupCount = 1,
  });

  final UserNotification item;
  final VoidCallback onTap;
  final Future<void> Function() onSwipeMarkRead;
  final Future<void> Function() onSwipeArchive;
  final IconData markReadIcon;
  final String markReadSemanticLabel;
  final IconData archiveIcon;
  final String archiveSemanticLabel;
  final Color markReadColor;
  final Color archiveColor;
  final int groupCount;

  static final BorderRadius borderRadius = BorderRadius.circular(
    AppSpacing.radius18,
  );

  @override
  State<NotificationSwipeCard> createState() => _NotificationSwipeCardState();
}

class _NotificationSwipeCardState extends State<NotificationSwipeCard>
    with SingleTickerProviderStateMixin {
  static const double _maxReveal = 56;
  static const double _triggerThreshold = 40;
  static const double _velocityTrigger = 520;

  /// Underlap so the tile border does not show a hairline against the strip.
  static const double _stripOverlap = 1;

  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: AppMotion.fast)
      ..addListener(_onSnapTick);
  }

  void _onSnapTick() {
    final Animation<double>? animation = _snapAnimation;
    if (animation == null) return;
    setState(() => _dragOffset = animation.value);
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _snapController.stop();
    _snapAnimation = null;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(
        -_maxReveal,
        _maxReveal,
      );
    });
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final double velocity = details.primaryVelocity ?? 0;
    final bool commitRead =
        _dragOffset > 0 &&
        (_dragOffset >= _triggerThreshold || velocity > _velocityTrigger);
    final bool commitArchive =
        _dragOffset < 0 &&
        (_dragOffset <= -_triggerThreshold || velocity < -_velocityTrigger);

    if (commitRead) {
      AppHaptics.light();
      await widget.onSwipeMarkRead();
    } else if (commitArchive) {
      AppHaptics.light();
      await widget.onSwipeArchive();
    }
    if (!mounted) return;
    _animateTo(0);
  }

  void _animateTo(double target) {
    _snapAnimation = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: AppMotion.standardCurve),
    );
    _snapController
      ..value = 0
      ..forward();
  }

  BorderRadius _tileBorderRadius() {
    final BorderRadius outer = NotificationSwipeCard.borderRadius;
    if (_dragOffset > 0) {
      return BorderRadius.only(
        topRight: outer.topRight,
        bottomRight: outer.bottomRight,
      );
    }
    if (_dragOffset < 0) {
      return BorderRadius.only(
        topLeft: outer.topLeft,
        bottomLeft: outer.bottomLeft,
      );
    }
    return outer;
  }

  @override
  Widget build(BuildContext context) {
    final double leftReveal = _dragOffset.clamp(0, _maxReveal);
    final double rightReveal = (-_dragOffset).clamp(0, _maxReveal);
    final BorderRadius outer = NotificationSwipeCard.borderRadius;
    final BorderRadius leftStripRadius = BorderRadius.only(
      topLeft: outer.topLeft,
      bottomLeft: outer.bottomLeft,
    );
    final BorderRadius rightStripRadius = BorderRadius.only(
      topRight: outer.topRight,
      bottomRight: outer.bottomRight,
    );

    return ClipRRect(
      borderRadius: outer,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double rowWidth = constraints.maxWidth;
          final double leftStripWidth = leftReveal > 0
              ? leftReveal + _stripOverlap
              : 0;
          final double rightStripWidth = rightReveal > 0
              ? rightReveal + _stripOverlap
              : 0;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              if (leftStripWidth > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: leftStripWidth,
                  child: NotificationSwipeActionPane(
                    icon: widget.markReadIcon,
                    semanticLabel: widget.markReadSemanticLabel,
                    color: widget.markReadColor,
                    borderRadius: leftStripRadius,
                  ),
                ),
              if (rightStripWidth > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: rightStripWidth,
                  child: NotificationSwipeActionPane(
                    icon: widget.archiveIcon,
                    semanticLabel: widget.archiveSemanticLabel,
                    color: widget.archiveColor,
                    borderRadius: rightStripRadius,
                  ),
                ),
              Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: SizedBox(
                  width: rowWidth,
                  child: GestureDetector(
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: _onDragEnd,
                    behavior: HitTestBehavior.opaque,
                    child: NotificationTile(
                      item: widget.item,
                      onTap: widget.onTap,
                      groupCount: widget.groupCount,
                      borderRadius: _tileBorderRadius(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
