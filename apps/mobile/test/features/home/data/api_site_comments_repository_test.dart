import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/home/data/api_site_comments_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubApiClient extends ApiClient {
  _StubApiClient() : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: () {},
      );

  ApiResponse? nextGet;

  @override
  Future<ApiResponse> get(String path, {Map<String, String>? headers}) async {
    return nextGet ??
        const ApiResponse(statusCode: 200, json: <String, dynamic>{});
  }
}

void main() {
  late _StubApiClient client;
  late ApiSiteCommentsRepository repo;

  setUp(() {
    client = _StubApiClient();
    repo = ApiSiteCommentsRepository(client);
  });

  test('getSiteComments maps nested replies', () async {
    client.nextGet = const ApiResponse(
      statusCode: 200,
      json: <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'id': 'root-1',
            'parentId': null,
            'authorId': 'u1',
            'authorName': 'Alice',
            'body': 'Root',
            'createdAt': '2026-01-01T12:00:00.000Z',
            'likesCount': 2,
            'isLikedByMe': false,
            'repliesCount': 1,
            'replies': <dynamic>[
              <String, dynamic>{
                'id': 'reply-1',
                'parentId': 'root-1',
                'authorId': 'u2',
                'authorName': 'Bob',
                'body': 'Reply',
                'createdAt': '2026-01-01T13:00:00.000Z',
                'likesCount': 0,
                'isLikedByMe': true,
                'repliesCount': 0,
                'replies': <dynamic>[],
              },
            ],
          },
        ],
        'meta': <String, dynamic>{
          'page': 1,
          'limit': 20,
          'total': 1,
        },
      },
    );

    final SiteCommentsResult r = await repo.getSiteComments('site-a');

    expect(r.items, hasLength(1));
    expect(r.items.first.id, 'root-1');
    expect(r.items.first.replies, hasLength(1));
    expect(r.items.first.replies.first.id, 'reply-1');
    expect(r.items.first.replies.first.isLikedByMe, isTrue);
    expect(r.total, 1);
  });

  test('getSiteUpvotes maps hasMore from meta', () async {
    client.nextGet = const ApiResponse(
      statusCode: 200,
      json: <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'userId': 'u9',
            'displayName': 'Pat',
            'avatarUrl': null,
            'upvotedAt': '2026-02-02T10:00:00.000Z',
          },
        ],
        'meta': <String, dynamic>{
          'page': 1,
          'limit': 20,
          'total': 40,
          'hasMore': true,
        },
      },
    );

    final SiteUpvotesResult r = await repo.getSiteUpvotes('site-b');

    expect(r.items, hasLength(1));
    expect(r.items.first.displayName, 'Pat');
    expect(r.hasMore, isTrue);
    expect(r.total, 40);
  });
}
