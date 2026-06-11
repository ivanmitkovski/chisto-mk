import 'dart:math' show max, min;

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/utils/civic_actor_display.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/attendee_list_sheet.dart';
import 'package:flutter/material.dart';

/// Overlapping avatar circles: uses [previews] from a light [fetchParticipants] peek
/// when available; falls back to organizer + letter placeholders if [previews] is null.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.count,
    required this.event,
    this.previews,
    this.isLoadingPeek = false,
  });

  final int count;
  final EcoEvent event;
  final List<AttendeePreview>? previews;
  final bool isLoadingPeek;

  static const double _size = 30;
  static const double _overlap = 9;
  static const double _borderW = 2;

  double _outer() => _size + 2 * _borderW;

  double _totalWidthForSlots(int slotCount) {
    if (slotCount <= 0) {
      return 0;
    }
    final double outer = _outer();
    return outer + (slotCount - 1) * (_size - _overlap);
  }

  Widget _ringedAvatar({required double left, required Widget child}) {
    final double outer = _outer();
    return Positioned(
      left: left,
      child: Container(
        width: outer,
        height: outer,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: _borderW),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final String organizerLabel = civicActorDisplayLabel(
      context.l10n,
      displayName: event.organizerName,
      isDeleted: event.organizerIsDeleted,
    );
    final String? organizerAvatar =
        event.organizerIsDeleted ? null : event.organizerAvatarUrl;

    const double size = _size;
    const double overlap = _overlap;
    final double outer = _outer();

    if (isLoadingPeek && (previews == null || previews!.isEmpty)) {
      return SizedBox(
        width: outer + (size - overlap) + 12,
        height: outer,
        child: Row(
          children: <Widget>[
            UserAvatarCircle(
              displayName: organizerLabel,
              imageUrl: organizerAvatar,
              size: size,
              seed: event.organizerId,
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 20,
              height: 20,
              child: AppLoadingIndicator(
                size: AppLoadingIndicatorSize.sm,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      );
    }

    if (previews != null && previews!.isNotEmpty) {
      final List<AttendeePreview> list = orderPreviewsForAvatarStack(previews!);
      final bool useOverflow = count > 3;
      // [participantCount] is joiners only (API); merge always prepends the organizer.
      // Use max(list.length, count) so "1 volunteer" + organizer still gets two face slots.
      // When /participants returns fewer rows than the event count (common), pad with
      // deterministic placeholder avatars so the stack matches the headline.
      final int targetFaceSlots = useOverflow
          ? 3
          : min(max(list.length, count), 4).clamp(1, 4);
      final int takeKnown = useOverflow
          ? min(3, list.length)
          : min(targetFaceSlots, list.length);
      final List<AttendeePreview> slice = list
          .take(takeKnown)
          .toList(growable: false);
      final int padSlots = targetFaceSlots - slice.length;
      final int stackSlots = useOverflow ? 4 : targetFaceSlots;
      final double totalWidth = _totalWidthForSlots(stackSlots);

      int ringIndex = 0;
      final List<Widget> stackChildren = <Widget>[];
      for (final AttendeePreview p in slice) {
        stackChildren.add(
          _ringedAvatar(
            left: ringIndex * (size - overlap),
            child: UserAvatarCircle(
              displayName: p.name,
              imageUrl: p.avatarUrl,
              size: size,
              seed: p.userId.isNotEmpty ? p.userId : p.name,
            ),
          ),
        );
        ringIndex++;
      }
      for (int p = 0; p < padSlots; p++) {
        final String label = String.fromCharCode(65 + p + ringIndex);
        stackChildren.add(
          _ringedAvatar(
            left: ringIndex * (size - overlap),
            child: UserAvatarCircle(
              displayName: label,
              size: size,
              seed: '${event.id}_peek_pad_${ringIndex}_$p',
            ),
          ),
        );
        ringIndex++;
      }
      if (useOverflow) {
        stackChildren.add(
          _ringedAvatar(
            left: 3 * (size - overlap),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.inputFill,
              ),
              child: Text(
                '+${count - 3}',
                style: AppTypography.eventsCaptionStrong(
                  Theme.of(context).textTheme,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: totalWidth,
        height: outer,
        child: Stack(clipBehavior: Clip.none, children: stackChildren),
      );
    }

    // Fallback: no peek data (offline / error) — organizer + decorative placeholders.
    final int display = count.clamp(1, 4);
    final double totalWidth = _totalWidthForSlots(display);
    return SizedBox(
      width: totalWidth,
      height: outer,
      child: Stack(
        clipBehavior: Clip.none,
        children: List<Widget>.generate(display, (int i) {
          final double left = i * (size - overlap);
          if (i == 0) {
            return _ringedAvatar(
              left: left,
              child: UserAvatarCircle(
                displayName: event.organizerName,
                imageUrl: event.organizerAvatarUrl,
                size: size,
                seed: event.organizerId,
              ),
            );
          }
          final String placeholderLabel = String.fromCharCode(0x40 + i);
          return _ringedAvatar(
            left: left,
            child: UserAvatarCircle(
              displayName: placeholderLabel,
              size: size,
              seed: '${event.id}_stack_$i',
            ),
          );
        }),
      ),
    );
  }
}
