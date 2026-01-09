// lib/backend/api_config.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // ✅ Allow overriding base URL at build/run time:
    // flutter run --dart-define=API_BASE_URL=https://your-vercel-domain.vercel.app
    // flutter build apk --release --dart-define=API_BASE_URL=https://your-vercel-domain.vercel.app
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;

    // 🌐 Flutter Web (Chrome)
    if (kIsWeb) {
      return 'https://fixit-backend-pink.vercel.app';
    }

    // 🤖 Android emulator debug
    if (!kReleaseMode) {
      return 'http://10.0.2.2:3000';
    }

    // 📦 Release (APK)
    return 'https://fixit-backend-pink.vercel.app';
  }
}
