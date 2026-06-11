part of 'push_notification_service.dart';

mixin PushNotificationLocal {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;
  EventChatNotificationDetails? _eventChatNotificationDetails;
  bool _timezoneInitialized = false;
  StreamSubscription<RemoteMessage>? _firebaseOnMessageSub;
  StreamSubscription<RemoteMessage>? _firebaseOnMessageOpenedAppSub;
  StreamSubscription<String>? _firebaseOnTokenRefreshSub;
  bool _tokenRefreshListenerAttached = false;
  bool _firebaseReady = false;
  static const String _organizerEndSoonChannelId =
      'chisto_organizer_cleanup_ending_soon';
  static const String _attendeeReminderChannelId =
      'chisto_event_attendee_reminder';

  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _notificationTapController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _localNotificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  Future<void> _initLocalNotifications({Locale? appLanguageOverride}) async {
    if (_localNotificationsInitialized) {
      return;
    }
    final Locale effectiveLocale = resolveAppLocale(
      override: appLanguageOverride,
      platformLocales: PlatformDispatcher.instance.locales,
    );
    final AppLocalizations strings = lookupAppLocalizations(effectiveLocale);
    final List<AndroidNotificationChannel> channels =
        buildPushAndroidNotificationChannels(strings);

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      for (final AndroidNotificationChannel c in channels) {
        await android?.createNotificationChannel(c);
      }
    }

    _eventChatNotificationDetails = EventChatNotificationDetails(
      androidChannel: PushNotificationPayload.resolveAndroidChannel(
        'EVENT_CHAT',
        strings: strings,
      ),
      replyActionTitle: strings.eventChatPushReplyAction,
      replyInputLabel: strings.eventChatPushReplyPlaceholder,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: EventChatNotificationDetails.darwinCategories(
            replyTitle: strings.eventChatPushReplyAction,
            replyButtonTitle: strings.eventChatPushReplyButton,
            replyPlaceholder: strings.eventChatPushReplyPlaceholder,
          ),
        );

    await _localNotifications.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final bool handledReply =
            await EventChatPushReplyService.handleNotificationResponse(
              response,
              mainIsolate: true,
            );
        if (handledReply) {
          return;
        }
        final Map<String, dynamic>? data = _decodeNotificationPayload(
          response.payload,
        );
        if (data != null) {
          _localNotificationTapController.add(data);
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          onEventChatPushBackgroundNotificationResponse,
    );
    _localNotificationsInitialized = true;
  }

  Future<void> _consumeLocalNotificationLaunchReply() async {
    final NotificationAppLaunchDetails? details = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) {
      return;
    }
    final NotificationResponse? response = details?.notificationResponse;
    if (response == null) {
      return;
    }
    final bool handledReply =
        await EventChatPushReplyService.handleNotificationResponse(
          response,
          mainIsolate: true,
        );
    if (handledReply) {
      return;
    }
    final Map<String, dynamic>? data = _decodeNotificationPayload(
      response.payload,
    );
    if (data != null) {
      _localNotificationTapController.add(data);
    }
  }

  Future<void> _ensureTimezoneInitialized() async {
    if (_timezoneInitialized) {
      return;
    }
    tzdata.initializeTimeZones();
    _timezoneInitialized = true;
  }

  int _organizerEndSoonNotificationId(String eventId) {
    final String hex = eventId.replaceAll('-', '');
    if (hex.length >= 8) {
      return int.parse(hex.substring(0, 8), radix: 16);
    }
    return eventId.hashCode & 0x3fffffff;
  }

  Future<void> scheduleOrganizerCleanupEndingSoon({
    required String eventId,
    required DateTime fireAtUtc,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    try {
      await _initLocalNotifications();
      await _ensureTimezoneInitialized();
      final DateTime utcNow = DateTime.now().toUtc();
      if (!fireAtUtc.toUtc().isAfter(utcNow.add(const Duration(seconds: 2)))) {
        return;
      }
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            _localNotifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        await android?.createNotificationChannel(
          AndroidNotificationChannel(
            _organizerEndSoonChannelId,
            channelName,
            description: channelDescription,
            importance: Importance.defaultImportance,
          ),
        );
      }
      final int id = _organizerEndSoonNotificationId(eventId);
      final tz.TZDateTime scheduled = tz.TZDateTime.from(
        fireAtUtc.toUtc(),
        tz.UTC,
      );
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _organizerEndSoonChannelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: PushNotificationPayload.encodePayload(<String, dynamic>{
          'type': 'CLEANUP_EVENT',
          'eventId': eventId,
        }),
      );
    } on Object catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Organizer end-soon schedule failed: $e');
      }
    }
  }

  Future<void> cancelOrganizerCleanupEndingSoon(String eventId) async {
    try {
      await _initLocalNotifications();
      final int id = _organizerEndSoonNotificationId(eventId);
      await _localNotifications.cancel(id);
    } on Object catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Organizer end-soon cancel failed: $e');
      }
    }
  }

  int _attendeeReminderNotificationId(String eventId) =>
      _organizerEndSoonNotificationId(eventId) ^ 0x5a5a5a5a;

  Future<void> scheduleEventAttendeeReminder({
    required String eventId,
    required DateTime fireAtUtc,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    try {
      await _initLocalNotifications();
      await _ensureTimezoneInitialized();
      final DateTime utcNow = DateTime.now().toUtc();
      if (!fireAtUtc.toUtc().isAfter(utcNow.add(const Duration(seconds: 2)))) {
        return;
      }
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            _localNotifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        await android?.createNotificationChannel(
          AndroidNotificationChannel(
            _attendeeReminderChannelId,
            channelName,
            description: channelDescription,
            importance: Importance.defaultImportance,
          ),
        );
      }
      final int id = _attendeeReminderNotificationId(eventId);
      final tz.TZDateTime scheduled = tz.TZDateTime.from(
        fireAtUtc.toUtc(),
        tz.UTC,
      );
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _attendeeReminderChannelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: PushNotificationPayload.encodePayload(<String, dynamic>{
          'type': 'CLEANUP_EVENT',
          'eventId': eventId,
        }),
      );
    } on Object catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Attendee reminder schedule failed: $e');
      }
    }
  }

  Future<void> cancelEventAttendeeReminder(String eventId) async {
    try {
      await _initLocalNotifications();
      final int id = _attendeeReminderNotificationId(eventId);
      await _localNotifications.cancel(id);
    } on Object catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Attendee reminder cancel failed: $e');
      }
    }
  }

  Future<NotificationSettings?> getOsNotificationSettings() async {
    if (!_firebaseReady) return null;
    return FirebaseMessaging.instance.getNotificationSettings();
  }

  Future<bool> hasUsableAlertPermission() async {
    final NotificationSettings? settings = await getOsNotificationSettings();
    if (settings == null) return false;
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return false;
    }
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return settings.alert == AppleNotificationSetting.enabled;
  }

  Future<void> _configureHandlers() async {
    await teardownFirebaseListeners();
    _firebaseOnMessageSub = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Foreground message: ${message.messageId}');
      }
      _foregroundMessageController.add(message);
      unawaited(_presentForegroundNotification(message));
    });

    _firebaseOnMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage message) {
          if (kDebugMode) {
            AppLog.verbose(
              '[Push] Opened from background: ${message.messageId}',
            );
          }
          _notificationTapController.add(message);
        });
  }

  Future<void> teardownFirebaseListeners() async {
    await _firebaseOnMessageSub?.cancel();
    _firebaseOnMessageSub = null;
    await _firebaseOnMessageOpenedAppSub?.cancel();
    _firebaseOnMessageOpenedAppSub = null;
    await _firebaseOnTokenRefreshSub?.cancel();
    _firebaseOnTokenRefreshSub = null;
    _tokenRefreshListenerAttached = false;
  }

  Future<void> consumePendingLaunchNotificationImpl() async {
    if (!_firebaseReady) return;

    RemoteMessage? initialMessage;
    try {
      initialMessage = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(seconds: 2));
    } on Object {
      initialMessage = null;
    }
    if (initialMessage != null) {
      ColdStartCoordinator.instance.queueColdStartPush(initialMessage);
    }

    final PendingPushDrainResult pending =
        await PushBackgroundPendingStore.drainPending();
    if (pending.unreadCount != null) {
      publishNotificationsUnreadCount(pending.unreadCount!);
    }
    if (pending.inboxBump) {
      bumpNotificationsInboxRefreshTick();
    }
    final Map<String, dynamic>? tap = pending.tapPayload;
    if (initialMessage == null && tap != null && tap.isNotEmpty) {
      _localNotificationTapController.add(tap);
    }
  }

  Future<void> _presentForegroundNotification(RemoteMessage message) async {
    final String? type = message.data['type'] as String?;
    if (type == 'EVENT_CHAT') {
      final String? eventId = message.data['eventId'] as String?;
      if (eventId != null &&
          eventId.isNotEmpty &&
          EventChatForegroundScope.instance.isViewingEvent(eventId)) {
        return;
      }
    }
    if (!PushNotificationPayload.shouldPresentForegroundBanner(message)) {
      return;
    }
    if (!await hasUsableAlertPermission()) {
      return;
    }
    await _showForegroundBanner(message);
  }

  Future<void> _showForegroundBanner(RemoteMessage message) async {
    await _initLocalNotifications();

    final String? type = message.data['type'] as String?;
    if (type == 'EVENT_CHAT' && _eventChatNotificationDetails != null) {
      final Locale effectiveLocale = resolveAppLocale(
        override: null,
        platformLocales: PlatformDispatcher.instance.locales,
      );
      final AppLocalizations strings = lookupAppLocalizations(effectiveLocale);
      await EventChatLocalNotificationPresenter.show(
        _localNotifications,
        message: message,
        eventChatDetails: _eventChatNotificationDetails!,
        strings: strings,
      );
      return;
    }

    final ({String? title, String? body}) resolved =
        PushNotificationPayload.resolveTitleBody(message);
    final String? title = resolved.title;
    final String? body = resolved.body;
    if (title == null || title.isEmpty || body == null || body.isEmpty) {
      return;
    }

    final AndroidChannelInfo ch = PushNotificationPayload.resolveAndroidChannel(
      type,
    );
    final String? notificationId = message.data['notificationId'] as String?;
    final int androidId = notificationId != null && notificationId.isNotEmpty
        ? notificationId.hashCode & 0x3fffffff
        : (message.messageId?.hashCode ?? message.hashCode) & 0x3fffffff;
    try {
      await _localNotifications.show(
        androidId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            ch.id,
            ch.name,
            channelDescription: ch.description,
            importance: ch.importance,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: PushNotificationPayload.encodePayload(message.data),
      );
    } on Object catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Foreground show failed: $e');
      }
    }
  }

  Map<String, dynamic>? _decodeNotificationPayload(String? raw) =>
      PushNotificationPayload.decodePayload(raw);

  @visibleForTesting
  static ({String? title, String? body}) resolveNotificationTitleBodyForTest(
    RemoteMessage message,
  ) => PushNotificationPayload.resolveTitleBody(message);

  @visibleForTesting
  static String? encodeNotificationPayloadForTest(Map<String, dynamic> data) =>
      PushNotificationPayload.encodePayload(data);

  @visibleForTesting
  static Map<String, dynamic>? decodeNotificationPayloadForTest(String? raw) =>
      PushNotificationPayload.decodePayload(raw);
}
