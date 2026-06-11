import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Tracks touched/submit state and orchestrates focus, scroll, haptics, and a11y
/// announcements for form validation (Apple-like UX).
class FormFieldHandle {
  FormFieldHandle({this.focusNode, this.fieldKey});

  final FocusNode? focusNode;
  final GlobalKey? fieldKey;
}

mixin FormValidationMixin<T extends StatefulWidget> on State<T> {
  final Set<String> _touchedFieldIds = <String>{};
  final Set<String> _dirtyFieldIds = <String>{};
  bool submitAttempted = false;
  final Map<String, FormFieldHandle> _fieldHandles =
      <String, FormFieldHandle>{};
  final Map<String, String> _serverFieldErrors = <String, String>{};

  bool get hasActiveValidation =>
      submitAttempted || _touchedFieldIds.isNotEmpty;

  bool shouldShowFieldError(String id) =>
      submitAttempted || _touchedFieldIds.contains(id);

  void registerFormField(
    String id, {
    FocusNode? focusNode,
    GlobalKey? fieldKey,
  }) {
    _fieldHandles[id] = FormFieldHandle(
      focusNode: focusNode,
      fieldKey: fieldKey,
    );
    focusNode?.addListener(() {
      if (!focusNode.hasFocus && mounted && _dirtyFieldIds.contains(id)) {
        markFieldTouched(id);
      }
    });
  }

  /// Call when the user edits a field so blur can mark it touched for validation.
  void markFieldDirty(String id) {
    _dirtyFieldIds.add(id);
  }

  void markFieldTouched(String id) {
    if (!_touchedFieldIds.contains(id)) {
      setState(() => _touchedFieldIds.add(id));
    }
  }

  void clearServerFieldErrors() {
    if (_serverFieldErrors.isEmpty) return;
    setState(_serverFieldErrors.clear);
  }

  void setServerFieldErrors(Map<String, String> errors) {
    setState(() {
      _serverFieldErrors
        ..clear()
        ..addAll(errors);
      submitAttempted = true;
    });
  }

  String? serverFieldError(String id) => _serverFieldErrors[id];

  Set<String> get registeredFieldIds => _fieldHandles.keys.toSet();

  /// Runs [validator] only when the field is touched or submit was attempted.
  String? validateIfVisible(String id, String? Function() validator) {
    final String? server = _serverFieldErrors[id];
    if (server != null && server.isNotEmpty) {
      if (shouldShowFieldError(id)) return server;
    }
    if (!shouldShowFieldError(id)) return null;
    return validator();
  }

  int countInvalidFields(
    List<String> fieldOrder,
    Map<String, String? Function()> validators,
  ) {
    var count = 0;
    for (final String id in fieldOrder) {
      final String? Function()? validate = validators[id];
      if (validate == null) continue;
      if (validateIfVisible(id, validate) != null) {
        count++;
      }
    }
    return count;
  }

  Future<bool> focusAndScrollToFirstInvalid(
    BuildContext context,
    List<String> fieldOrder,
    Map<String, String? Function()> validators,
  ) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;
    for (final String id in fieldOrder) {
      final String? Function()? validate = validators[id];
      if (validate == null) continue;
      if (validateIfVisible(id, validate) != null) {
        final FormFieldHandle? handle = _fieldHandles[id];
        handle?.focusNode?.requestFocus();
        final BuildContext? ctx =
            handle?.fieldKey?.currentContext ?? handle?.focusNode?.context;
        if (ctx != null && ctx.mounted) {
          await Scrollable.ensureVisible(
            ctx,
            duration: AppMotion.fast,
            curve: AppMotion.smooth,
            alignment: 0.2,
          );
        }
        return true;
      }
    }
    return false;
  }

  /// Marks submit attempted, haptics, focuses first invalid, announces count.
  /// Returns true when validation failed (caller should abort submit).
  Future<bool> handleInvalidSubmit(
    BuildContext context,
    AppLocalizations l10n,
    List<String> fieldOrder,
    Map<String, String? Function()> validators,
  ) async {
    setState(() => submitAttempted = true);
    final int invalidCount = countInvalidFields(fieldOrder, validators);
    if (invalidCount == 0) return false;
    AppHaptics.warning(context);
    await focusAndScrollToFirstInvalid(context, fieldOrder, validators);
    if (!mounted) return true;
    SemanticsService.sendAnnouncement(
      View.of(context),
      l10n.formValidationErrorsAnnounce(invalidCount),
      Directionality.of(context),
    );
    return true;
  }
}
