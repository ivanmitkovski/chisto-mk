import 'dart:io';

import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class EventCalendarExport {
  const EventCalendarExport._();

  static Future<void> shareEvent(EcoEvent event) async {
    final File file = await _buildIcsFile(event);
    await Share.shareXFiles(
      <XFile>[
        XFile(file.path, mimeType: 'text/calendar'),
      ],
      subject: event.title,
      text: 'Add "${event.title}" to your calendar.',
    );
  }

  static Future<File> _buildIcsFile(EcoEvent event) async {
    final Directory dir = await getTemporaryDirectory();
    final String safeId = event.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final File file = File('${dir.path}/chisto-event-$safeId.ics');
    final String uid = '$safeId@chisto.mk';
    final DateTime nowUtc = DateTime.now().toUtc();
    final DateTime startUtc = event.startDateTime.toUtc();
    final DateTime endUtc = event.endDateTime.toUtc();

    final String content = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Chisto.mk//Events//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:${_formatUtc(nowUtc)}',
      'DTSTART:${_formatUtc(startUtc)}',
      'DTEND:${_formatUtc(endUtc)}',
      'SUMMARY:${_escape(event.title)}',
      'DESCRIPTION:${_escape(event.description)}',
      'LOCATION:${_escape(event.siteName)}',
      'STATUS:CONFIRMED',
      'END:VEVENT',
      'END:VCALENDAR',
      '',
    ].join('\r\n');

    await file.writeAsString(content, flush: true);
    return file;
  }

  static String _formatUtc(DateTime dt) {
    final DateTime utc = dt.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}'
        'T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  static String _escape(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('\n', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;');
  }
}
