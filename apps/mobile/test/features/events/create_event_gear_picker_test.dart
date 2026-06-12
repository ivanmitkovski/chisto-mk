import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/event_ui_mappers.dart';
import 'package:feature_events/src/presentation/utils/events_localized_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('gear picker shows a single description and gear options', (
    WidgetTester tester,
  ) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      wrapForWidgetTest(
        Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppBottomSheet.show<void>(
                      context: context,
                      builder: (BuildContext ctx) {
                        return AppGroupedOptionPickerSheet<EventGear>(
                          title: ctx.l10n.createEventGearTitle,
                          subtitle: ctx.l10n.createEventGearSubtitle,
                          closeSemanticLabel: ctx.l10n.commonClose,
                          options: EventGear.values
                              .map(
                                (EventGear gear) =>
                                    AppGroupedOption<EventGear>(
                                      icon: gear.icon,
                                      title: gear.localizedLabel(ctx.l10n),
                                      value: gear,
                                    ),
                              )
                              .toList(growable: false),
                          isSelected: (EventGear gear) => false,
                          onOptionTap: (EventGear gear) {},
                        );
                      },
                    );
                  },
                  child: const Text('Open gear picker'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open gear picker'));
    await tester.pumpAndSettle();

    // Exactly one description below the title — no duplicated instruction copy.
    expect(find.text(l10n.createEventGearSubtitle), findsOneWidget);
    expect(find.byType(AppSelectionInstruction), findsNothing);

    final Finder optionTiles = find.byType(AppActionTile);
    expect(optionTiles, findsWidgets);

    final AppActionTile firstTile = tester.widget<AppActionTile>(
      optionTiles.first,
    );
    expect(firstTile.title, EventGear.trashBags.localizedLabel(l10n));
  });
}
