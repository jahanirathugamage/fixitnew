// lib/backend/api_config.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // 🌐 Flutter Web (Chrome)
    if (kIsWeb) {
      return 'http://127.0.0.1:3000';
    }

    // 🧪 Debug / Profile (emulator or local dev)
    if (!kReleaseMode) {
      // Android emulator talks to host via 10.0.2.2
      return 'http://10.0.2.2:3000';
    }

    // 📱 RELEASE APK (REAL PHONE)
    // MUST be a reachable backend (Vercel / Render / Railway etc.)
    return 'https://fixit-backend-pink.vercel.app';
  }
}
