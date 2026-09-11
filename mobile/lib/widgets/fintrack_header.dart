import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../screens/main_shell.dart';

class FinTrackHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoTap;

  const FinTrackHeader({
    super.key,
    this.onSearchTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.onLogoTap,
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
      MainShell.navigateToTab(4);
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 12.0,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _handleLogoTap(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'F.',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FinTrack',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
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
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              constraints: const BoxConstraints(maxWidth: 40),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
              onPressed: onNotificationTap ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new unread notifications')),
                );
              },
            ),
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
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0, left: 4.0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _handleProfileTap(context),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.border,
                backgroundImage: const NetworkImage(
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
