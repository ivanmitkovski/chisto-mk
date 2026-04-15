import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

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

  void _submit() {
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
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.eventsFeedbackHowWasEvent,
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
                label: Text(context.l10n.eventsFeedbackRatingStars(v)),
                onSelected: (_) => setState(() => _rating = v),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.eventsFeedbackBagsCollected,
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
            context.l10n.eventsFeedbackVolunteerHours(_hours.toStringAsFixed(1)),
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
            decoration: InputDecoration(
              hintText: context.l10n.eventsFeedbackNotesHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: context.l10n.eventsSaveImpactSummary,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
