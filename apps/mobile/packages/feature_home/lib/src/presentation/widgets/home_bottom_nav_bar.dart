import 'package:chisto_infrastructure/core/assets/app_assets.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.navItemKeys,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  /// One key per tab index (0–3), aligned with [index] on each [_BottomNavItem].
  final List<GlobalKey> navItemKeys;

  @override
  Widget build(BuildContext context) {
    final List<_NavItemConfig> items = <_NavItemConfig>[
      _NavItemConfig(
        label: context.l10n.homeShellNavHome,
        iconAsset: AppAssets.navHome,
      ),
      _NavItemConfig(
        label: context.l10n.homeShellNavReports,
        iconAsset: AppAssets.navReports,
      ),
      _NavItemConfig(
        label: context.l10n.homeShellNavMap,
        iconAsset: AppAssets.navMap,
      ),
      _NavItemConfig(
        label: context.l10n.homeShellNavEvents,
        iconAsset: AppAssets.navEvents,
      ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusCard),
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          boxShadow: AppShadows.bottomBarLift(Theme.of(context).colorScheme),
        ),
        child: Material(
          color: AppColors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              KeyedSubtree(
                key: navItemKeys[0],
                child: _BottomNavItem(
                  config: items[0],
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTabSelected,
                ),
              ),
              KeyedSubtree(
                key: navItemKeys[1],
                child: _BottomNavItem(
                  config: items[1],
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTabSelected,
                ),
              ),
              const SizedBox(width: 64),
              KeyedSubtree(
                key: navItemKeys[2],
                child: _BottomNavItem(
                  config: items[2],
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: onTabSelected,
                ),
              ),
              KeyedSubtree(
                key: navItemKeys[3],
                child: _BottomNavItem(
                  config: items[3],
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTabSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatefulWidget {
  const _BottomNavItem({
    required this.config,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final _NavItemConfig config;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> {
  bool _pressed = false;

  bool get _isSelected => widget.index == widget.currentIndex;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color color = _isSelected ? AppColors.primary : AppColors.textMuted;

    return Semantics(
      button: true,
      selected: _isSelected,
      label: widget.config.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          widget.onTap(widget.index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: AppMotion.xFast,
          curve: AppMotion.emphasized,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SvgPicture.asset(
                widget.config.iconAsset,
                width: 26,
                height: 26,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                widget.config.label,
                style: AppTypography.badgeLabel(textTheme).copyWith(
                  height: 1.1,
                  fontWeight: _isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemConfig {
  const _NavItemConfig({required this.label, required this.iconAsset});

  final String label;
  final String iconAsset;
}
