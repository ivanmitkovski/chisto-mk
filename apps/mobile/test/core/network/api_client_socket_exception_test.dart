import 'dart:io';

import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('SocketException maps to AppError.network', () async {
    final mock = MockClient((http.Request request) async {
      throw const SocketException('Connection refused');
    });

    final client = ApiClient(
      config: AppConfig.local,
      accessToken: () => 'token',
      onUnauthorized: (_) {},
      httpClient: mock,
    );

    await expectLater(
      client.get('/reports'),
      throwsA(
        isA<AppError>()
            .having((AppError e) => e.code, 'code', 'NETWORK_ERROR')
            .having(
              (AppError e) => e.message,
              'message',
              contains('Connection refused'),
            )
            .having((AppError e) => e.retryable, 'retryable', isTrue),
      ),
    );
  });

  test(
    'cleartext SocketException maps to actionable network message',
    () async {
      final mock = MockClient((http.Request request) async {
        throw const SocketException(
          'Cleartext HTTP traffic to chisto-dev-alb.example.com not permitted',
        );
      });

      final client = ApiClient(
        config: AppConfig.local,
        accessToken: () => 'token',
        onUnauthorized: (_) {},
        httpClient: mock,
      );

      await expectLater(
        client.post('/reports', body: <String, dynamic>{}),
        throwsA(
          isA<AppError>()
              .having((AppError e) => e.code, 'code', 'NETWORK_ERROR')
              .having(
                (AppError e) => e.message,
                'message',
                contains('cleartext'),
              ),
        ),
      );
    },
  );
}
