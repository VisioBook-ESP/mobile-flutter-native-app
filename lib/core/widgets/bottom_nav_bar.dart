import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onAddTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassAlpha = isDark ? 0.18 : 0.12;
    final borderAlpha = isDark ? 0.25 : 0.3;
    final innerGlowAlpha = isDark ? 0.08 : 0.06;
    final edgeHighAlpha = isDark ? 0.5 : 0.8;
    final edgeLowAlpha = isDark ? 0.2 : 0.3;
    final iconColor = isDark ? Colors.white : AppColors.neutral900;

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomPadding + 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: CustomPaint(
            painter: _NavBarGlassPainter(
              highAlpha: edgeHighAlpha,
              lowAlpha: edgeLowAlpha,
            ),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: glassAlpha),
                borderRadius: BorderRadius.circular(20),
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
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.white.withValues(alpha: innerGlowAlpha),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    _NavItem(
                      icon: LucideIcons.home,
                      isSelected: currentIndex == 0,
                      onTap: () => onTap(0),
                      iconColor: iconColor,
                      isDark: isDark,
                    ),
                    _NavItem(
                      icon: LucideIcons.fileText,
                      isSelected: currentIndex == 1,
                      onTap: () => onTap(1),
                      iconColor: iconColor,
                      isDark: isDark,
                    ),
                    _NavItem(
                      icon: LucideIcons.playCircle,
                      isSelected: currentIndex == 2,
                      onTap: () => onTap(2),
                      iconColor: iconColor,
                      isDark: isDark,
                    ),
                    _NavItem(
                      icon: LucideIcons.plus,
                      isSelected: false,
                      onTap: () => onAddTap?.call(),
                      iconColor: iconColor,
                      isDark: isDark,
                    ),
                    _NavItem(
                      icon: LucideIcons.user,
                      isSelected: currentIndex == 4,
                      onTap: () => onTap(4),
                      iconColor: iconColor,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the top and left edge highlights (::before and ::after in CSS)
class _NavBarGlassPainter extends CustomPainter {
  final double highAlpha;
  final double lowAlpha;

  _NavBarGlassPainter({this.highAlpha = 0.8, this.lowAlpha = 0.3});

  @override
  void paint(Canvas canvas, Size size) {
    // Top edge highlight (::before)
    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: highAlpha),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1));
    canvas.drawRect(Rect.fromLTWH(20, 0, size.width - 40, 1), topPaint);

    // Left edge highlight (::after)
    final leftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: highAlpha),
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: lowAlpha),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 1, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 20, 1, size.height - 40), leftPaint);
  }

  @override
  bool shouldRepaint(covariant _NavBarGlassPainter oldDelegate) =>
      oldDelegate.highAlpha != highAlpha || oldDelegate.lowAlpha != lowAlpha;
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color iconColor;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBgAlpha = isDark ? 0.12 : 0.2;
    final selectedBorderAlpha = isDark ? 0.15 : 0.25;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 64,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: isSelected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: selectedBgAlpha),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: selectedBorderAlpha,
                        ),
                      ),
                    )
                  : null,
              child: Center(
                child: Icon(
                  icon,
                  color: isSelected
                      ? iconColor
                      : iconColor.withValues(alpha: 0.4),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
