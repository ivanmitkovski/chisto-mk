import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('ReportGeoFence', () {
    test('contains returns true for coordinates in Macedonia', () {
      expect(ReportGeoFence.contains(41.6, 21.7), isTrue);
      expect(ReportGeoFence.contains(40.8, 20.4), isTrue);
      expect(ReportGeoFence.contains(42.4, 23.1), isTrue);
    });

    test('contains returns false for coordinates outside Macedonia', () {
      expect(ReportGeoFence.contains(40.0, 21.0), isFalse);
      expect(ReportGeoFence.contains(43.0, 21.0), isFalse);
      expect(ReportGeoFence.contains(41.0, 19.0), isFalse);
      expect(ReportGeoFence.contains(41.0, 24.0), isFalse);
    });

    test('clampToInsetBounds clamps out-of-bounds coordinates', () {
      final (double lat, double lng) = ReportGeoFence.clampToInsetBounds(40.0, 19.0);
      expect(lat, greaterThanOrEqualTo(ReportGeoFence.insetMinLat));
      expect(lat, lessThanOrEqualTo(ReportGeoFence.insetMaxLat));
      expect(lng, greaterThanOrEqualTo(ReportGeoFence.insetMinLng));
      expect(lng, lessThanOrEqualTo(ReportGeoFence.insetMaxLng));
    });

    test('inset bounds are within main bounds', () {
      expect(ReportGeoFence.insetMinLat, greaterThan(ReportGeoFence.minLat));
      expect(ReportGeoFence.insetMaxLat, lessThan(ReportGeoFence.maxLat));
      expect(ReportGeoFence.insetMinLng, greaterThan(ReportGeoFence.minLng));
      expect(ReportGeoFence.insetMaxLng, lessThan(ReportGeoFence.maxLng));
    });
  });

  group('ReportCategory', () {
    test('has expected values', () {
      expect(ReportCategory.values.length, 5);
      expect(ReportCategory.values, contains(ReportCategory.illegalLandfill));
      expect(ReportCategory.values, contains(ReportCategory.waterPollution));
      expect(ReportCategory.values, contains(ReportCategory.airPollution));
      expect(ReportCategory.values, contains(ReportCategory.industrialWaste));
      expect(ReportCategory.values, contains(ReportCategory.other));
    });

    test('each category has label and description', () {
      for (final ReportCategory cat in ReportCategory.values) {
        expect(cat.label, isNotEmpty);
        expect(cat.description, isNotEmpty);
      }
    });
  });

  group('ReportRequirement', () {
    test('has expected values and messages', () {
      expect(ReportRequirement.photos.message, 'Add at least one photo');
      expect(ReportRequirement.category.message, 'Choose a category');
      expect(ReportRequirement.location.message, 'Confirm a location in Macedonia');
    });
  });

  group('CleanupEffort', () {
    test('has expected values and labels', () {
      expect(CleanupEffort.oneToTwo.label, '1–2 people');
      expect(CleanupEffort.threeToFive.label, '3–5 people');
      expect(CleanupEffort.sixToTen.label, '6–10 people');
      expect(CleanupEffort.tenPlus.label, '10+ people');
      expect(CleanupEffort.notSure.label, 'Not sure');
    });

    test('apiKey round-trips with fromApiString', () {
      for (final CleanupEffort e in CleanupEffort.values) {
        expect(CleanupEffort.fromApiString(e.apiKey), e);
      }
      expect(CleanupEffort.fromApiString(null), isNull);
      expect(CleanupEffort.fromApiString(''), isNull);
      expect(CleanupEffort.fromApiString('INVALID'), isNull);
    });
  });

  group('ReportDraft', () {
    test('constructs with defaults', () {
      final ReportDraft draft = ReportDraft();

      expect(draft.photos, isEmpty);
      expect(draft.category, isNull);
      expect(draft.description, '');
      expect(draft.latitude, isNull);
      expect(draft.longitude, isNull);
      expect(draft.address, isNull);
      expect(draft.cleanupEffort, isNull);
    });

    test('constructs with all fields', () {
      final List<XFile> photos = <XFile>[XFile('/tmp/photo.jpg')];
      final ReportDraft draft = ReportDraft(
        photos: photos,
        category: ReportCategory.illegalLandfill,
        description: 'Test description',
        latitude: 41.6,
        longitude: 21.7,
        address: 'Skopje',
        cleanupEffort: CleanupEffort.threeToFive,
      );

      expect(draft.photos, photos);
      expect(draft.category, ReportCategory.illegalLandfill);
      expect(draft.description, 'Test description');
      expect(draft.latitude, 41.6);
      expect(draft.longitude, 21.7);
      expect(draft.address, 'Skopje');
      expect(draft.cleanupEffort, CleanupEffort.threeToFive);
    });

    test('hasPhotos returns true when photos non-empty', () {
      final ReportDraft empty = ReportDraft();
      final ReportDraft withPhotos = ReportDraft(
        photos: <XFile>[XFile('/tmp/photo.jpg')],
      );

      expect(empty.hasPhotos, isFalse);
      expect(withPhotos.hasPhotos, isTrue);
    });

    test('hasCategory returns true when category set', () {
      final ReportDraft without = ReportDraft();
      final ReportDraft withCat = ReportDraft(category: ReportCategory.other);

      expect(without.hasCategory, isFalse);
      expect(withCat.hasCategory, isTrue);
    });

    test('hasLocation returns true when lat/lng set', () {
      final ReportDraft without = ReportDraft();
      final ReportDraft withLoc = ReportDraft(latitude: 41.6, longitude: 21.7);

      expect(without.hasLocation, isFalse);
      expect(withLoc.hasLocation, isTrue);
    });

    test('hasDescription returns true when non-empty trimmed', () {
      final ReportDraft empty = ReportDraft();
      final ReportDraft whitespace = ReportDraft(description: '   ');
      final ReportDraft withDesc = ReportDraft(description: ' Some text ');

      expect(empty.hasDescription, isFalse);
      expect(whitespace.hasDescription, isFalse);
      expect(withDesc.hasDescription, isTrue);
    });

    test('isValid requires photos, category, and location', () {
      final ReportDraft incomplete = ReportDraft(
        photos: <XFile>[XFile('/tmp/p.jpg')],
        category: ReportCategory.other,
      );
      expect(incomplete.isValid, isFalse);

      final ReportDraft valid = ReportDraft(
        photos: <XFile>[XFile('/tmp/p.jpg')],
        category: ReportCategory.other,
        latitude: 41.6,
        longitude: 21.7,
      );
      expect(valid.isValid, isTrue);
    });

    test('completedRequiredSteps and totalRequiredSteps', () {
      final ReportDraft empty = ReportDraft();
      expect(empty.completedRequiredSteps, 0);
      expect(empty.totalRequiredSteps, 3);

      final ReportDraft twoOfThree = ReportDraft(
        photos: <XFile>[XFile('/tmp/p.jpg')],
        category: ReportCategory.other,
      );
      expect(twoOfThree.completedRequiredSteps, 2);
      expect(twoOfThree.totalRequiredSteps, 3);
    });

    test('missingRequirements returns correct list', () {
      final ReportDraft empty = ReportDraft();
      final List<ReportRequirement> missing = empty.missingRequirements(
        hasLocationInMacedonia: false,
      );

      expect(missing, contains(ReportRequirement.photos));
      expect(missing, contains(ReportRequirement.category));
      expect(missing, contains(ReportRequirement.location));
      expect(missing.length, 3);
    });

    test('missingRequirements excludes location when in Macedonia', () {
      final ReportDraft withLoc = ReportDraft(
        photos: <XFile>[XFile('/tmp/p.jpg')],
        category: ReportCategory.other,
        latitude: 41.6,
        longitude: 21.7,
      );
      final List<ReportRequirement> missing = withLoc.missingRequirements(
        hasLocationInMacedonia: true,
      );

      expect(missing, isEmpty);
    });

    test('copyWith updates fields', () {
      final ReportDraft original = ReportDraft(
        description: 'Original',
        latitude: 41.0,
        longitude: 21.0,
      );

      final ReportDraft updated = original.copyWith(
        description: 'Updated',
        latitude: 42.0,
      );

      expect(updated.description, 'Updated');
      expect(updated.latitude, 42.0);
      expect(updated.longitude, 21.0);
    });

    test('copyWith clearLocation clears location fields', () {
      final ReportDraft withLoc = ReportDraft(
        latitude: 41.6,
        longitude: 21.7,
        address: 'Skopje',
      );

      final ReportDraft cleared = withLoc.copyWith(clearLocation: true);

      expect(cleared.latitude, isNull);
      expect(cleared.longitude, isNull);
      expect(cleared.address, isNull);
    });

    test('copyWith clearLocation preserves other fields', () {
      final ReportDraft original = ReportDraft(
        photos: <XFile>[XFile('/tmp/p.jpg')],
        category: ReportCategory.waterPollution,
        description: 'Desc',
        latitude: 41.6,
        longitude: 21.7,
        cleanupEffort: CleanupEffort.sixToTen,
      );

      final ReportDraft cleared = original.copyWith(clearLocation: true);

      expect(cleared.photos.length, 1);
      expect(cleared.category, ReportCategory.waterPollution);
      expect(cleared.description, 'Desc');
      expect(cleared.cleanupEffort, CleanupEffort.sixToTen);
    });
  });
}
