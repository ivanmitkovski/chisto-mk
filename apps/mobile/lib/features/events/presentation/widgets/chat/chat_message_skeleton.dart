import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/chat/chat_theme.dart';

class ChatMessageSkeleton extends StatefulWidget {
  const ChatMessageSkeleton({super.key, this.alignEnd = false, this.widthFraction = 0.6});

  final bool alignEnd;
  final double widthFraction;

  @override
  State<ChatMessageSkeleton> createState() => _ChatMessageSkeletonState();
}

class _ChatMessageSkeletonState extends State<ChatMessageSkeleton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _shimmer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: AppMotion.standard);
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 0.5;
      _shimmer.value = 0;
    } else {
      _pulse.repeat(reverse: true);
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Align(
        alignment: widget.alignEnd
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_pulse, _shimmer]),
          builder: (BuildContext context, Widget? child) {
            final double t = _pulse.value;
            final Color base = AppColors.inputFill.withValues(alpha: 0.72);
            final Color pulse = AppColors.inputFill;
            final double s = _shimmer.value;
            return Container(
              width: MediaQuery.sizeOf(context).width * widget.widthFraction,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: ChatTheme.bubbleRadiusSymmetric,
                gradient: LinearGradient(
                  begin: Alignment(-1.1 + 2.2 * s, 0),
                  end: Alignment(-0.1 + 2.2 * s, 0),
                  colors: <Color>[
                    Color.lerp(base, pulse, t)!,
                    Color.lerp(base, pulse, t * 0.92)!.withValues(alpha: 0.95),
                    Color.lerp(base, pulse, t)!,
                  ],
                  stops: const <double>[0.35, 0.5, 0.65],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChatMessageSkeletonList extends StatelessWidget {
  const ChatMessageSkeletonList({super.key});

  static const List<_SkeletonRow> _rows = <_SkeletonRow>[
    _SkeletonRow(alignEnd: false, widthFraction: 0.55),
    _SkeletonRow(alignEnd: true, widthFraction: 0.70),
    _SkeletonRow(alignEnd: false, widthFraction: 0.45),
    _SkeletonRow(alignEnd: true, widthFraction: 0.65),
    _SkeletonRow(alignEnd: false, widthFraction: 0.50),
    _SkeletonRow(alignEnd: true, widthFraction: 0.58),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      children: <Widget>[
        for (final _SkeletonRow r in _rows)
          ChatMessageSkeleton(alignEnd: r.alignEnd, widthFraction: r.widthFraction),
      ],
    );
  }
}

class _SkeletonRow {
  const _SkeletonRow({required this.alignEnd, required this.widthFraction});
  final bool alignEnd;
  final double widthFraction;
}
