import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Production FinTrack Brand Logo Widget
/// Renders the official brand icon from assets/logo/logo.png with optional brand text.
class FinTrackLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double fontSize;
  final Color? textColor;

  const FinTrackLogo({
    super.key,
    this.size = 38,
    this.showText = true,
    this.fontSize = 22,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final logoImage = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.28),
            blurRadius: size * 0.35,
            spreadRadius: 1,
            offset: Offset(0, size * 0.12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/logo/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Safe fallback to lib/logo/logo.png if assets bundle lookup varies
            return Image.asset(
              'lib/logo/logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );

    if (!showText) {
      return logoImage;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoImage,
        SizedBox(width: size * 0.28),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Fin',
                style: TextStyle(
                  color: textColor ?? AppColors.textPrimary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const TextSpan(
                text: 'Track',
                style: TextStyle(
                  color: Color(0xFFFF7A00), // Match vibrant brand orange from logo
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
