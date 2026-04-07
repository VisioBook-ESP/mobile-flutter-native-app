import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0D0D12),
                  Color(0xFF12101A),
                  Color(0xFF0E1415),
                  Color(0xFF110D16),
                ]
              : const [
                  Color(0xFFD5DFEF), // muted blue
                  Color(0xFFDDD4EE), // soft lavender
                  Color(0xFFCDE4DA), // sage mint
                  Color(0xFFE0D6F0), // light violet
                ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFF93B5E1,
                    ).withValues(alpha: isDark ? 0.2 : 0.45),
                    const Color(0xFF93B5E1).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 350,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFFB8A4D8,
                    ).withValues(alpha: isDark ? 0.2 : 0.4),
                    const Color(0xFFB8A4D8).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFF8FBFAA,
                    ).withValues(alpha: isDark ? 0.2 : 0.4),
                    const Color(0xFF8FBFAA).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: 30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFFE8A4B8,
                    ).withValues(alpha: isDark ? 0.15 : 0.25),
                    const Color(0xFFE8A4B8).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
