import 'package:chisto_mobile/features/home/domain/models/cleaning_event.dart';
import 'package:chisto_mobile/features/home/domain/models/comment.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ImageProvider primaryImage;

  setUp(() {
    primaryImage = NetworkImage('https://example.com/site.jpg');
  });

  group('PollutionSite', () {
    PollutionSite buildSite({
      String id = 'site-1',
      List<ImageProvider>? images,
      List<Comment> comments = const [],
      List<CleaningEvent> cleaningEvents = const [],
    }) {
      return PollutionSite(
        id: id,
        title: 'Test Site',
        description: 'A test pollution site',
        statusLabel: 'Active',
        statusColor: Colors.green,
        distanceKm: 2.5,
        score: 10,
        participantCount: 5,
        imageProvider: primaryImage,
        images: images,
        comments: comments,
        cleaningEvents: cleaningEvents,
        urgencyLabel: 'High',
        pollutionType: 'Plastic',
      );
    }

    test('constructs with all required fields', () {
      final PollutionSite site = buildSite();

      expect(site.id, 'site-1');
      expect(site.title, 'Test Site');
      expect(site.description, 'A test pollution site');
      expect(site.statusLabel, 'Active');
      expect(site.statusColor, Colors.green);
      expect(site.distanceKm, 2.5);
      expect(site.score, 10);
      expect(site.participantCount, 5);
      expect(site.imageProvider, primaryImage);
      expect(site.urgencyLabel, 'High');
      expect(site.pollutionType, 'Plastic');
    });

    test('constructs with optional fields', () {
      final PollutionSite site = PollutionSite(
        id: 'site-2',
        title: 'Minimal',
        description: 'Minimal site',
        statusLabel: 'Pending',
        statusColor: Colors.orange,
        distanceKm: 0.0,
        score: 0,
        participantCount: 0,
        imageProvider: primaryImage,
      );

      expect(site.images, isNull);
      expect(site.comments, isEmpty);
      expect(site.cleaningEvents, isEmpty);
      expect(site.urgencyLabel, isNull);
      expect(site.pollutionType, isNull);
    });

    test('galleryImages returns primary image when images is null', () {
      final PollutionSite site = buildSite(images: null);

      expect(site.galleryImages.length, 1);
      expect(site.galleryImages.first, primaryImage);
    });

    test('galleryImages returns primary image when images is empty', () {
      final PollutionSite site = buildSite(images: <ImageProvider>[]);

      expect(site.galleryImages.length, 1);
      expect(site.galleryImages.first, primaryImage);
    });

    test('galleryImages returns images list when provided', () {
      final ImageProvider secondary = NetworkImage('https://example.com/site2.jpg');
      final PollutionSite site = buildSite(
        images: <ImageProvider>[primaryImage, secondary],
      );

      expect(site.galleryImages.length, 2);
      expect(site.galleryImages.first, primaryImage);
      expect(site.galleryImages.last, secondary);
    });

    test('commentCount returns comments length', () {
      final List<Comment> comments = <Comment>[
        const Comment(id: 'c1', authorName: 'A', text: 'Comment 1'),
        const Comment(id: 'c2', authorName: 'B', text: 'Comment 2'),
      ];
      final PollutionSite site = buildSite(comments: comments);

      expect(site.commentCount, 2);
    });

    test('commentCount returns 0 when no comments', () {
      final PollutionSite site = buildSite();

      expect(site.commentCount, 0);
    });

    test('copyWith updates engagement fields without mutating base data', () {
      final PollutionSite site = buildSite();
      final PollutionSite updated = site.copyWith(
        score: 24,
        shareCount: 5,
        isUpvotedByMe: true,
        isSavedByMe: true,
      );

      expect(updated.score, 24);
      expect(updated.shareCount, 5);
      expect(updated.isUpvotedByMe, isTrue);
      expect(updated.isSavedByMe, isTrue);
      expect(updated.id, site.id);
      expect(updated.title, site.title);
      expect(site.score, 10);
      expect(site.isUpvotedByMe, isFalse);
    });
  });
}
