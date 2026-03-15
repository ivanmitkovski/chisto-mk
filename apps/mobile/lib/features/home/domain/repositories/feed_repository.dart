import 'package:flutter/foundation.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';

abstract class FeedRepository implements Listenable {
  List<PollutionSite> get sites;
  bool get isReady;
  Future<void> get ready;

  void loadInitialIfNeeded();
  PollutionSite? findById(String id);
  bool toggleUpvote(String siteId);
  bool toggleSave(String siteId);
}
