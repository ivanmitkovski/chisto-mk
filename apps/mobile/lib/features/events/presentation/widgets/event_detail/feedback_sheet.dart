import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

class FeedbackSheetContent extends StatefulWidget {
  const FeedbackSheetContent({
    super.key,
    required this.event,
    this.current,
  });

  final EcoEvent event;
  final EventFeedbackSnapshot? current;

  @override
  State<FeedbackSheetContent> createState() => _FeedbackSheetContentState();
}

class _FeedbackSheetContentState extends State<FeedbackSheetContent> {
  late final TextEditingController _notesController;
  late int _rating;
  late int _bags;
  late double _hours;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.current?.notes ?? '');
    _rating = widget.current?.rating ?? 5;
    _bags = widget.current?.bagsCollected ?? 3;
    _hours = widget.current?.volunteerHours ?? 2;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: AppSpacing.sheetHandle,
                  height: AppSpacing.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Post-event feedback',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.event.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'How was the event?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                children: List<Widget>.generate(5, (int index) {
                  final int v = index + 1;
                  return ChoiceChip(
                    selected: _rating == v,
                    label: Text('$v★'),
                    onSelected: (_) => setState(() => _rating = v),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Bags collected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: _bags > 0 ? () => setState(() => _bags -= 1) : null,
                    icon: const Icon(CupertinoIcons.minus_circle),
                  ),
                  Text(
                    '$_bags',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  IconButton(
                    onPressed: () => setState(() => _bags += 1),
                    icon: const Icon(CupertinoIcons.plus_circle),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Volunteer hours: ${_hours.toStringAsFixed(1)}h',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Slider(
                value: _hours,
                min: 0.5,
                max: 12,
                divisions: 23,
                onChanged: (double value) => setState(() => _hours = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'What worked well? Any notes for next time?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      EventFeedbackSnapshot(
                        eventId: widget.event.id,
                        rating: _rating,
                        bagsCollected: _bags,
                        volunteerHours: _hours,
                        notes: _notesController.text.trim(),
                        createdAt: DateTime.now(),
                      ),
                    );
                  },
                  child: const Text('Save impact summary'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
