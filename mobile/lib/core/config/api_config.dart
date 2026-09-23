import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  /// Primary Production Cloud Run Backend URL
  static const String primaryBaseUrl = 'https://fintrack-backend-api-335711726164.asia-south1.run.app/api/v1';

  /// Localhost Fallback URL
  static const String localFallbackUrl = 'http://localhost:5001/api/v1';

  /// Optional compile-time overrides:
  /// --dart-define=API_BASE_URL=https://...
  /// --dart-define=FORCE_CLOUD_RUN=true
  static const String _envOverride = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const bool _forceCloudRun = bool.fromEnvironment('FORCE_CLOUD_RUN', defaultValue: false);

  /// Active Base URL in use (defaults to primary Cloud Run)
  static String _activeBaseUrl = _envOverride.isNotEmpty ? _envOverride : primaryBaseUrl;

  /// Getter for the active base URL
  static String get baseUrl => _activeBaseUrl;

  /// Switch active base URL to deployed Cloud Run backend
  static void useDeployedBackend() {
    _activeBaseUrl = primaryBaseUrl;
    debugPrint('[ApiConfig] Switched active backend to Deployed Cloud Run: $_activeBaseUrl');
  }

  /// Switch active base URL to local development backend
  static void useLocalBackend() {
    _activeBaseUrl = localFallbackUrl;
    debugPrint('[ApiConfig] Switched active backend to Local: $_activeBaseUrl');
  }

  /// Quick check if primary or local backend is reachable
  static Future<String> getActiveBaseUrl() async {
    // If environment explicitly specified a URL
    if (_envOverride.isNotEmpty) {
      _activeBaseUrl = _envOverride;
      return _activeBaseUrl;
    }

    // In release mode or if forced, always use Cloud Run
    if (kReleaseMode || _forceCloudRun) {
      _activeBaseUrl = primaryBaseUrl;
      debugPrint('[ApiConfig] Using Deployed Cloud Run Backend: $_activeBaseUrl');
      return _activeBaseUrl;
    }

    // In debug mode, prioritize local backend if it's running on port 5001
    try {
      final localRes = await http
          .get(Uri.parse('$localFallbackUrl/health'))
          .timeout(const Duration(seconds: 2));
      if (localRes.statusCode == 200) {
        _activeBaseUrl = localFallbackUrl;
        debugPrint('[ApiConfig] Connected to local backend with FinTrack AI: $localFallbackUrl');
        return _activeBaseUrl;
      }
    } catch (_) {}

    // Fallback to Cloud Run
    try {
      final res = await http
          .get(Uri.parse('$primaryBaseUrl/health'))
          .timeout(const Duration(seconds: 4));
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
