import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FeedNotificationBell extends StatefulWidget {
  const FeedNotificationBell({
    super.key,
    required this.unreadCount,
    required this.onTap,
    this.size = 46,
  }) : assert(size >= 28 && size <= 56, 'size must be between 28 and 56');

  final int unreadCount;
  final VoidCallback onTap;

  /// Outer hit target / layout size. Default 46 matches the full feed header.
  final double size;

  @override
  State<FeedNotificationBell> createState() => _FeedNotificationBellState();
}

class _FeedNotificationBellState extends State<FeedNotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.unreadCount > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant FeedNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unreadCount == 0 && widget.unreadCount > 0) {
      _pulseController.repeat(reverse: true);
    } else if (oldWidget.unreadCount > 0 && widget.unreadCount == 0) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = widget.unreadCount > 0;
    final double box = widget.size;
    final double m = box / 46.0;
    final double margin = 1 * m;
    final double inner = (box - 2 * margin).clamp(20.0, 52.0);
    final double icon = (21 * m).clamp(14.0, 24.0);
    final double badgeTop = -2 * m;
    final double badgeRight = -3 * m;
    final double badgeMinWidth = (18 * m).clamp(14.0, 20.0);
    final double badgeHeight = (18 * m).clamp(14.0, 20.0);
    final double badgeFont = (10 * m).clamp(8.0, 11.0);
    final double badgeHPad = (4 * m).clamp(3.0, 6.0);
    return Semantics(
      button: true,
      label: hasUnread
          ? context.l10n.feedNotificationBellUnreadSemantic(widget.unreadCount)
          : context.l10n.feedNotificationBellAllReadSemantic,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: box,
          height: box,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              if (hasUnread)
                Positioned.fill(
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.12, end: 0.28).animate(
                      CurvedAnimation(
                        parent: _pulseController,
                        curve: AppMotion.decelerate,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentDanger.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Container(
                  width: inner,
                  height: inner,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: hasUnread
                          ? <Color>[
                              AppColors.white,
                              AppColors.accentDanger.withValues(alpha: 0.04),
                            ]
                          : <Color>[
                              AppColors.white,
                              AppColors.inputFill,
                            ],
                    ),
                    border: Border.all(
                      color: hasUnread
                          ? AppColors.accentDanger.withValues(alpha: 0.22)
                          : AppColors.divider,
                      width: 1,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 10 * m,
                        offset: Offset(0, 3 * m),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppAssets.notificationBing,
                      width: icon,
                      height: icon,
                      colorFilter: ColorFilter.mode(
                        hasUnread
                            ? AppColors.accentDanger
                            : AppColors.textPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              if (hasUnread)
                Positioned(
                  top: badgeTop,
                  right: badgeRight,
                  child: Container(
                    constraints: BoxConstraints(minWidth: badgeMinWidth),
                    height: badgeHeight,
                    padding: EdgeInsets.symmetric(horizontal: badgeHPad),
                    decoration: BoxDecoration(
                      color: AppColors.accentDanger,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(
                        color: AppColors.panelBackground,
                        width: 1.5,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color:
                              AppColors.accentDanger.withValues(alpha: 0.35),
                          blurRadius: 8 * m,
                          offset: Offset(0, 2 * m),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.unreadCount > 9 ? '9+' : '${widget.unreadCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textOnDark,
                              fontSize: badgeFont,
                              fontWeight: FontWeight.w700,
                              height: 1,
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
