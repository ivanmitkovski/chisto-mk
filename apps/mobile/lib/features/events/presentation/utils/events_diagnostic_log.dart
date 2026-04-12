import 'dart:developer' as developer;

/// Non-PII diagnostic channel for crash log correlation (codes only; no titles, ids, or queries).
void logEventsDiagnostic(String code) {
  developer.log(code, name: 'chisto.events');
}
