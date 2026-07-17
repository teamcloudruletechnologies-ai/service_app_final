import 'package:flutter/foundation.dart';

class ApiConfig {
  // Safe default local IP. Can be overridden at compile-time with:
  // flutter run --dart-define=API_HOST=your_ip
  static const String _defaultIp = '192.168.1.10';

  static String get host {
    if (kIsWeb) {
      return 'localhost';
    }
    return const String.fromEnvironment('API_HOST', defaultValue: _defaultIp);
  }

  static String get baseUrl => 'https://service-app-hsu6.onrender.com/api';
  static String get uploadsBaseUrl => 'https://service-app-hsu6.onrender.com';

  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    return '$uploadsBaseUrl$path';
  }
}
