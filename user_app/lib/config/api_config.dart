import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _defaultRenderUrl = 'https://service-app-final.onrender.com';

  static String get baseUrl => 
      const String.fromEnvironment('API_URL', defaultValue: '$_defaultRenderUrl/api');

  static String get uploadsBaseUrl => 
      const String.fromEnvironment('UPLOADS_URL', defaultValue: _defaultRenderUrl);

  static String resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('data:')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$uploadsBaseUrl$cleanPath';
  }

  static String getUploadUrl(String? path) => resolveImageUrl(path);
}
