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
  });

  final int unreadCount;
  final VoidCallback onTap;

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
    return Semantics(
      button: true,
      label: hasUnread
          ? context.l10n.feedNotificationBellUnreadSemantic(widget.unreadCount)
          : context.l10n.feedNotificationBellAllReadSemantic,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 46,
          height: 46,
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
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.all(1),
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
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.notificationBing,
                    width: 21,
                    height: 21,
                    colorFilter: ColorFilter.mode(
                      hasUnread ? AppColors.accentDanger : AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              if (hasUnread)
                Positioned(
                  top: -2,
                  right: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentDanger,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(
                          color: AppColors.panelBackground, width: 1.5),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.accentDanger.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.unreadCount > 9 ? '9+' : '${widget.unreadCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textOnDark,
                              fontSize: 10,
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
