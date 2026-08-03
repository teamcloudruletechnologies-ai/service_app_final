import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _defaultRenderUrl = 'https://service-app-final.onrender.com';

  static String get baseUrl => 
      const String.fromEnvironment('API_URL', defaultValue: '$_defaultRenderUrl/api');

  static String get uploadsBaseUrl => 
      const String.fromEnvironment('UPLOADS_URL', defaultValue: _defaultRenderUrl);

  static String resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    String trimmed = path.trim();

    // Auto-convert Google Drive URLs to direct image URLs
    if (trimmed.contains('drive.google.com')) {
      final matchD = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (matchD != null && matchD.groupCount >= 1) {
        return 'https://lh3.googleusercontent.com/d/${matchD.group(1)}';
      }
      final matchId = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (matchId != null && matchId.groupCount >= 1) {
        return 'https://lh3.googleusercontent.com/d/${matchId.group(1)}';
      }
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('data:')) return trimmed;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$uploadsBaseUrl$cleanPath';
  }

  static String getUploadUrl(String? path) => resolveImageUrl(path);
}
