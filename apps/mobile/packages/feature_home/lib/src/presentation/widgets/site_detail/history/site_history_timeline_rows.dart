import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_sections.dart';

enum SiteHistoryTimelineRowKind { sectionHeader, entry }

class SiteHistoryTimelineRow {
  const SiteHistoryTimelineRow.sectionHeader({
    required this.label,
    required this.showLineAbove,
    required this.showLineBelow,
  }) : kind = SiteHistoryTimelineRowKind.sectionHeader,
       entry = null;

  const SiteHistoryTimelineRow.entry({
    required this.entry,
    required this.showLineAbove,
    required this.showLineBelow,
  }) : kind = SiteHistoryTimelineRowKind.entry,
       label = null;

  final SiteHistoryTimelineRowKind kind;
  final String? label;
  final SiteHistoryEntry? entry;
  final bool showLineAbove;
  final bool showLineBelow;
}

List<SiteHistoryTimelineRow> buildSiteHistoryTimelineRows({
  required List<SiteHistoryEntry> items,
  required DateTime now,
  required String Function(SiteHistorySection section) sectionLabelFor,
}) {
  if (items.isEmpty) return const <SiteHistoryTimelineRow>[];

  final List<SiteHistorySection> sections = groupSiteHistoryByBucket(
    items,
    now,
  );
  final List<SiteHistoryTimelineRow> draft = <SiteHistoryTimelineRow>[];

  for (final SiteHistorySection section in sections) {
    draft.add(
      SiteHistoryTimelineRow.sectionHeader(
        label: sectionLabelFor(section),
        showLineAbove: false,
        showLineBelow: false,
      ),
    );
    for (final SiteHistoryEntry entry in section.entries) {
      draft.add(
        SiteHistoryTimelineRow.entry(
          entry: entry,
          showLineAbove: false,
          showLineBelow: false,
        ),
      );
    }
  }

  if (draft.isEmpty) return draft;

  return List<SiteHistoryTimelineRow>.generate(draft.length, (int index) {
    final SiteHistoryTimelineRow row = draft[index];
    final bool showLineAbove = index > 0;
    final bool showLineBelow = index < draft.length - 1;
    switch (row.kind) {
      case SiteHistoryTimelineRowKind.sectionHeader:
        return SiteHistoryTimelineRow.sectionHeader(
          label: row.label,
          showLineAbove: showLineAbove,
          showLineBelow: showLineBelow,
        );
      case SiteHistoryTimelineRowKind.entry:
        return SiteHistoryTimelineRow.entry(
          entry: row.entry,
          showLineAbove: showLineAbove,
          showLineBelow: showLineBelow,
        );
    }
  });
}
