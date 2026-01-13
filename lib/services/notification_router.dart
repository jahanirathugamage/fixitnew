// lib/services/notification_router.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationRouter {
  NotificationRouter._();
  static final NotificationRouter instance = NotificationRouter._();

  GlobalKey<NavigatorState>? _navKey;
  bool _initialized = false;

  /// If a tap arrives before navigator is ready, store it and retry later.
  RemoteMessage? _pending;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navKey = navigatorKey;

    if (_initialized) return;
    _initialized = true;

    // App opened from background by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App launched from terminated by tapping notification
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) _handleTap(msg);
    });

    // Try pending after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushPendingIfPossible();
    });
  }

  void _handleTap(RemoteMessage message) {
    // If navigator isn't ready yet, store and retry
    if (_navKey?.currentState == null) {
      _pending = message;
      _scheduleRetry();
      return;
    }

    _routeFromMessage(message);
  }

  void _flushPendingIfPossible() {
    final msg = _pending;
    if (msg == null) return;

    if (_navKey?.currentState == null) {
      _scheduleRetry();
      return;
    }

    _pending = null;
    _routeFromMessage(msg);
  }

  void _scheduleRetry() {
    // Retry shortly (AuthWrapper/FutureBuilders may still be building)
    Timer(const Duration(milliseconds: 250), _flushPendingIfPossible);
  }

  void _routeFromMessage(RemoteMessage message) {
    final nav = _navKey?.currentState;
    if (nav == null) {
      _pending = message;
      _scheduleRetry();
      return;
    }

    final data = message.data;
    final type = (data['type'] ?? '').toString().trim();
    final jobId = (data['jobId'] ?? '').toString().trim();

    // 1) Provider: client sent job request → open provider job details of that jobRequest
    if (type == 'provider_job_request' && jobId.isNotEmpty) {
      nav.pushNamed('/provider/job_details', arguments: jobId);
      return;
    }

    // 2) Client: provider accepted → go to Jobs page
    if (type == 'client_job_accepted') {
      nav.pushNamedAndRemoveUntil(
        '/dashboards/client/client_jobs',
        (route) => false,
      );
      return;
    }

    // 3) Client: provider declined → go to Job Requests page
    if (type == 'client_job_declined') {
      nav.pushNamedAndRemoveUntil(
        '/dashboards/client/client_job_requests',
        (route) => false,
      );
      return;
    }

    // Unknown payload → do nothing safely
  }
}
