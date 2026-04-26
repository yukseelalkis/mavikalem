import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mavikalem_app/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint(
    'FCM background message received: ${message.messageId}, data: ${message.data}',
  );
}

final class FcmNotificationService {
  FcmNotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final StreamController<RemoteMessage> _foregroundController =
      StreamController<RemoteMessage>.broadcast();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  Stream<RemoteMessage> get foregroundMessages => _foregroundController.stream;

  Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    final token = await _messaging.getToken();
    debugPrint('FCM token: $token');

    await _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'FCM foreground message received: ${message.messageId}, data: ${message.data}',
      );
      _foregroundController.add(message);
    });
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _foregroundController.close();
  }
}
