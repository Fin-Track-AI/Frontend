import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class NudgeBanner extends StatelessWidget {
  final String title;
  final String message;
  final String type;
  final String? actionText;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;

  const NudgeBanner({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.actionText,
    this.onDismiss,
    this.onAction,
  });

  IconData _getNudgeIcon() {
    switch (type.toUpperCase()) {
      case 'SPIKE':
        return Icons.trending_up_rounded;
      case 'SUBSCRIPTION':
        return Icons.autorenew_rounded;
      case 'SAVINGS':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getNudgeColor() {
    switch (type.toUpperCase()) {
      case 'SPIKE':
        return AppColors.red;
      case 'SUBSCRIPTION':
        return AppColors.amber;
      case 'SAVINGS':
        return AppColors.green;
      default:
        return AppColors.primary;
    }
  }

  Color _getNudgeBg() {
    switch (type.toUpperCase()) {
      case 'SPIKE':
        return AppColors.redLight;
      case 'SUBSCRIPTION':
        return AppColors.amberLight;
      case 'SAVINGS':
        return AppColors.greenLight;
      default:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getNudgeColor();
    final bgColor = _getNudgeBg();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(_getNudgeIcon(), color: themeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onDismiss != null)
                InkWell(
                  onTap: onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (actionText != null && actionText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
