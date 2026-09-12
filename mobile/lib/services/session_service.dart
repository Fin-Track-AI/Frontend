import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that holds the authenticated user session in memory.
/// Loaded once at app startup — all screens read from this.
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  static const String _tokenKey = 'fintrack_auth_token';
  static const String _userKey = 'fintrack_user_data';

  // In-memory session state
  String? _token;
  Map<String, dynamic>? _user;

  // ── Getters ──────────────────────────────────────────────────────────────

  /// Returns the JWT token for the current session, or null if not logged in.
  String? get token => _token;

  /// Returns the authenticated user object, or null if not logged in.
  Map<String, dynamic>? get user => _user;

  /// Returns true if a valid session is active.
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// User unique ID
  String get userId => _user?['id'] as String? ?? '';

  /// User's display name
  String get userName {
    final name = _user?['name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final email = userEmail;
    if (email.isNotEmpty) return email.split('@')[0];
    return 'User';
  }

  /// User's phone number
  String get userPhone => _user?['phone'] as String? ?? '';

  /// User's email
  String get userEmail => _user?['email'] as String? ?? '';

  /// User's avatar URL
  String get avatarUrl => _user?['avatarUrl'] as String? ?? '';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Call once at app startup (before runApp) to restore any persisted session.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userStr = prefs.getString(_userKey);
    if (userStr != null && userStr.isNotEmpty) {
      try {
        _user = jsonDecode(userStr) as Map<String, dynamic>;
      } catch (_) {
        _user = null;
      }
    }
  }

  /// Persist session after successful login.
  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    _token = token;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// Update user in-memory and in cache
  Future<void> updateUser(Map<String, dynamic> updatedUserData) async {
    _user = {...?_user, ...updatedUserData};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_user));
  }

  /// Clear session on logout.
  Future<void> clearSession() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
