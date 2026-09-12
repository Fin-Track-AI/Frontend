import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Production FinTrack Brand Logo Widget
/// A polished, modern fintech mark featuring dynamic dual-gradient layers,
/// an upward financial vector arrow, and a subtle glowing badge.
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
    final iconBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Deep Slate Navy
            Color(0xFF1E293B), // Charcoal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: size * 0.35,
            spreadRadius: 1,
            offset: Offset(0, size * 0.12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle glowing upward pulse
          Positioned(
            top: size * 0.14,
            right: size * 0.14,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Clean Modern Financial Geometric Icon
          CustomPaint(
            size: Size(size * 0.58, size * 0.58),
            painter: _FinTrackLogoPainter(),
          ),
        ],
      ),
    );

    if (!showText) {
      return iconBox;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconBox,
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
              TextSpan(
                text: 'Track',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: fontSize,
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

/// Custom painter for an ultra-crisp, scalable fintech mark (Geometric 'F' with upward growth bar)
class _FinTrackLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Primary Coral Gradient Paint
    final coralPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF6B4A),
          Color(0xFFFA5533),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // Secondary Cyan/Teal accent paint for growth arrow
    final accentPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // 1. Left Vertical Pillar
    final pillarRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w * 0.26, h),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(pillarRRect, coralPaint);

    // 2. Top Horizontal Bar
    final topBarRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, 0, w * 0.78, h * 0.26),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(topBarRRect, coralPaint);

    // 3. Middle Dynamic Growth Bar
    final midBarRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.44, w * 0.52, h * 0.24),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(midBarRRect, coralPaint);

    // 4. Accent Growth Dot / Indicator at top right
    final dotCenter = Offset(w * 0.86, h * 0.76);
    canvas.drawCircle(dotCenter, w * 0.14, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
