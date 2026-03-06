import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/assets/app_assets.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TakeActionBottomSheet extends StatefulWidget {
  const TakeActionBottomSheet({super.key});

  @override
  State<TakeActionBottomSheet> createState() => _TakeActionBottomSheetState();
}

class _TakeActionBottomSheetState extends State<TakeActionBottomSheet> {
  static const List<String> _options = <String>[
    'Create Eco Action',
    'Join Action',
    'Donate / Contribute',
    'Report Issue',
    'Share Site',
  ];

  String _selected = _options.first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SvgPicture.asset(
            AppAssets.takeActionDrawing,
            height: 160,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Take action',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Choose one action',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildDropdown(context),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Continue',
            onPressed: () {
              // TODO: Wire up navigation per action type.
              Navigator.of(context).pop(_selected);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selected,
          borderRadius: BorderRadius.circular(24),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: Theme.of(context).textTheme.bodyMedium,
          items: _options
              .map(
                (String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (value == _selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (String? value) {
            if (value == null) return;
            setState(() {
              _selected = value;
            });
          },
        ),
      ),
    );
  }
}

