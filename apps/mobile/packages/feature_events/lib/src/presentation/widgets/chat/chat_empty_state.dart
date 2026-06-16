import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';

class ChatEmptyState extends StatefulWidget {
  const ChatEmptyState({super.key, this.onSayHello});

  final VoidCallback? onSayHello;

  @override
  State<ChatEmptyState> createState() => _ChatEmptyStateState();
}

class _ChatEmptyStateState extends State<ChatEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 0.5;
    } else {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? child) {
        final double s = 1.0 + _pulse.value * 0.04;
        return Transform.scale(scale: s, child: child);
      },
      child: const AppEmptyStateIcon(
        icon: CupertinoIcons.bubble_left_bubble_right,
      ),
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            const SizedBox(height: AppSpacing.lg),
            AppText.emptyTitle(
              context.l10n.eventChatEmptyTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText.emptySubtitle(
              context.l10n.eventChatEmptyBody,
              textAlign: TextAlign.center,
            ),
            if (widget.onSayHello != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppButton.secondary(
                label: context.l10n.eventChatEmptySayHello,
                onPressed: widget.onSayHello,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
