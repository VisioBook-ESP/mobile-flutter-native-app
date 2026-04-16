import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final double blur;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 7,
    this.opacity = 0.13,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassOpacity = isDark ? 0.08 : opacity;
    final borderAlpha = isDark ? 0.12 : 0.3;
    final edgeHighlightAlpha = isDark ? 0.3 : 0.6;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            painter: _GlassEdgePainter(
              borderRadius: borderRadius,
              highlightAlpha: edgeHighlightAlpha,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: glassOpacity),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: borderAlpha),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the highlight edges: top edge glow and left edge glow
class _GlassEdgePainter extends CustomPainter {
  final double borderRadius;
  final double highlightAlpha;

  _GlassEdgePainter({required this.borderRadius, this.highlightAlpha = 0.6});

  @override
  void paint(Canvas canvas, Size size) {
    // Top edge highlight (like ::before)
    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: highlightAlpha),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1));
    canvas.drawRect(
      Rect.fromLTWH(borderRadius, 0, size.width - borderRadius * 2, 1),
      topPaint,
    );

    // Left edge highlight (like ::after)
    final leftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: highlightAlpha),
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: highlightAlpha * 0.33),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 1, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, borderRadius, 1, size.height - borderRadius * 2),
      leftPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassEdgePainter oldDelegate) =>
      oldDelegate.highlightAlpha != highlightAlpha;
}
