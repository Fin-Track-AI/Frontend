import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../screens/main_shell.dart';
import '../routes/app_routes.dart';

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
      // Switch active tab in MainShell to 0 (Home Dashboard)
      MainShell.navigateToTab(0);
      // If we are currently inside a pushed route (e.g. AI Assistant or Add Expense), pop back
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  void _handleProfileTap(BuildContext context) {
    if (onProfileTap != null) {
      onProfileTap!();
    } else {
      MainShell.navigateToTab(4); // Switch to Profile tab
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
      title: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _handleLogoTap(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo "F." in black box
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'F.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'FinTrack',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 24),
          onPressed: onSearchTap ?? () {},
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
              onPressed: onNotificationTap ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new unread notifications')),
                );
              },
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 4.0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _handleProfileTap(context),
              child: CircleAvatar(
                radius: 17,
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
