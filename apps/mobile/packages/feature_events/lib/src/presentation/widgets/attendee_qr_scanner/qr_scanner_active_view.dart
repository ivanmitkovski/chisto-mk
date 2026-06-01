part of 'package:feature_events/src/presentation/screens/attendee_qr_scanner_screen.dart';

extension QrScannerActiveView on _AttendeeQrScannerScreenState {
  Widget buildQrScannerActiveBody(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    return PopScope(
      canPop: !_processing,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          leading: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Center(
              child: AppBackButton(
                backgroundColor: AppColors.white.withValues(alpha: 0.14),
                iconColor: AppColors.white,
              ),
            ),
          ),
          title: Text(
            context.l10n.qrScannerAppBarTitle,
            style: AppTypography.eventsHeroCardTitle(textTheme).copyWith(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final Rect scanRect = _stableScanRect(w, h, bottomSafe);
            final double side = scanRect.width;

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (widget.scannerTestSlotBuilder != null)
                  Positioned.fill(
                    child: ColoredBox(
                      color: AppColors.black,
                      child: widget.scannerTestSlotBuilder!(
                        context,
                        (String raw) => unawaited(_submitRawCode(raw)),
                      ),
                    ),
                  )
                else
                  Semantics(
                    label: context.l10n.qrScannerPointCameraHint,
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _handleBarcode,
                      placeholderBuilder: attendeeQrScannerLoadingLayer,
                      errorBuilder: _scannerErrorLayer,
                      tapToFocus: false,
                      scanWindow: kIsWeb ? null : scanRect,
                      scanWindowUpdateThreshold: 48,
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: AttendeeQrDimOutsideScanPainter(
                        scanRect: scanRect,
                        overlayColor: AppColors.black.withValues(alpha: 0.5),
                        holeRadius: _AttendeeQrScannerScreenState
                            ._scanFrameCornerRadius,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: scanRect.left,
                  top: scanRect.top,
                  width: scanRect.width,
                  height: scanRect.height,
                  child: Semantics(
                    container: true,
                    label: context.l10n.qrScannerPointCameraHint,
                    child: IgnorePointer(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          CustomPaint(
                            size: Size.square(side),
                            painter: AttendeeQrSquareScanFramePainter(
                              color: AppColors.primary.withValues(alpha: 0.95),
                              strokeWidth: 3,
                              cornerRadius: _AttendeeQrScannerScreenState
                                  ._scanFrameCornerRadius,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _scanLineController,
                            builder: (BuildContext context, Widget? child) {
                              final double t = _scanLineController.value;
                              const double inset = 10;
                              final double travel = math.max(
                                0,
                                side - 2 * inset - 4,
                              );
                              final double top = inset + t * travel;
                              return Positioned(
                                left: inset,
                                right: inset,
                                top: top,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.85,
                                    ),
                                    boxShadow: AppShadows.qrScannerCorner(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.md,
                  child: IgnorePointer(
                    child: attendeeQrScannerGlassChip(
                      context,
                      icon: CupertinoIcons.qrcode_viewfinder,
                      text: context.l10n.qrScannerPointCameraHint,
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: bottomSafe + AppSpacing.md,
                  child: SafeArea(
                    top: false,
                    child: attendeeQrScannerGlassBottomPanel(
                      context,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_feedback != null) ...<Widget>[
                            Text(
                              _feedback!,
                              style:
                                  AppTypography.eventsChatMessageBody(
                                    textTheme,
                                  ).copyWith(
                                    color:
                                        (_lastFeedbackStatus == null ||
                                            _AttendeeQrScannerScreenState._isRecoverableScannerStatus(
                                              _lastFeedbackStatus!,
                                            ))
                                        ? AppColors.accentWarning
                                        : AppColors.accentDanger,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: <Widget>[
                              Semantics(
                                button: true,
                                label: context.l10n.qrScannerEnterManually,
                                child: CupertinoButton(
                                  onPressed: _openManualEntry,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  minimumSize: const Size.square(
                                    AppSpacing.avatarMd,
                                  ),
                                  child: Text(
                                    context.l10n.qrScannerEnterManually,
                                    style: AppTypography.eventsCaptionStrong(
                                      textTheme,
                                      color: AppColors.textOnDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: context.l10n.qrScannerRetryCamera,
                                child: CupertinoButton(
                                  onPressed: _restartScanner,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  minimumSize: const Size.square(
                                    AppSpacing.avatarMd,
                                  ),
                                  child: Text(
                                    context.l10n.qrScannerRetryCamera,
                                    style: AppTypography.eventsCaptionStrong(
                                      textTheme,
                                      color: AppColors.textOnDarkMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _cameraReady
                                ? context.l10n.qrScannerHintFreshQr
                                : context.l10n.qrScannerHintCameraBlocked,
                            style: AppTypography.eventsHeroCardMeta(textTheme)
                                .copyWith(
                                  color: AppColors.white.withValues(
                                    alpha: 0.55,
                                  ),
                                  height: 1.35,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_processing)
                  Semantics(
                    label: context.l10n.qrScannerCheckingIn,
                    child: ColoredBox(
                      color: AppColors.black.withValues(alpha: 0.52),
                      child: Center(
                        child: attendeeQrScannerProcessingHud(context),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
