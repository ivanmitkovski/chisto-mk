import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Plain chat body with tappable http(s) and www. links.
class ChatLinkifiedText extends StatefulWidget {
  const ChatLinkifiedText({
    super.key,
    required this.text,
    required this.style,
    this.linkColor,
  });

  final String text;
  final TextStyle? style;
  final Color? linkColor;

  @override
  State<ChatLinkifiedText> createState() => _ChatLinkifiedTextState();
}

class _ChatLinkifiedTextState extends State<ChatLinkifiedText> {
  static final RegExp _url = RegExp(
    r'(https?://[^\s]+)|(www\.[^\s]+)',
    caseSensitive: false,
  );

  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];
  TextSpan? _root;

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatLinkifiedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.linkColor != widget.linkColor) {
      _disposeRecognizers();
      _root = null;
    }
  }

  void _disposeRecognizers() {
    for (final TapGestureRecognizer r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TextSpan _buildRoot() {
    final String text = widget.text;
    final TextStyle? base = widget.style;
    final Color linkColor = widget.linkColor ?? AppColors.primary;
    final Iterable<RegExpMatch> matches = _url.allMatches(text);

    if (matches.isEmpty) {
      return TextSpan(text: text, style: base);
    }

    final List<InlineSpan> spans = <InlineSpan>[];
    int start = 0;
    for (final RegExpMatch m in matches) {
      if (m.start > start) {
        spans.add(TextSpan(text: text.substring(start, m.start)));
      }
      final String raw = m.group(0)!;
      final String href = raw.startsWith('http') ? raw : 'https://$raw';
      final TapGestureRecognizer tap = TapGestureRecognizer()
        ..onTap = () async {
          AppHaptics.light(context);
          final Uri? uri = Uri.tryParse(href);
          if (uri == null || !context.mounted) {
            return;
          }
          try {
            final bool openedInApp =
                await launchUrl(uri, mode: LaunchMode.inAppWebView);
            if (!openedInApp && context.mounted) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } on Object {
            if (!context.mounted) {
              return;
            }
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } on Object {
              // No handler or user dismissed.
            }
          }
        };
      _recognizers.add(tap);
      spans.add(
        TextSpan(
          text: raw,
          style: base?.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
          ),
          recognizer: tap,
        ),
      );
      start = m.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return TextSpan(style: base, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    _root ??= _buildRoot();
    return Text.rich(_root!);
  }
}
