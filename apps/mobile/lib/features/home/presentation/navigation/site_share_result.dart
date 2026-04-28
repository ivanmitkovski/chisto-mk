import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';

/// Outcome of the site share sheet + server tracking flow.
sealed class SiteShareResult {
  const SiteShareResult();
}

/// User dismissed the sheet or the widget was unmounted before finishing.
final class SiteShareCancelled extends SiteShareResult {
  const SiteShareCancelled();
}

/// Server accepted the share; [snapshot] has authoritative counts.
final class SiteShareSuccess extends SiteShareResult {
  const SiteShareSuccess(this.snapshot);

  final EngagementSnapshot snapshot;
}

/// User completed the local action but `POST /sites/:id/share` failed (snack shown).
final class SiteShareTrackFailed extends SiteShareResult {
  const SiteShareTrackFailed();
}

/// Return value of [TakeActionCoordinator.execute] so callers can handle share specially.
sealed class TakeActionCoordinatorOutcome {
  const TakeActionCoordinatorOutcome();
}

/// Create / join / donate flows finished (no share payload).
final class TakeActionCoordinatorFinished extends TakeActionCoordinatorOutcome {
  const TakeActionCoordinatorFinished();
}

/// User chose [TakeActionType.shareSite]; inspect [share] for success vs cancel vs track failure.
final class TakeActionCoordinatorShareOutcome extends TakeActionCoordinatorOutcome {
  const TakeActionCoordinatorShareOutcome(this.share);

  final SiteShareResult share;
}
