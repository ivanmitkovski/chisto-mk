import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_filter.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:feature_events/src/presentation/utils/event_calendar_date_format.dart';
import 'package:feature_events/src/presentation/widgets/event_calendar.dart';
import 'package:feature_events/src/presentation/widgets/events_feed/events_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';
import '../events/recording_events_repository.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  Future<void> _openFilterSheet(WidgetTester tester) async {
    await tester.tap(find.text('Open filter'));
    await tester.pumpAndSettle();
  }

  Future<void> _tapDateFromTile(WidgetTester tester, String label) async {
    final Finder fromTile = find.ancestor(
      of: find.text(label),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(fromTile);
    await tester.pumpAndSettle();
    await tester.tap(fromTile);
    await tester.pumpAndSettle();
  }

  Widget _host({
    required RecordingEventsRepository repository,
    required EcoEventFilter activeChip,
    required void Function(BuildContext context) onOpen,
  }) {
    return wrapForWidgetTest(
      Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => onOpen(context),
                child: const Text('Open filter'),
              ),
            ),
          );
        },
      ),
    );
  }

  testWidgets('renders inset checklist rows and subtitle', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    late AppLocalizations l10n;
    final RecordingEventsRepository repository = RecordingEventsRepository();

    await tester.pumpWidget(
      _host(
        repository: repository,
        activeChip: EcoEventFilter.all,
        onOpen: (BuildContext context) {
          l10n = AppLocalizations.of(context)!;
          EventsFilterSheet.show(
            context,
            current: const EcoEventSearchParams(),
            activeChip: EcoEventFilter.all,
            repository: repository,
          );
        },
      ),
    );

    await _openFilterSheet(tester);

    expect(find.text(l10n.eventsFilterSheetSubtitle), findsOneWidget);
    expect(find.byType(AppFilterInsetGroup), findsNWidgets(2));
    expect(find.byType(AppFilterCheckRow), findsWidgets);
  });

  testWidgets(
    'From tile opens design-system calendar instead of Material picker',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      late AppLocalizations l10n;
      final RecordingEventsRepository repository = RecordingEventsRepository();

      await tester.pumpWidget(
        _host(
          repository: repository,
          activeChip: EcoEventFilter.all,
          onOpen: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            EventsFilterSheet.show(
              context,
              current: const EcoEventSearchParams(),
              activeChip: EcoEventFilter.all,
              repository: repository,
            );
          },
        ),
      );

      await _openFilterSheet(tester);

      expect(find.text(l10n.eventsFilterSheetTitle), findsOneWidget);

      await _tapDateFromTile(tester, l10n.eventsFilterSheetDateFrom);

      expect(find.byType(EventCalendar), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(EventCalendar),
          matching: find.text('15'),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(l10n.eventsTimePickerConfirm));
      await tester.pumpAndSettle();

      expect(
        find.text(
          formatEventCalendarDate(
            tester.element(find.byType(EventsFilterSheet)),
            DateTime(DateTime.now().year, DateTime.now().month, 15),
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('From picker respects existing To upper bound', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    late AppLocalizations l10n;
    EcoEventSearchParams? result;
    final RecordingEventsRepository repository = RecordingEventsRepository();

    await tester.pumpWidget(
      _host(
        repository: repository,
        activeChip: EcoEventFilter.all,
        onOpen: (BuildContext context) async {
          l10n = AppLocalizations.of(context)!;
          result = await EventsFilterSheet.show(
            context,
            current: EcoEventSearchParams(dateTo: DateTime(2026, 6, 10)),
            activeChip: EcoEventFilter.all,
            repository: repository,
          );
        },
      ),
    );

    await _openFilterSheet(tester);

    await _tapDateFromTile(tester, l10n.eventsFilterSheetDateFrom);

    await tester.tap(
      find.descendant(
        of: find.byType(EventCalendar),
        matching: find.text('10'),
      ),
    );
    await tester.pump();

    await tester.tap(find.text(l10n.eventsTimePickerConfirm));
    await tester.pumpAndSettle();

    final Finder applyButton = find.descendant(
      of: find.byType(EventsFilterSheet),
      matching: find.byType(AppButton),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(result?.dateFrom, DateTime(2026, 6, 10));
    expect(result?.dateTo, DateTime(2026, 6, 10));
  });

  testWidgets(
    'shows chip override banner when upcoming pill and status draft',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      late AppLocalizations l10n;
      final RecordingEventsRepository repository = RecordingEventsRepository();

      await tester.pumpWidget(
        _host(
          repository: repository,
          activeChip: EcoEventFilter.upcoming,
          onOpen: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            EventsFilterSheet.show(
              context,
              current: EcoEventSearchParams(
                statuses: <EcoEventStatus>{EcoEventStatus.completed},
              ),
              activeChip: EcoEventFilter.upcoming,
              repository: repository,
            );
          },
        ),
      );

      await _openFilterSheet(tester);

      expect(
        find.text(l10n.eventsFilterChipStatusOverrideHint),
        findsOneWidget,
      );
    },
  );
}
