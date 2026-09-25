import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import 'session_service.dart';

enum NotificationType {
  invitation,
  splitExpense,
  claim,
  system,
  splitReminder,
  settlement,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionStatus; // 'ACCEPTED', 'DECLINED', or null

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.actionStatus,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? actionStatus,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      actionStatus: actionStatus ?? this.actionStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'data': data,
        'actionStatus': actionStatus,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        title: (json['title'] ?? '') as String,
        body: (json['body'] ?? '') as String,
        type: NotificationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => NotificationType.system,
        ),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isRead: (json['isRead'] as bool?) ?? false,
        data: json['data'] as Map<String, dynamic>?,
        actionStatus: json['actionStatus'] as String?,
      );
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _storageKey = 'fintrack_app_notifications_v1';

  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_storageKey);
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List<dynamic>;
        _notifications = list
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      _notifications = [];
    }
    notifyListeners();

    // Sync with backend API in background
    syncWithBackend();
  }

  Future<void> syncWithBackend() async {
    try {
      final token = SessionService().token;
      final phone = SessionService().userPhone;
      final phoneQuery = phone.isNotEmpty ? '?phone=${Uri.encodeComponent(phone)}' : '';
      final uri = Uri.parse('${ApiConfig.baseUrl}/notifications$phoneQuery');
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          final List<dynamic> list = data['data'] as List<dynamic>;
          final backendNotifs = list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();

          bool changed = false;
          for (final bn in backendNotifs) {
            final bnGroupId = bn.data?['groupId']?.toString();

            // Match by exact ID or by duplicate content / groupId
            final idx = _notifications.indexWhere((n) {
              if (n.id == bn.id) return true;
              if (bnGroupId != null && bnGroupId.isNotEmpty && n.data?['groupId']?.toString() == bnGroupId && n.type == bn.type) {
                return true;
              }
              if (n.title.trim() == bn.title.trim() && n.body.trim() == bn.body.trim() && n.type == bn.type) {
                return true;
              }
              return false;
            });

            if (idx == -1) {
              _notifications.add(bn);
              changed = true;
            } else {
              // Preserve any accepted/declined local status if backend is null
              final existingStatus = _notifications[idx].actionStatus;
              final finalStatus = bn.actionStatus ?? existingStatus;
              _notifications[idx] = bn.copyWith(
                actionStatus: finalStatus,
                isRead: bn.isRead || _notifications[idx].isRead,
              );
              changed = true;
            }
          }
          if (changed) {
            _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            await _save();
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Sync notifications with backend: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, str);
    } catch (_) {}
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? actionStatus,
  }) async {
    final groupId = data?['groupId']?.toString();
    // Strict deduplication check
    final exists = _notifications.any((n) {
      if (groupId != null && groupId.isNotEmpty && n.data?['groupId']?.toString() == groupId && n.type == type) {
        return true;
      }
      return n.type == type && n.title.trim() == title.trim() && n.body.trim() == body.trim();
    });

    if (exists) return;

    final notif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      data: data,
      actionStatus: actionStatus,
    );

    _notifications.insert(0, notif);
    await _save();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      await _save();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _save();
    notifyListeners();
  }

  Future<void> updateActionStatus(String id, String status) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final targetNotif = _notifications[idx];
      final targetGroupId = targetNotif.data?['groupId']?.toString();

      _notifications[idx] = targetNotif.copyWith(
        actionStatus: status,
        isRead: true,
      );

      if (targetGroupId != null && targetGroupId.isNotEmpty) {
        updateActionStatusForGroup(targetGroupId, status);
      }

      await _save();
      notifyListeners();

      // Sync action update to backend if valid backend ID
      if (!id.startsWith('notif_')) {
        try {
          final token = SessionService().token;
          if (token != null && token.isNotEmpty) {
            final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/$id/action');
            await http.put(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'action': status}),
            ).timeout(const Duration(seconds: 3));
          }
        } catch (e) {
          debugPrint('Backend update notification action error: $e');
        }
      }
    }
  }

  Future<void> updateActionStatusForGroup(String groupId, String status) async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].data?['groupId']?.toString() == groupId) {
        _notifications[i] = _notifications[i].copyWith(
          actionStatus: status,
          isRead: true,
        );
        changed = true;
      }
    }
    if (changed) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _save();
    notifyListeners();
  }
}
