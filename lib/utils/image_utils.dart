// lib/utils/image_utils.dart
import 'dart:convert';
import 'dart:typed_data';

Uint8List? decodeBase64Image(String raw) {
  try {
    var s = raw.trim();
    if (s.isEmpty) return null;

    // If the string is a Data URI: "data:image/png;base64,...."
    final commaIndex = s.indexOf(',');
    if (s.startsWith('data:') && commaIndex != -1) {
      s = s.substring(commaIndex + 1);
    }

    // Remove any whitespace/newlines
    s = s.replaceAll(RegExp(r'\s+'), '');

    // Normalize URL-safe base64 variants
    s = s.replaceAll('-', '+').replaceAll('_', '/');

    // Add padding if missing
    final mod = s.length % 4;
    if (mod != 0) {
      s = s.padRight(s.length + (4 - mod), '=');
    }

    return base64Decode(s);
  } catch (_) {
    return null;
  }
}

bool looksLikeUrl(String? v) {
  if (v == null) return false;
  final s = v.trim().toLowerCase();
  return s.startsWith('http://') || s.startsWith('https://');
}
