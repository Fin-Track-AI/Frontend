import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/split_service.dart';

class NotificationCenterModal extends StatelessWidget {
  const NotificationCenterModal({super.key});

  static Future<void> show(BuildContext context) {
    NotificationService().syncWithBackend();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationCenterModal(),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ListenableBuilder(
                      listenable: notificationService,
                      builder: (context, _) {
                        final unread = notificationService.unreadCount;
                        if (unread == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unread NEW',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => notificationService.markAllAsRead(),
                  child: const Text(
                    'Mark all as read',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Notification List
          Expanded(
            child: ListenableBuilder(
              listenable: notificationService,
              builder: (context, _) {
                final list = notificationService.notifications;

                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'All Caught Up!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Group invites, split updates, and claim notifications will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 64, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final notif = list[index];
                    return _NotificationTile(
                      notification: notif,
                      timeAgo: _formatTime(notif.timestamp),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String timeAgo;

  const _NotificationTile({
    required this.notification,
    required this.timeAgo,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.invitation:
        return Icons.group_add_rounded;
      case NotificationType.splitExpense:
        return Icons.call_split_rounded;
      case NotificationType.claim:
        return Icons.assignment_turned_in_rounded;
      case NotificationType.system:
        return Icons.notifications_active_rounded;
      case NotificationType.splitReminder:
        return Icons.mail_outline_rounded;
      case NotificationType.settlement:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.invitation:
        return AppColors.blue;
      case NotificationType.splitExpense:
        return AppColors.primary;
      case NotificationType.claim:
        return AppColors.green;
      case NotificationType.system:
        return AppColors.textSecondary;
      case NotificationType.splitReminder:
        return AppColors.amber;
      case NotificationType.settlement:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final isInvitation = notification.type == NotificationType.invitation;
    final groupId = notification.data?['groupId'] as String?;
    final actionStatus = notification.actionStatus;

    return Container(
      color: isUnread ? AppColors.primaryLight.withOpacity(0.3) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _getIconColor().withOpacity(0.12),
            child: Icon(_getIcon(), size: 18, color: _getIconColor()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),

                // Invitation Interactive Actions
                if (isInvitation && groupId != null) ...[
                  const SizedBox(height: 10),
                  if (actionStatus == 'ACCEPTED')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.greenBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check, size: 14, color: AppColors.green),
                          SizedBox(width: 4),
                          Text('Joined group', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (actionStatus == 'DECLINED')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Invitation declined', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    )
                  else
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final splitService = SplitService();
                            await splitService.respondToInvitation(groupId, true);
                            await NotificationService().updateActionStatus(notification.id, 'ACCEPTED');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.green,
                                  content: Text('Joined group successfully!'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text(
                            'Accept & Join',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final splitService = SplitService();
                            await splitService.respondToInvitation(groupId, false);
                            await NotificationService().updateActionStatus(notification.id, 'DECLINED');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
