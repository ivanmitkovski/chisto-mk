/// Target row to briefly highlight when opening a notification from the inbox.
class NotificationInboxHighlight {
  const NotificationInboxHighlight({
    this.commentId,
    this.actorUserId,
  });

  final String? commentId;
  final String? actorUserId;

  bool get hasTarget =>
      (commentId != null && commentId!.trim().isNotEmpty) ||
      (actorUserId != null && actorUserId!.trim().isNotEmpty);
}
