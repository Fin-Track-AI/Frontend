import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  /// Primary Production Cloud Run Backend URL
  static const String primaryBaseUrl = 'https://fintrack-backend-api-335711726164.asia-south1.run.app/api/v1';

  /// Localhost Fallback URL
  static const String localFallbackUrl = 'http://localhost:5001/api/v1';

  /// Active Base URL in use (defaults to primary Cloud Run)
  static String _activeBaseUrl = primaryBaseUrl;

  /// Getter for the active base URL
  static String get baseUrl => _activeBaseUrl;

  /// Quick check if primary is reachable; only falls back to localhost in debug mode
  static Future<String> getActiveBaseUrl() async {
    // In release APKs on real phones, always use Cloud Run (localhost does not exist on physical phones)
    if (kReleaseMode) {
      _activeBaseUrl = primaryBaseUrl;
      return _activeBaseUrl;
    }

    try {
      final res = await http
          .get(Uri.parse('$primaryBaseUrl/health'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        _activeBaseUrl = primaryBaseUrl;
        return _activeBaseUrl;
      }
    } catch (e) {
      debugPrint('[ApiConfig] Cloud Run primary backend unreachable in debug: $e. Falling back to localhost.');
      _activeBaseUrl = localFallbackUrl;
    }
    return _activeBaseUrl;
  }

  /// Sets active base URL manually if needed
  static void setBaseUrl(String url) {
    _activeBaseUrl = url;
  }
}
