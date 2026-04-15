import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

abstract final class ProfileActionsHandler {
  static Future<void> handleHelp(BuildContext context) async {
    AppHaptics.tap();
    final String url = ServiceLocator.instance.config.helpCenterUrl;
    final Uri uri = Uri.parse(url);
    final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppSnack.show(
        context,
        message: context.l10n.profileHelpCenterOpenFailedSnack,
        type: AppSnackType.info,
      );
    }
  }

  static Future<void> handleLogout(BuildContext context) async {
    AppHaptics.tap();
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(ctx.l10n.profileSignOutDialogTitle),
        content: Text(ctx.l10n.profileSignOutDialogBody),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.commonCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.profileSignOutTile),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      _performLogout(context);
    }
  }

  static Future<void> handleDeleteAccount(BuildContext context) async {
    AppHaptics.tap();
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: Text(ctx.l10n.profileDeleteAccountDialogTitle),
        content: Text(ctx.l10n.profileDeleteAccountDialogBody),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.commonCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!context.mounted) return;
      final bool? doubleConfirm = await showCupertinoDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => CupertinoAlertDialog(
          title: Text(ctx.l10n.profileDeleteAccountFinalDialogTitle),
          content: Text(ctx.l10n.profileDeleteAccountFinalDialogBody),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.commonCancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.l10n.profileDeleteAccountTile),
            ),
          ],
        ),
      );
      if (doubleConfirm == true && context.mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!context.mounted) return;
        final bool? typedConfirm = await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) =>
              _DeleteAccountPhraseDialog(l10n: ctx.l10n),
        );
        if (typedConfirm == true && context.mounted) {
          try {
            await ServiceLocator.instance.authRepository.deleteAccount();
            if (!context.mounted) return;
            AppHaptics.success();
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.signIn,
              (Route<dynamic> route) => false,
            );
          } on AppError catch (e) {
            if (!context.mounted) return;
            AppSnack.show(
              context,
              message: e.message,
              type: AppSnackType.error,
            );
          }
        }
      }
    }
  }

  static Future<void> _performLogout(BuildContext context) async {
    await ServiceLocator.instance.authRepository.signOut();
    AppHaptics.success();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (Route<dynamic> route) => false,
    );
  }
}

class _DeleteAccountPhraseDialog extends StatefulWidget {
  const _DeleteAccountPhraseDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_DeleteAccountPhraseDialog> createState() =>
      _DeleteAccountPhraseDialogState();
}

class _DeleteAccountPhraseDialogState extends State<_DeleteAccountPhraseDialog> {
  late final TextEditingController _controller;
  late final String _phrase;

  @override
  void initState() {
    super.initState();
    _phrase = widget.l10n.profileDeleteAccountConfirmPhrase;
    _controller = TextEditingController();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _phraseMatches => _controller.text.trim() == _phrase;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.l10n.profileDeleteAccountTypeConfirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(widget.l10n.profileDeleteAccountTypeConfirmBody),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Text(
                  _phrase,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              label: widget.l10n.profileDeleteAccountTypeFieldPlaceholder,
              textField: true,
              child: CupertinoTextField(
                controller: _controller,
                placeholder: widget.l10n.profileDeleteAccountTypeFieldPlaceholder,
                autofocus: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                onSubmitted: (_) {
                  if (_phraseMatches) {
                    Navigator.of(context).pop(true);
                    return;
                  }
                  AppSnack.show(
                    context,
                    message: widget.l10n.profileDeleteAccountTypeMismatchSnack,
                    type: AppSnackType.warning,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.l10n.commonCancel),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: _phraseMatches
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(widget.l10n.profileDeleteAccountTile),
        ),
      ],
    );
  }
}
