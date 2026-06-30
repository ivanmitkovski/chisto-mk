part of 'package:feature_events/src/presentation/organizer_checkin/organizer_checkin_screen.dart';

class _OrganizerCheckInScreenState extends ConsumerState<OrganizerCheckInScreen>
    with WidgetsBindingObserver {
  EventsRepository get _eventsRepository => readEventsRepository();
  CheckInRepository get _checkInRepository => readCheckInRepository();
  final OrganizerEndSoonLocalController _organizerEndSoonLocal =
      OrganizerEndSoonLocalController();
  late final OrganizerCheckInQrSessionController _qrSession;
  late final OrganizerCheckInWsCoordinator _wsCoordinator;
  late final OrganizerCheckInAttendeeCoordinator _attendeeCoordinator;
  late final OrganizerCheckInEventLifecycleCoordinator _eventLifecycle;
  PushNotificationService? _pushForLocalReminders;

  EcoEvent? get _eventOrNull => _eventsRepository.findById(widget.eventId);

  EcoEvent get _event => _eventOrNull!;

  List<CheckedInAttendee> get _attendees =>
      _attendeeCoordinator.visibleAttendees();

  void _refreshQrAfterVolunteerScan() {
    if (!mounted || !_checkInRepository.isOpen(_event.id)) {
      return;
    }
    unawaited(_qrSession.issueNewPayload());
  }

  String _mapCheckInAppError(AppError e) {
    final AppLocalizations l10n = context.l10n;
    if (e.code == 'UNAUTHORIZED') {
      return l10n.errorUserUnauthorized;
    }
    return localizedAppErrorMessage(l10n, e);
  }

  double _qrDisplaySize(BuildContext context) {
    final double shortest = MediaQuery.sizeOf(context).shortestSide;
    return (shortest * 0.62).clamp(260.0, 320.0);
  }

  Future<void> _ensureSession() async {
    final EcoEvent? ev = _eventOrNull;
    if (ev == null) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    try {
      await _checkInRepository.ensureSession(event: ev);
      await _checkInRepository.refreshAttendees(ev.id);
      if (!mounted) {
        return;
      }
      await _qrSession.issueNewPayload();
    } on AppError catch (e) {
      logEventsDiagnostic('organizer_checkin_session_setup_failed');
      if (!mounted) {
        return;
      }
      AppHaptics.warning();
      final String m = _mapCheckInAppError(e);
      _qrSession.setLoadError(
        m.trim().isNotEmpty ? m : l10n.eventsOrganizerSessionSetupFailed,
      );
    } on Object {
      logEventsDiagnostic('organizer_checkin_session_setup_failed');
      if (!mounted) {
        return;
      }
      AppHaptics.warning();
      _qrSession.setLoadError(l10n.eventsOrganizerSessionSetupFailed);
    }
  }

  void _onRepoChanged() {
    if (!mounted) {
      return;
    }
    void applyUpdate() {
      if (!mounted) {
        return;
      }
      setState(() {});
    }

    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
      return;
    }
    applyUpdate();
  }

  @override
  void initState() {
    _qrSession = OrganizerCheckInQrSessionController(
      eventId: widget.eventId,
      checkInRepository: _checkInRepository,
      eventsRepository: _eventsRepository,
      isMounted: () => mounted,
      isCheckInOpen: () => _eventOrNull?.isCheckInOpen ?? false,
      readL10n: () => context.l10n,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _attendeeCoordinator = OrganizerCheckInAttendeeCoordinator(
      eventId: widget.eventId,
      checkInRepository: _checkInRepository,
      isMounted: () => mounted,
      readContext: () => context,
      readEvent: () => _event,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      qrSession: _qrSession,
      mapCheckInAppError: _mapCheckInAppError,
    );
    _eventLifecycle = OrganizerCheckInEventLifecycleCoordinator(
      eventsRepository: _eventsRepository,
      checkInRepository: _checkInRepository,
      isMounted: () => mounted,
      readContext: () => context,
      readEvent: () => _event,
      readAttendeeCount: () => _attendees.length,
      qrSession: _qrSession,
      attendeeCoordinator: _attendeeCoordinator,
    );
    _wsCoordinator = OrganizerCheckInWsCoordinator(
      eventId: widget.eventId,
      checkInRepository: _checkInRepository,
      isMounted: () => mounted,
      readContext: () => context,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      onVolunteerScan: _refreshQrAfterVolunteerScan,
    );
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _eventsRepository.loadInitialIfNeeded();
    _eventsRepository.addListener(_onRepoChanged);
    _checkInRepository.addListener(_onRepoChanged);
    _wsCoordinator.connect(ref.read(appBootstrapProvider));
    if (_eventOrNull != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_ensureSession());
      });
    }
    _qrSession.startRefreshTicker();
    _attendeeCoordinator.startPollTimer();
    final AppBootstrap bootstrap = ref.read(appBootstrapProvider);
    if (bootstrap.isInitialized) {
      _pushForLocalReminders = ref.read(pushNotificationServiceProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventsRepository.removeListener(_onRepoChanged);
    _checkInRepository.removeListener(_onRepoChanged);
    _attendeeCoordinator.dispose();
    _qrSession.dispose();
    _wsCoordinator.dispose();
    final PushNotificationService? push = _pushForLocalReminders;
    if (push != null) {
      unawaited(_organizerEndSoonLocal.dispose(push));
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _attendeeCoordinator.onAppResumed();
      _qrSession.syncCountdownNotifier();
    }
  }

  @override
  Widget build(BuildContext context) {
    final EcoEvent? event = _eventOrNull;
    if (event == null) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.appBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              OrganizerCheckInHeader(title: context.l10n.eventsCheckInTitle),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      context.l10n.eventsEventNotFoundBody,
                      style: AppTypography.eventsBodyProse(
                        Theme.of(context).textTheme,
                      ).copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isOpen = event.isCheckInOpen;
    final List<CheckedInAttendee> attendees = _attendees;
    final double qrSize = _qrDisplaySize(context);
    final AppLocalizations l10n = context.l10n;

    if (ref.read(appBootstrapProvider).isInitialized) {
      unawaited(
        _organizerEndSoonLocal.sync(
          event: event,
          push: ref.read(pushNotificationServiceProvider),
          l10n: l10n,
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            OrganizerCheckInHeader(
              title: event.title.isNotEmpty
                  ? event.title
                  : context.l10n.eventsCheckInTitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (event.status == EcoEventStatus.inProgress)
                    Semantics(
                      label: l10n.eventsOrganizerExtendEndSemantic,
                      button: true,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: const Icon(
                          CupertinoIcons.clock_fill,
                          color: AppColors.primaryDark,
                        ),
                        onPressed: () => _eventLifecycle.openExtendEnd(event),
                      ),
                    ),
                  Semantics(
                    label: isOpen
                        ? l10n.eventsOrganizerPauseCheckIn
                        : l10n.eventsOrganizerResumeCheckIn,
                    button: true,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: Icon(
                        isOpen
                            ? CupertinoIcons.pause_circle
                            : CupertinoIcons.play_circle,
                        color: AppColors.primaryDark,
                      ),
                      onPressed: () =>
                          unawaited(_eventLifecycle.handlePauseResume()),
                    ),
                  ),
                  Semantics(
                    label: l10n.eventsOrganizerMoreActionsSemantic,
                    button: true,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: const Icon(
                        CupertinoIcons.ellipsis_circle,
                        color: AppColors.primaryDark,
                      ),
                      onPressed: () =>
                          unawaited(_eventLifecycle.showMoreActions()),
                    ),
                  ),
                ],
              ),
            ),
            if (_eventLifecycle.shouldShowEndSoonBanner(event)) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppBanner(
                      title: l10n.eventsEndSoonBannerTitle,
                      message: l10n.eventsEndSoonBannerBody,
                      icon: CupertinoIcons.clock_fill,
                      tone: AppSurfaceTone.accent,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppButton.text(
                        label: l10n.eventsEndSoonBannerExtend,
                        onPressed: () => _eventLifecycle.openExtendEnd(event),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.panelBackground,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusCard,
                              ),
                              border: Border.all(
                                color: AppColors.divider.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              boxShadow: AppShadows.card(
                                Theme.of(context).colorScheme,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.qrcode_viewfinder,
                                        size: 22,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        context
                                            .l10n
                                            .eventsOrganizerQrRefreshHelp,
                                        style:
                                            AppTypography.eventsBodyProse(
                                              textTheme,
                                            ).copyWith(
                                              color: AppColors.textSecondary,
                                              height: 1.45,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            context.l10n.eventsOrganizerHoldPhoneForScan,
                            style: AppTypography.eventsBodyMediumSecondary(
                              textTheme,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          RepaintBoundary(
                            child: ValueListenableBuilder<int>(
                              valueListenable: _qrSession.countdownSeconds,
                              builder: (BuildContext context, int sec, Widget? _) {
                                return PulsingQRContainer(
                                  isActive:
                                      isOpen && _qrSession.payload != null,
                                  pulseOnlyNearExpiry: true,
                                  remainingSecondsUntilExpiry:
                                      isOpen && _qrSession.payload != null
                                      ? sec
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.panelBackground,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusCard,
                                      ),
                                      border: Border.all(
                                        color: AppColors.divider.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                      boxShadow: AppShadows.card(
                                        Theme.of(context).colorScheme,
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: AppMotion.standard,
                                      switchInCurve: AppMotion.emphasized,
                                      switchOutCurve: AppMotion.emphasized,
                                      child: !isOpen
                                          ? SizedBox(
                                              key: const ValueKey<String>(
                                                'qr_paused',
                                              ),
                                              width: qrSize,
                                              height: qrSize,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Icon(
                                                    CupertinoIcons
                                                        .pause_circle_fill,
                                                    size: 42,
                                                    color: AppColors.textMuted
                                                        .withValues(alpha: 0.6),
                                                  ),
                                                  const SizedBox(
                                                    height: AppSpacing.sm,
                                                  ),
                                                  Text(
                                                    l10n.eventsOrganizerPausedLabel,
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                          color: AppColors
                                                              .textMuted,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : _qrSession.qrLoadError != null &&
                                                _qrSession.payload == null
                                          ? SizedBox(
                                              key: ValueKey<String>(
                                                'qr_err_$_qrSession.qrLoadError',
                                              ),
                                              width: qrSize,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  const Icon(
                                                    CupertinoIcons
                                                        .exclamationmark_circle,
                                                    size: 40,
                                                    color: AppColors
                                                        .accentWarningDark,
                                                  ),
                                                  const SizedBox(
                                                    height: AppSpacing.sm,
                                                  ),
                                                  Text(
                                                    _qrSession.qrLoadError!,
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(
                                                    height: AppSpacing.md,
                                                  ),
                                                  CupertinoButton(
                                                    onPressed: () {
                                                      unawaited(
                                                        _qrSession
                                                            .issueNewPayload(),
                                                      );
                                                    },
                                                    child: Text(
                                                      l10n.eventsOrganizerQrRetry,
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: AppColors
                                                                .primaryDark,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : _qrSession.payload != null
                                          ? TweenAnimationBuilder<double>(
                                              key: ValueKey<String>(
                                                _qrSession.payload!.nonce,
                                              ),
                                              tween: Tween<double>(
                                                begin: 0.92,
                                                end: 1,
                                              ),
                                              duration:
                                                  MediaQuery.disableAnimationsOf(
                                                    context,
                                                  )
                                                  ? Duration.zero
                                                  : AppMotion.standard,
                                              curve: AppMotion.emphasized,
                                              builder:
                                                  (
                                                    BuildContext context,
                                                    double value,
                                                    Widget? child,
                                                  ) {
                                                    return Transform.scale(
                                                      scale: value,
                                                      child: Opacity(
                                                        opacity: value,
                                                        child: child,
                                                      ),
                                                    );
                                                  },
                                              child: EventCheckInQrCard(
                                                key: ValueKey<String>(
                                                  _qrSession.payload!.nonce,
                                                ),
                                                payload: _qrSession.payload!,
                                                qrSize: qrSize,
                                                semanticsLabel: l10n
                                                    .eventsOrganizerQrSemantics(
                                                      sec.clamp(0, 9999),
                                                    ),
                                                encodeErrorDescription: l10n
                                                    .eventsOrganizerQrEncodeError,
                                                retryLabel:
                                                    l10n.eventsOrganizerQrRetry,
                                                onRetryAfterEncodeError: () {
                                                  unawaited(
                                                    _qrSession
                                                        .issueNewPayload(),
                                                  );
                                                },
                                              ),
                                            )
                                          : SizedBox(
                                              key: const ValueKey<String>(
                                                'qr_loading',
                                              ),
                                              width: qrSize,
                                              height: qrSize,
                                              child: const Center(
                                                child:
                                                    CupertinoActivityIndicator(
                                                      radius: 16,
                                                    ),
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (isOpen &&
                              _qrSession.payload != null &&
                              _qrSession.qrLoadError != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    CupertinoIcons.exclamationmark_triangle,
                                    size: 14,
                                    color: AppColors.accentWarningDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      l10n.eventsOrganizerQrLoadFailedGeneric,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.accentWarningDark,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isOpen && _qrSession.payload != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text(
                                l10n.eventsOrganizerQrBrightnessHint,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.35,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Center(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      StatusPill(
                                        label: isOpen
                                            ? l10n.eventsOrganizerStatusOpen
                                            : l10n.eventsOrganizerStatusPaused,
                                        color: isOpen
                                            ? AppColors.primaryDark
                                            : AppColors.textMuted,
                                      ),
                                      if (isOpen &&
                                          _qrSession.payload !=
                                              null) ...<Widget>[
                                        const SizedBox(width: AppSpacing.sm),
                                        ValueListenableBuilder<int>(
                                          valueListenable:
                                              _qrSession.countdownSeconds,
                                          builder:
                                              (
                                                BuildContext context,
                                                int sec,
                                                Widget? _,
                                              ) {
                                                return StatusPill(
                                                  label: l10n
                                                      .eventsOrganizerRefreshInSeconds(
                                                        sec,
                                                      ),
                                                  color: sec <= 3
                                                      ? AppColors.error
                                                      : sec <= 10
                                                      ? AppColors
                                                            .accentWarningDark
                                                      : AppColors.textPrimary,
                                                );
                                              },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                isOpen
                                    ? l10n.eventsOrganizerQrRefreshesWhenOpen
                                    : l10n.eventsOrganizerResumeForFreshQr,
                                style: AppTypography.eventsSupportingCaption(
                                  textTheme,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              AppButton.secondary(
                                label:
                                    context.l10n.eventsOrganizerManualOverride,
                                onPressed: () => unawaited(
                                  _attendeeCoordinator.addManualAttendee(),
                                ),
                                expand: true,
                                leadingIcon: const Icon(
                                  CupertinoIcons
                                      .person_crop_circle_badge_checkmark,
                                  size: 20,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              if (_qrSession.payload != null) ...<Widget>[
                                const SizedBox(height: AppSpacing.sm),
                                AppButton.outlined(
                                  label: context.l10n.eventsOrganizerCopyQrText,
                                  onPressed: () => unawaited(
                                    _eventLifecycle.copyQrToClipboard(),
                                  ),
                                  expand: true,
                                  leadingIcon: const Icon(
                                    CupertinoIcons.doc_on_clipboard,
                                    size: 20,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._buildCheckedInAttendeeSlivers(
                    context,
                    textTheme,
                    attendees,
                    l10n,
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
