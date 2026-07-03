import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static String get uploadsBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    return '$uploadsBaseUrl$path';
  }
}
