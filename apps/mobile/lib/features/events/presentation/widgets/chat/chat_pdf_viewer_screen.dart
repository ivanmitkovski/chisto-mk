import 'dart:typed_data';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class ChatPdfViewerScreen extends StatefulWidget {
  const ChatPdfViewerScreen({
    super.key,
    required this.bytes,
    required this.title,
  });

  final Uint8List bytes;
  final String title;

  @override
  State<ChatPdfViewerScreen> createState() => _ChatPdfViewerScreenState();
}

class _ChatPdfViewerScreenState extends State<ChatPdfViewerScreen> {
  late final PdfControllerPinch _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(widget.bytes),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        ),
      ),
      body: _failed
          ? Center(child: Text(context.l10n.eventChatPdfOpenFailed))
          : PdfViewPinch(
              controller: _controller,
              onDocumentError: (_) {
                if (mounted) {
                  setState(() => _failed = true);
                }
              },
            ),
    );
  }
}
