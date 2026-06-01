part of 'package:feature_events/src/presentation/screens/event_chat_screen.dart';

extension EventChatAppBarMixin on _EventChatScreenState {
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (_searchOpen) {
      // Custom toolbar: Material AppBar + TextField title can lay out under the
      // status bar / Dynamic Island on iOS; explicit top inset matches safe area.
      final double topInset = MediaQuery.paddingOf(context).top;
      return PreferredSize(
        preferredSize: Size.fromHeight(topInset + kToolbarHeight),
        child: Material(
          color: AppColors.appBackground,
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.only(top: topInset),
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: <Widget>[
                  Semantics(
                    button: true,
                    label: context.l10n.semanticClose,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: context.l10n.semanticClose,
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        _searchDebounce?.cancel();
                        _searchSerial++;
                        rebuildState(() {
                          _searchOpen = false;
                          _searchServerHits = <EventChatMessage>[];
                          _searchController.clear();
                          _lastSearchQuery = '';
                          _searchError = false;
                          _searchLoading = false;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: DesignSystemTextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: context.l10n.eventChatSearchHint,
                        border: InputBorder.none,
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: (String v) =>
                          unawaited(_runSearch(v.trim())),
                    ),
                  ),
                  if (_searchLoading)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: AppLoadingIndicator(
                          size: AppLoadingIndicatorSize.sm,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () =>
                          unawaited(_runSearch(_searchController.text.trim())),
                      tooltip: context.l10n.eventChatSearchAction,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: AppColors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.appBackground.withValues(alpha: 0.78),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
      ),
      leading: const AppBackButton(),
      title: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final TextTheme appBarTextTheme = Theme.of(context).textTheme;
          final String effectiveTitle = _resolvedEventTitle.isNotEmpty
              ? _resolvedEventTitle
              : widget.eventTitle;
          final String titleText = effectiveTitle.trim().isEmpty
              ? context.l10n.eventChatTitle
              : effectiveTitle.trim();
          final int count = _participantCount;
          return Semantics(
            button: true,
            label: context.l10n.eventChatParticipantsTitleSemantic(
              titleText,
              count,
            ),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: () {
                  unawaited(
                    showChatParticipantsSheet(
                      context: context,
                      eventId: widget.eventId,
                      repo: _repo,
                      initialParticipants:
                          List<EventChatParticipantPreview>.from(
                            _participantPreviews,
                          ),
                      initialCount: _participantCount,
                      currentUserId: _auth.userId,
                      initialLoadFailed:
                          _participantsLoadFailed &&
                          _participantPreviews.isEmpty,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 44,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              titleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.eventsListCardTitle(
                                appBarTextTheme,
                              ),
                            ),
                            if (count > 0)
                              Text(
                                context.l10n.eventChatParticipantsCount(count),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.eventsChatTimestamp(
                                  appBarTextTheme,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: context.l10n.eventChatSearchAction,
          onPressed: () => rebuildState(() => _searchOpen = true),
        ),
        IconButton(
          icon: Icon(
            _muted
                ? Icons.notifications_off_outlined
                : Icons.notifications_outlined,
          ),
          tooltip: _muted
              ? context.l10n.eventChatUnmuteNotifications
              : context.l10n.eventChatMuteNotifications,
          onPressed: _muteBusy ? null : () => unawaited(_toggleMute()),
        ),
      ],
    );
  }
}
