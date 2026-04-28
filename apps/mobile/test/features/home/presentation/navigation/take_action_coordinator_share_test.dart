import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/navigation/take_action_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fallbackShareLinkPayloadForSite builds deterministic non-signed URL', () {
    const site = PollutionSite(
      id: 'c1234567890abcdefghijklmn',
      title: 'Site title',
      description: 'Site description',
      statusLabel: 'Medium',
      statusColor: AppColors.primary,
      distanceKm: 1,
      score: 1,
      participantCount: 0,
    );

    final payload = fallbackShareLinkPayloadForSite(site, channel: 'link');
    expect(payload.siteId, site.id);
    expect(payload.channel, 'link');
    expect(payload.token, isEmpty);
    expect(payload.cid, isEmpty);
    expect(payload.url, contains('/sites/${site.id}'));
  });
}
