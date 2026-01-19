// lib/services/notification_router.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationRouter {
  NotificationRouter._();
  static final NotificationRouter instance = NotificationRouter._();

  GlobalKey<NavigatorState>? _navKey;
  bool _initialized = false;

  RemoteMessage? _pending;

  // ✅ NEW: Image 5 trigger
  bool _pendingClientThankYou = false;

  bool consumeClientThankYou() {
    final v = _pendingClientThankYou;
    _pendingClientThankYou = false;
    return v;
  }

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navKey = navigatorKey;

    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) _handleTap(msg);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushPendingIfPossible();
    });
  }

  void _handleTap(RemoteMessage message) {
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
    final route = (data['route'] ?? '').toString().trim();

    // ✅ Prefer explicit route from backend
    if (route.isNotEmpty) {
      if (jobId.isNotEmpty) {
        nav.pushNamed(route, arguments: jobId);
      } else {
        nav.pushNamed(route);
      }
      return;
    }

    // ✅ Existing
    if (type == 'provider_job_request' && jobId.isNotEmpty) {
      nav.pushNamed('/provider/job_details', arguments: jobId);
      return;
    }

    if (type == 'client_job_accepted') {
      nav.pushNamedAndRemoveUntil('/dashboards/client/client_jobs', (r) => false);
      return;
    }

    if (type == 'client_job_declined') {
      nav.pushNamedAndRemoveUntil('/dashboards/client/client_job_requests', (r) => false);
      return;
    }

    // ✅ Quotation created → Client opens quotation screen
    if (type == 'client_quotation_created' && jobId.isNotEmpty) {
      nav.pushNamed('/client/quotation', arguments: jobId);
      return;
    }

    // ✅ Invoice created → Client opens invoice review screen
    if (type == 'client_invoice_created' && jobId.isNotEmpty) {
      nav.pushNamed('/client/invoice_review', arguments: jobId);
      return;
    }

    // ✅ Provider needs to confirm visitation fee / final payment
    if (type == 'provider_confirm_visitation_fee' && jobId.isNotEmpty) {
      nav.pushNamed('/provider/confirm_visitation_fee', arguments: jobId);
      return;
    }

    if (type == 'provider_confirm_final_payment' && jobId.isNotEmpty) {
      nav.pushNamed('/provider/confirm_final_payment', arguments: jobId);
      return;
    }

    // ✅ Client thank-you flow after provider confirms visitation fee
    if (type == 'client_visitation_fee_confirmed' ||
        type == 'visitation_fee_confirmed' ||
        type == 'client_thank_you') {
      _pendingClientThankYou = true;
      nav.pushNamedAndRemoveUntil('/dashboards/client/home_screen', (r) => false);
      return;
    }

    // ✅ Contractor routing back to jobs list
    if (type == 'contractor_quotation_accepted' || type == 'contractor_quotation_declined') {
      nav.pushNamedAndRemoveUntil('/dashboards/contractor/contractor_jobs_screen', (r) => false);
      return;
    }
  }
}
