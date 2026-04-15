import 'package:chisto_mobile/core/cache/image_cache_diagnostics.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows fallback with retry on image failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          body: SizedBox(
            width: 240,
            height: 140,
            child: AppSmartImage(image: _AlwaysFailImageProvider()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Image unavailable'), findsOneWidget);
    expect(find.textContaining('Retry'), findsOneWidget);

    final snapshot = ImageCacheDiagnostics.snapshot();
    expect(snapshot.renderErrors, greaterThan(0));
  });
}

class _AlwaysFailImageProvider extends ImageProvider<_AlwaysFailImageProvider> {
  const _AlwaysFailImageProvider();

  @override
  Future<_AlwaysFailImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_AlwaysFailImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _AlwaysFailImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(StateError('simulated image decode failure')),
    );
  }
}
