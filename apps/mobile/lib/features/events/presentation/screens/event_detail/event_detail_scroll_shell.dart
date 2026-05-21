part of 'package:chisto_mobile/features/events/presentation/screens/event_detail_screen.dart';

extension EventDetailScrollShell on _EventDetailScreenState {
  Widget buildEventDetailScrollShell(BuildContext context) {
    final EcoEvent? event = _eventsStore.findById(widget.eventId);

    if (!_detailPrefetchDone && event == null) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: const AppBackButton(),
          title: Text(context.l10n.authLoading),
        ),
        body: AnimatedPhaseSwitcher(
          phaseKey: 'skeleton',
          child: const EventDetailSkeleton(),
        ),
      );
    }

    if (event == null || _detailMissing) {
      return Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          leading: const AppBackButton(),
          title: Text(context.l10n.eventsEventNotFoundTitle),
        ),
        body: const EventDetailNotFoundView(),
      );
    }

    final double scrollBottomInset = _scrollBottomInset(context, event);

    final AppBootstrap bootstrap = readRoot(appBootstrapProvider);
    if (bootstrap.isInitialized) {
      unawaited(
        _organizerEndSoonLocal.sync(
          event: event,
          push: readRoot(pushNotificationServiceProvider),
          l10n: context.l10n,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Semantics(
        label: context.l10n.eventsDetailSemanticsLabel(event.title),
        child: Stack(
          children: <Widget>[
            AppRefreshIndicator(
              onRefresh: _handlePullToRefresh,
              child: CustomScrollView(
                controller: _detailScrollController,
                physics: eventDetailScrollPhysics(context),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: <Widget>[
                  HeroImageBar(
                      event: event,
                      innerBoxIsScrolled: _heroCollapsedEnoughForBodyScroll,
                      enableThumbnailHero: widget.enableThumbnailHero,
                      onEdit:
                          event.isOrganizer &&
                              (event.status == EcoEventStatus.upcoming ||
                                  event.status == EcoEventStatus.inProgress)
                          ? () {
                              AppHaptics.tap();
                              _openEditEvent(event);
                            }
                          : null,
                      onOpenEventChat: _canOpenEventChat(event)
                          ? () => _openEventChat(event)
                          : null,
                      eventChatUnreadCount: _chatUnreadCount,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          kEventDetailBodyHorizontalGutter,
                          kEventDetailBodyHorizontalGutter,
                          kEventDetailBodyHorizontalGutter,
                          scrollBottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                          if (_showStaleDetailBanner) ...<Widget>[
                            Semantics(
                              container: true,
                              label:
                                  '${context.l10n.eventsDetailCouldNotRefresh}. ${context.l10n.eventsDetailRetryRefresh}',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  ReportInfoBanner(
                                    message: context
                                        .l10n
                                        .eventsDetailCouldNotRefresh,
                                    icon: CupertinoIcons
                                        .exclamationmark_circle_fill,
                                    tone: ReportSurfaceTone.warning,
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: AppButton.text(
                                      label: context.l10n.eventsDetailRetryRefresh,
                                      onPressed: () =>
                                          unawaited(_retryDetailRefresh()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (event.isDeclined &&
                              event.isOrganizer) ...<Widget>[
                            ReportInfoBanner(
                              title: context.l10n.eventsDeclinedBannerTitle,
                              message: context.l10n.eventsDeclinedBannerBody,
                              icon: CupertinoIcons.xmark_circle_fill,
                              tone: ReportSurfaceTone.danger,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ] else if (!event.moderationApproved &&
                              event.isOrganizer) ...<Widget>[
                            ReportInfoBanner(
                              title: context.l10n.eventsModerationBannerTitle,
                              message: context.l10n.eventsModerationBannerBody,
                              icon: CupertinoIcons.info_circle_fill,
                              tone: ReportSurfaceTone.accent,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          if (!event.moderationApproved &&
                              !event.isOrganizer) ...<Widget>[
                            ReportInfoBanner(
                              title: context
                                  .l10n
                                  .eventsAttendeeModerationBannerTitle,
                              message: context
                                  .l10n
                                  .eventsAttendeeModerationBannerBody,
                              icon: CupertinoIcons.hourglass,
                              tone: ReportSurfaceTone.accent,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          if (_shouldShowOrganizerEndSoonBanner(
                            event,
                          )) ...<Widget>[
                            ReportInfoBanner(
                              title: context.l10n.eventsEndSoonBannerTitle,
                              message: context.l10n.eventsEndSoonBannerBody,
                              icon: CupertinoIcons.clock_fill,
                              tone: ReportSurfaceTone.accent,
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: AppButton.text(
                                label: context.l10n.eventsEndSoonBannerExtend,
                                onPressed: () => _openExtendCleanupEnd(event),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          DetailContent(
                            event: event,
                            onToggleReminder: () =>
                                _handleToggleReminder(event),
                            onExportCalendar: () => _handleAddToCalendar(event),
                            feedbackSnapshot: _feedbackSnapshot,
                            onEditFeedback: () => _editFeedback(event),
                            onImageTap: (int index) =>
                                _openFullscreenGallery(context, event, index),
                            onOpenSeriesOccurrence: (String id) {
                              if (id == widget.eventId) {
                                return;
                              }
                              EventsNavigation.replaceDetail(
                                context,
                                eventId: id,
                              );
                            },
                            onSaveBagsCollected:
                                event.isOrganizer &&
                                    event.status == EcoEventStatus.completed
                                ? (int bags) => _saveBagsCollected(event, bags)
                                : null,
                            onOpenImpactReceipt: event.status == EcoEventStatus.inProgress ||
                                    event.status == EcoEventStatus.completed
                                ? () => EventsNavigation.openImpactReceipt(
                                      context,
                                      eventId: event.id,
                                    )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            StickyBottomCTA(
              event: event,
              isPrimaryLoading: _ctaMutationBusy,
              onToggleJoin: () => _handleToggleJoin(event),
              onToggleReminder: () => _handleToggleReminder(event),
              onStartEvent: () => _handleStartEvent(event),
              onManageCheckIn: () => _handleManageCheckIn(event),
              onOpenAttendeeCheckIn: () => _handleOpenAttendeeCheckIn(event),
              onOpenCleanupEvidence: () => _handleOpenCleanupEvidence(event),
              onExtendCleanupEnd: () => _openExtendCleanupEnd(event),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreenGallery(
    BuildContext context,
    EcoEvent event,
    int index,
  ) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => FullscreenGalleryPage(
          event: event,
          initialIndex: index,
        ),
      ),
    );
  }
}
