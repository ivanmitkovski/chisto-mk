import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_participants.dart';
import 'package:chisto_mobile/features/events/data/chat/event_chat_repository.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/user_avatar_circle.dart';
import 'package:flutter/material.dart';

/// Opens a bottom sheet listing chat participants (same chrome as pinned messages sheet).
Future<void> showChatParticipantsSheet({
  required BuildContext context,
  required String eventId,
  required EventChatRepository repo,
  required List<EventChatParticipantPreview> initialParticipants,
  required int initialCount,
  required String? currentUserId,
  bool initialLoadFailed = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.panelBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
    ),
    builder: (BuildContext ctx) {
      return _ChatParticipantsSheetBody(
        eventId: eventId,
        repo: repo,
        initialParticipants: initialParticipants,
        initialCount: initialCount,
        currentUserId: currentUserId,
        initialLoadFailed: initialLoadFailed,
      );
    },
  );
}

List<EventChatParticipantPreview> sortedChatParticipants(
  List<EventChatParticipantPreview> raw,
  String? currentUserId,
) {
  final List<EventChatParticipantPreview> copy = List<EventChatParticipantPreview>.from(raw);
  copy.sort((EventChatParticipantPreview a, EventChatParticipantPreview b) {
    final bool aMe = a.id == currentUserId;
    final bool bMe = b.id == currentUserId;
    if (aMe != bMe) {
      return aMe ? -1 : 1;
    }
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
  return copy;
}

class _ChatParticipantsSheetBody extends StatefulWidget {
  const _ChatParticipantsSheetBody({
    required this.eventId,
    required this.repo,
    required this.initialParticipants,
    required this.initialCount,
    required this.currentUserId,
    required this.initialLoadFailed,
  });

  final String eventId;
  final EventChatRepository repo;
  final List<EventChatParticipantPreview> initialParticipants;
  final int initialCount;
  final String? currentUserId;
  final bool initialLoadFailed;

  @override
  State<_ChatParticipantsSheetBody> createState() => _ChatParticipantsSheetBodyState();
}

class _ChatParticipantsSheetBodyState extends State<_ChatParticipantsSheetBody> {
  late List<EventChatParticipantPreview> _participants;
  late int _count;
  late bool _fatalError;

  @override
  void initState() {
    super.initState();
    _participants = sortedChatParticipants(widget.initialParticipants, widget.currentUserId);
    _count = widget.initialCount;
    _fatalError = widget.initialLoadFailed && _participants.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_refresh(userPulled: false));
      }
    });
  }

  /// [userPulled] is true for [RefreshIndicator] swipe; false for initial open refresh.
  Future<void> _refresh({required bool userPulled}) async {
    try {
      final EventChatParticipantsResult p = await widget.repo.fetchParticipants(widget.eventId);
      if (!mounted) {
        return;
      }
      setState(() {
        _participants = sortedChatParticipants(p.participants, widget.currentUserId);
        _count = p.count;
        _fatalError = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      final bool hadList = _participants.isNotEmpty;
      if (_participants.isEmpty) {
        setState(() => _fatalError = true);
      }
      if (mounted && (userPulled || !hadList)) {
        AppSnack.show(context, message: context.l10n.eventChatParticipantsLoadError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxH = math.min(MediaQuery.sizeOf(context).height * 0.62, 520);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: AppSpacing.sheetHandle,
                height: AppSpacing.sheetHandleHeight,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      context.l10n.eventChatParticipantsSheetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_count > 0)
                    Text(
                      context.l10n.eventChatParticipantsCount(_count),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            if (_fatalError)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      context.l10n.eventChatParticipantsLoadError,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.tonal(
                      onPressed: () => unawaited(_refresh(userPulled: true)),
                      child: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: maxH,
                child: RefreshIndicator(
                  onRefresh: () => _refresh(userPulled: true),
                  child: _participants.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          children: <Widget>[
                            SizedBox(height: maxH * 0.2),
                            Text(
                              context.l10n.eventChatParticipantsEmpty,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: _participants.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.6)),
                          itemBuilder: (BuildContext c, int i) {
                            final EventChatParticipantPreview p = _participants[i];
                            final bool isMe = p.id == widget.currentUserId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Row(
                                children: <Widget>[
                                  UserAvatarCircle(
                                    displayName: p.displayName,
                                    imageUrl: p.avatarUrl,
                                    size: 44,
                                    seed: p.id,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          p.displayName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (isMe)
                                          Text(
                                            context.l10n.eventChatParticipantsYouBadge,
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
