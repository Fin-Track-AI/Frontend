import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../screens/main_shell.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';
import '../screens/notifications/notification_center_modal.dart';
import 'fintrack_logo.dart';

class FinTrackHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoTap;
  final bool? showBackButton;

  const FinTrackHeader({
    super.key,
    this.onSearchTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.onLogoTap,
    this.showBackButton,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  void _handleLogoTap(BuildContext context) {
    if (onLogoTap != null) {
      onLogoTap!();
    } else {
      MainShell.navigateToTab(0);
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  void _handleProfileTap(BuildContext context) {
    if (onProfileTap != null) {
      onProfileTap!();
    } else {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != AppRoutes.profile) {
        Navigator.pushNamed(context, AppRoutes.profile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowBack = showBackButton ?? Navigator.canPop(context);

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: shouldShowBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      titleSpacing: shouldShowBack ? 0.0 : 12.0,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _handleLogoTap(context),
            child: const FinTrackLogo(
              size: 32,
              fontSize: 19,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          constraints: const BoxConstraints(maxWidth: 40),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 22),
          onPressed: onSearchTap ?? () {},
        ),
        ListenableBuilder(
          listenable: NotificationService(),
          builder: (context, _) {
            final unreadCount = NotificationService().unreadCount;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  constraints: const BoxConstraints(maxWidth: 40),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
                  onPressed: onNotificationTap ?? () {
                    NotificationCenterModal.show(context);
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 12,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0, left: 4.0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _handleProfileTap(context),
              child: Builder(
                builder: (context) {
                  final avatarUrl = SessionService().avatarUrl;
                  final name = SessionService().userName;
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

                  if (avatarUrl.isNotEmpty && (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'))) {
                    return ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
