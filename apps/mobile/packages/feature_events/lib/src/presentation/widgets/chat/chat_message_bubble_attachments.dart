part of 'package:feature_events/src/presentation/widgets/chat/chat_message_bubble.dart';

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.attachments, this.onOpenMessageActions});
  final List<EventChatAttachment> attachments;
  final VoidCallback? onOpenMessageActions;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    if (attachments.length == 1) {
      return _buildSingle(context, attachments.first);
    }
    return _buildGrid(context);
  }

  Widget _buildSingle(BuildContext context, EventChatAttachment a) {
    final double aspectRatio =
        (a.width != null && a.height != null && a.height! > 0)
        ? a.width!.toDouble() / a.height!.toDouble()
        : 4 / 3;
    return Semantics(
      button: true,
      label: context.l10n.eventChatImageViewerTitle,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            unawaited(
              openChatImageGallery(
                context,
                attachments: attachments,
                initialIndex: attachments.indexOf(a),
              ),
            );
          },
          onLongPress: onOpenMessageActions,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: AspectRatio(
              aspectRatio: aspectRatio.clamp(0.5, 2.0),
              child: eventChatImageTile(a, cacheWidth: 600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int count = attachments.length.clamp(0, 4);
    final bool hasMore = attachments.length > 4;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(
        height: 160,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < count; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: () {
                      unawaited(
                        openChatImageGallery(
                          context,
                          attachments: attachments,
                          initialIndex: i,
                        ),
                      );
                    },
                    onLongPress: onOpenMessageActions,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        eventChatImageTile(attachments[i], cacheWidth: 300),
                        if (hasMore && i == count - 1)
                          Container(
                            color: AppColors.overlayMedium,
                            alignment: Alignment.center,
                            child: Text(
                              '+${attachments.length - count}',
                              style: AppTypography.galleryMoreCount(textTheme),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.attachment, this.onOpenMessageActions});
  final EventChatAttachment attachment;
  final VoidCallback? onOpenMessageActions;

  String _formatDuration(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? thumb = attachment.thumbnailUrl;
    final bool remoteVideo = isEventChatRemoteAttachmentUrl(attachment.url);
    return Semantics(
      button: true,
      label: context.l10n.eventChatVideoViewerTitle,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            unawaited(openChatVideoPlayer(context, videoUrl: attachment.url));
          },
          onLongPress: onOpenMessageActions,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  if (thumb != null && remoteVideo)
                    CachedNetworkImage(
                      imageUrl: thumb,
                      cacheKey:
                          '${eventChatAttachmentCacheKey(attachment)}_thumb',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180,
                    )
                  else if (!remoteVideo)
                    Container(
                      color: AppColors.mapDarkPaper,
                      width: double.infinity,
                      height: 180,
                      alignment: Alignment.center,
                      child: const Icon(
                        CupertinoIcons.videocam_fill,
                        size: 52,
                        color: AppColors.textMuted,
                      ),
                    )
                  else
                    Container(
                      color: AppColors.inputFill,
                      width: double.infinity,
                      height: 180,
                      child: const Icon(
                        CupertinoIcons.videocam_fill,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                    ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.overlayStrong,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.play_fill,
                      size: 28,
                      color: AppColors.white,
                    ),
                  ),
                  if (attachment.duration != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.overlayStrong,
                          borderRadius: AppRadii.xs,
                        ),
                        child: Text(
                          _formatDuration(attachment.duration!),
                          style: AppTypography.microLabel(
                            textTheme,
                          ).copyWith(color: AppColors.textOnDark),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatAudioInline extends StatelessWidget {
  const _ChatAudioInline({
    required this.clipKey,
    required this.attachment,
    required this.own,
    this.onOpenMessageActions,
  });

  final String clipKey;
  final EventChatAttachment attachment;
  final bool own;
  final VoidCallback? onOpenMessageActions;

  @override
  Widget build(BuildContext context) {
    final EventChatAudioPlaybackController? playback =
        EventChatAudioPlaybackScope.maybeOf(context);
    final bool playing =
        playback != null && playback.isActiveAndPlaying(clipKey);
    const double outer = 44;
    const double inner = 32;
    final String totalLabel = _ChatAudioTimeline.fmtDurationMmSs(
      attachment.duration,
    );
    final EventChatAudioPlaybackController? pb = playback;
    final Duration posForSemantics = (pb != null && pb.isActive(clipKey))
        ? pb.player.position
        : Duration.zero;

    return Semantics(
      button: playback != null,
      label:
          '${context.l10n.eventChatAudioExpandedTitle}. ${_ChatAudioTimeline.fmtDurationFromDuration(posForSemantics)} / $totalLabel',
      child: GestureDetector(
        onLongPress: onOpenMessageActions,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: playback == null
                    ? null
                    : () {
                        unawaited(playback.toggle(clipKey, attachment.url));
                      },
                child: SizedBox(
                  width: outer,
                  height: outer,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        width: outer,
                        height: outer,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.chatAttachmentBadge(),
                        ),
                      ),
                      Container(
                        width: inner,
                        height: inner,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          playing
                              ? CupertinoIcons.pause_fill
                              : CupertinoIcons.play_fill,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChatAudioTimeline(
                  clipKey: clipKey,
                  attachment: attachment,
                  own: own,
                  playback: playback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress track + elapsed / total while this clip is active; idle shows empty track and length.
class _ChatAudioTimeline extends StatelessWidget {
  const _ChatAudioTimeline({
    required this.clipKey,
    required this.attachment,
    required this.own,
    required this.playback,
  });

  final String clipKey;
  final EventChatAttachment attachment;
  final bool own;
  final EventChatAudioPlaybackController? playback;

  static String fmtDurationMmSs(int? seconds) {
    if (seconds == null || seconds < 0) {
      return '0:00';
    }
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String fmtDurationFromDuration(Duration d) {
    final int sec = d.inSeconds.clamp(0, 35999);
    return fmtDurationMmSs(sec);
  }

  static Duration _totalFromAttachment(EventChatAttachment a) {
    final int? s = a.duration;
    if (s != null && s > 0) {
      return Duration(seconds: s);
    }
    return Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    final Color timeColor = own
        ? AppColors.primary.withValues(alpha: 0.92)
        : AppColors.textSecondary;
    final Color trackBg = own
        ? AppColors.primary.withValues(alpha: 0.22)
        : AppColors.inputFill;
    const Color trackFg = AppColors.primary;
    final TextTheme audioTextTheme = Theme.of(context).textTheme;
    final TextStyle timeStyle =
        AppTypography.eventsChatTimestamp(audioTextTheme).copyWith(
          fontWeight: FontWeight.w600,
          color: timeColor,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        );

    final EventChatAudioPlaybackController? p = playback;
    final bool active = p != null && p.isActive(clipKey);
    if (!active) {
      final Duration total = _totalFromAttachment(attachment);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _AudioTimelineBar(
            progress: 0,
            trackBg: trackBg,
            trackFg: trackFg,
            seekable: false,
            onSeekFraction: null,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(fmtDurationFromDuration(Duration.zero), style: timeStyle),
              Text(fmtDurationFromDuration(total), style: timeStyle),
            ],
          ),
        ],
      );
    }

    final EventChatAudioPlaybackController ctrl = p;

    return StreamBuilder<Duration>(
      stream: ctrl.player.positionStream,
      initialData: ctrl.player.position,
      builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
        final Duration pos = snapshot.data ?? Duration.zero;
        Duration total =
            ctrl.player.duration ?? _totalFromAttachment(attachment);
        if (total <= Duration.zero) {
          total = _totalFromAttachment(attachment);
        }
        if (total <= Duration.zero) {
          total = const Duration(seconds: 1);
        }
        final double progress = (pos.inMilliseconds / total.inMilliseconds)
            .clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _AudioTimelineBar(
              progress: progress,
              trackBg: trackBg,
              trackFg: trackFg,
              seekable: true,
              onSeekFraction: (double fx) {
                final int ms = (total.inMilliseconds * fx.clamp(0.0, 1.0))
                    .round();
                unawaited(ctrl.player.seek(Duration(milliseconds: ms)));
              },
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(fmtDurationFromDuration(pos), style: timeStyle),
                Text(fmtDurationFromDuration(total), style: timeStyle),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AudioTimelineBar extends StatelessWidget {
  const _AudioTimelineBar({
    required this.progress,
    required this.trackBg,
    required this.trackFg,
    required this.seekable,
    required this.onSeekFraction,
  });

  final double progress;
  final Color trackBg;
  final Color trackFg;
  final bool seekable;
  final void Function(double fraction)? onSeekFraction;

  @override
  Widget build(BuildContext context) {
    final Widget bar = ClipRRect(
      borderRadius: AppRadii.chatMicro,
      child: AppLinearProgress(
        value: progress.clamp(0.0, 1.0),
        minHeight: 4,
        backgroundColor: trackBg,
        valueColor: trackFg,
      ),
    );

    if (!seekable || onSeekFraction == null) {
      return bar;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails d) {
            final double w = constraints.maxWidth;
            if (w <= 0) {
              return;
            }
            onSeekFraction!(d.localPosition.dx / w);
          },
          child: bar,
        );
      },
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({
    required this.attachment,
    required this.downloadRemote,
    this.onOpenMessageActions,
  });
  final EventChatAttachment attachment;
  final Future<Uint8List> Function(String url) downloadRemote;
  final VoidCallback? onOpenMessageActions;

  IconData _iconForMime(String mime) {
    if (mime.contains('pdf')) return CupertinoIcons.doc_text;
    if (mime.contains('word') || mime.contains('document')) {
      return CupertinoIcons.doc_richtext;
    }
    if (mime.contains('sheet') || mime.contains('excel')) {
      return CupertinoIcons.table;
    }
    if (mime.contains('presentation') || mime.contains('powerpoint')) {
      return CupertinoIcons.rectangle_stack;
    }
    return CupertinoIcons.doc;
  }

  String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.eventChatOpenFile,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            unawaited(
              openChatDocument(
                context,
                attachment,
                downloadRemote: downloadRemote,
              ),
            );
          },
          onLongPress: onOpenMessageActions,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  _iconForMime(attachment.mimeType),
                  size: 32,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eventsChatMessageBody(
                          Theme.of(context).textTheme,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _humanSize(attachment.sizeBytes),
                        style: AppTypography.eventsChatTimestamp(
                          Theme.of(context).textTheme,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.arrow_down_to_line,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Same Carto light raster tiles + cache as [PollutionMapScreen] / [CreateEventSitesMap].
class _LocationPreview extends StatelessWidget {
  const _LocationPreview({required this.lat, required this.lng, this.label});

  final double lat;
  final double lng;
  final String? label;

  static final LatLngBounds _cameraBounds = LatLngBounds(
    const LatLng(ReportGeoFence.minLat, ReportGeoFence.minLng),
    const LatLng(ReportGeoFence.maxLat, ReportGeoFence.maxLng),
  );

  @override
  Widget build(BuildContext context) {
    final LatLng point = LatLng(lat, lng);
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final bool highDpi = dpr > 1.0;

    return Semantics(
      button: true,
      label: '${context.l10n.eventChatLocationMapTitle}. ${label ?? ''}',
      child: Tooltip(
        message: context.l10n.eventChatLocationMapTitle,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: () {
              unawaited(
                openChatLocationFullscreen(
                  context,
                  lat: lat,
                  lng: lng,
                  label: label,
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 140,
                    child: IgnorePointer(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: point,
                          initialZoom: 15,
                          minZoom: 3,
                          maxZoom: 18,
                          backgroundColor: AppColors.mapLightPaper,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                          cameraConstraint: CameraConstraint.containCenter(
                            bounds: _cameraBounds,
                          ),
                        ),
                        children: <Widget>[
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                            subdomains: const <String>['a', 'b', 'c', 'd'],
                            maxNativeZoom: 20,
                            userAgentPackageName: 'chisto_mobile',
                            retinaMode: highDpi,
                            keepBuffer: 2,
                            panBuffer: 1,
                            tileProvider: createCachedTileProvider(
                              maxStaleDays: 30,
                            ),
                            tileDisplay: const TileDisplay.fadeIn(
                              duration: Duration(milliseconds: 220),
                              startOpacity: 0,
                            ),
                          ),
                          MarkerLayer(
                            markers: <Marker>[
                              Marker(
                                point: point,
                                width: 40,
                                height: 48,
                                alignment: Alignment.topCenter,
                                child: const Icon(
                                  CupertinoIcons.location_solid,
                                  size: 34,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                      left: AppSpacing.xxs,
                      right: AppSpacing.xxs,
                      bottom: 2,
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          CupertinoIcons.location,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            (label != null && label!.trim().isNotEmpty)
                                ? label!.trim()
                                : context.l10n.eventsDetailOpenInMaps,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.eventsGridPropertyValue(
                              Theme.of(context).textTheme,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
