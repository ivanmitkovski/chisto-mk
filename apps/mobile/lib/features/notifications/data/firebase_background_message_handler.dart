import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'package:chisto_mobile/features/notifications/data/push_background_processor.dart';
import 'package:chisto_mobile/firebase_options.dart';

/// FCM background isolate entry point. Must be top-level and registered in [main] before runApp.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await processBackgroundPushMessage(message);
}
