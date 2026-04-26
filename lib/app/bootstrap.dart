import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/app/app.dart';
import 'package:mavikalem_app/core/env/app_env.dart';
import 'package:mavikalem_app/features/notifications/presentation/services/fcm_notification_service.dart';
import 'package:mavikalem_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final fcmNotificationService = FcmNotificationService();
  await fcmNotificationService.init();
  await AppEnv.load();
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: WarehouseApp()));
}
