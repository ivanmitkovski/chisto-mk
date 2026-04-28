import 'package:chisto_mobile/features/home/presentation/widgets/site_card/share_sheet.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const String _kSiteTitle = 'Test pollution site';
const String _kShareUrl = 'https://chisto.mk/sites/550e8400-e29b-41d4-a716-446655440000';

const List<LocalizationsDelegate<dynamic>> _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

MaterialApp _wrapSheet({required WidgetBuilder builder}) {
  return MaterialApp(
    localizationsDelegates: _delegates,
    supportedLocales: const <Locale>[Locale('en')],
    home: Scaffold(body: Builder(builder: builder)),
  );
}

ShareSheet _defaultSheet({String? imageUrl}) => ShareSheet(
      title: 'Share site',
      subtitle: 'Help others discover this site',
      siteTitle: _kSiteTitle,
      shareUrl: _kShareUrl,
      siteImageUrl: imageUrl,
    );

void main() {
  group('ShareSheet', () {
    testWidgets('renders copy link and send tiles (only 2 tiles)', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapSheet(builder: (_) => _defaultSheet()));
      await tester.pumpAndSettle();

      expect(find.byType(ShareActionTile), findsNWidgets(2));
      expect(find.text('Copy link'), findsOneWidget);
      expect(find.text('Send to people'), findsOneWidget);
    });

    testWidgets('does not contain shareProfile option', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapSheet(builder: (_) => _defaultSheet()));
      await tester.pumpAndSettle();

      expect(find.text('Share to profile'), findsNothing);
    });

    testWidgets('shows link preview with site title and host', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapSheet(builder: (_) => _defaultSheet()));
      await tester.pumpAndSettle();

      expect(find.text(_kSiteTitle), findsOneWidget);
      expect(find.text('chisto.mk'), findsOneWidget);
    });

    testWidgets('renders without site image gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapSheet(builder: (_) => _defaultSheet(imageUrl: null)));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(find.text(_kSiteTitle), findsOneWidget);
    });

    testWidgets('drag handle has semantics label', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapSheet(builder: (_) => _defaultSheet()));
      await tester.pumpAndSettle();

      final Finder semantics = find.bySemanticsLabel('Drag to resize or dismiss');
      expect(semantics, findsOneWidget);
    });

    testWidgets('pops ShareAction.copyLink on copy link tap', (WidgetTester tester) async {
      // Use a larger viewport so the sheet content fits.
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ShareAction? poppedAction;
      await tester.pumpWidget(_wrapSheet(builder: (BuildContext ctx) {
        return ElevatedButton(
          onPressed: () async {
            poppedAction = await showModalBottomSheet<ShareAction>(
              context: ctx,
              builder: (_) => _defaultSheet(),
            );
          },
          child: const Text('Open'),
        );
      }));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();

      expect(poppedAction, ShareAction.copyLink);
    });

    testWidgets('pops ShareAction.sendMessage on send tile tap', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ShareAction? poppedAction;
      await tester.pumpWidget(_wrapSheet(builder: (BuildContext ctx) {
        return ElevatedButton(
          onPressed: () async {
            poppedAction = await showModalBottomSheet<ShareAction>(
              context: ctx,
              builder: (_) => _defaultSheet(),
            );
          },
          child: const Text('Open'),
        );
      }));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send to people'));
      await tester.pumpAndSettle();

      expect(poppedAction, ShareAction.sendMessage);
    });

    testWidgets('returns null when sheet is dismissed via barrier', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Non-null sentinel so we can detect the null assignment.
      ShareAction? poppedAction = ShareAction.copyLink;
      await tester.pumpWidget(_wrapSheet(builder: (BuildContext ctx) {
        return ElevatedButton(
          onPressed: () async {
            poppedAction = await showModalBottomSheet<ShareAction>(
              context: ctx,
              isDismissible: true,
              builder: (_) => _defaultSheet(),
            );
          },
          child: const Text('Open'),
        );
      }));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap the scrim (top-left corner is outside the sheet).
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(poppedAction, isNull);
    });
  });
}
