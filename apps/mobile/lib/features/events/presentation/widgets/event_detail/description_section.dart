import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class DescriptionSection extends StatefulWidget {
  const DescriptionSection({super.key, required this.event});

  final EcoEvent event;

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  static const int _collapsedMaxLines = 4;
  bool _expanded = false;
  bool _needsExpansion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkOverflow();
  }

  void _checkOverflow() {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: widget.event.description,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      maxLines: _collapsedMaxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - AppSpacing.lg * 2);

    final bool overflows = tp.didExceedMaxLines;
    if (overflows != _needsExpansion) {
      setState(() => _needsExpansion = overflows);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'About',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.radiusSm),
        AnimatedCrossFade(
          duration: AppMotion.fast,
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Text(
            widget.event.description,
            maxLines: _collapsedMaxLines,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          secondChild: Text(
            widget.event.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
        if (_needsExpansion)
          GestureDetector(
            onTap: () {
              AppHaptics.light();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
