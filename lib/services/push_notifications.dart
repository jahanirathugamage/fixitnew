// lib/services/push_notifications.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushNotifications {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initForUser(String uid) async {
    final fm = FirebaseMessaging.instance;

    await fm.requestPermission();
    await fm.subscribeToTopic("user_$uid");

    // ✅ Handle notification taps (background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // ✅ Handle notification taps (terminated)
    final initial = await fm.getInitialMessage();
    if (initial != null) {
      _handleMessage(initial);
    }
  }

  static void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final route = (data["route"] ?? "").toString().trim();
    final jobId = (data["jobId"] ?? "").toString().trim();

    if (route.isEmpty) return;

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    // If route needs a jobId, pass it. Otherwise just navigate.
    if (jobId.isNotEmpty) {
      nav.pushNamed(route, arguments: jobId);
    } else {
      nav.pushNamed(route);
    }
  }
}
