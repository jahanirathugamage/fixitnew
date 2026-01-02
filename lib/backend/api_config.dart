// lib/backend/api_config.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // 🌐 Flutter Web (Chrome)
    if (kIsWeb) {
      return 'https://fixit-backend-pink.vercel.app';
    }

    if (!kReleaseMode) {
      return 'http://10.0.2.2:3000';
    }

    return 'https://fixit-backend-pink.vercel.app';
  }
}
