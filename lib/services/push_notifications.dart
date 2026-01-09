// lib/services/push_notifications.dart

import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotifications {
  static Future<void> initForUser(String uid) async {
    final fm = FirebaseMessaging.instance;

    // Ask permission (Android mostly auto, but safe to call)
    await fm.requestPermission();

    // Subscribe to per-user topic
    await fm.subscribeToTopic("user_$uid");

    // OPTIONAL: debug token
    // final token = await fm.getToken();
    // print("FCM token: $token");
  }
}
