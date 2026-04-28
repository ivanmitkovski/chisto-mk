import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/upvoters_sheet_content.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';

/// Full-screen upvoters list (shell route: `/feed/:siteId/upvoters`).
class FeedSiteUpvotersRouteScreen extends StatefulWidget {
  const FeedSiteUpvotersRouteScreen({super.key, required this.siteId});

  final String siteId;

  @override
  State<FeedSiteUpvotersRouteScreen> createState() =>
      _FeedSiteUpvotersRouteScreenState();
}

class _FeedSiteUpvotersRouteScreenState extends State<FeedSiteUpvotersRouteScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(context.l10n.siteUpvotersSheetTitle),
      ),
      body: ColoredBox(
        color: AppColors.panelBackground,
        child: UpvotersSheetContent(
          siteId: widget.siteId,
          scrollController: _scrollController,
        ),
      ),
    );
  }
}
