import 'package:flutter/foundation.dart';

class ApiConfig {
  // Safe default local IP. Can be overridden at compile-time with:
  // flutter run --dart-define=API_URL=http://YOUR_PC_IP:5000/api
  static const String _defaultRenderUrl = 'https://service-app-final.onrender.com';

  static String get baseUrl => 
      const String.fromEnvironment('API_URL', defaultValue: '$_defaultRenderUrl/api');

  static String get uploadsBaseUrl => 
      const String.fromEnvironment('UPLOADS_URL', defaultValue: _defaultRenderUrl);

  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    return '$uploadsBaseUrl$path';
  }
}

