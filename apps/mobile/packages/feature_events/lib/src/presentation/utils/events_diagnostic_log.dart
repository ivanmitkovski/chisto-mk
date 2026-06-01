import 'dart:developer' as developer;

/// Non-PII diagnostic channel for crash log correlation (codes only; no titles, ids, or queries).
/// Optional [detail] may carry numeric counters only (lane totals, durations), never free text.
void logEventsDiagnostic(String code, {String? detail}) {
  if (detail != null && detail.isNotEmpty) {
    developer.log('$code|$detail', name: 'chisto.events');
  } else {
    developer.log(code, name: 'chisto.events');
  }
}
