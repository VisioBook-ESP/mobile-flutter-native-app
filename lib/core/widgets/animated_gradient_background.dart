import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                  Color(0xFFD5DFEF),
                  Color(0xFFDDD4EE),
                  Color(0xFFCDE4DA),
                  Color(0xFFE0D6F0),
                ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            children: [
              _AnimatedBlob(
                t: t,
                baseX: 0.8,
                baseY: -0.05,
                radiusX: 0.15,
                radiusY: 0.08,
                speedX: 1,
                speedY: 2,
                size: 260,
                color: const Color(0xFF93B5E1),
                alpha: isDark ? 0.2 : 0.45,
              ),
              _AnimatedBlob(
                t: t,
                baseX: -0.1,
                baseY: 0.4,
                radiusX: 0.12,
                radiusY: 0.1,
                speedX: 1,
                speedY: 3,
                phase: 1.2,
                size: 300,
                color: const Color(0xFFB8A4D8),
                alpha: isDark ? 0.2 : 0.4,
              ),
              _AnimatedBlob(
                t: t,
                baseX: 0.85,
                baseY: 0.75,
                radiusX: 0.1,
                radiusY: 0.12,
                speedX: 2,
                speedY: 1,
                phase: 2.5,
                size: 240,
                color: const Color(0xFF8FBFAA),
                alpha: isDark ? 0.2 : 0.4,
              ),
              _AnimatedBlob(
                t: t,
                baseX: 0.6,
                baseY: 0.2,
                radiusX: 0.08,
                radiusY: 0.06,
                speedX: 3,
                speedY: 2,
                phase: 0.8,
                size: 150,
                color: const Color(0xFFE8A4B8),
                alpha: isDark ? 0.15 : 0.25,
              ),
              _AnimatedBlob(
                t: t,
                baseX: 0.3,
                baseY: 0.65,
                radiusX: 0.1,
                radiusY: 0.07,
                speedX: 1,
                speedY: 2,
                phase: 3.5,
                size: 200,
                color: const Color(0xFFA4C8E8),
                alpha: isDark ? 0.15 : 0.3,
              ),
              widget.child,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _AnimatedBlob extends StatelessWidget {
  final double t;
  final double baseX;
  final double baseY;
  final double radiusX;
  final double radiusY;
  final int speedX;
  final int speedY;
  final double phase;
  final double size;
  final Color color;
  final double alpha;

  const _AnimatedBlob({
    required this.t,
    required this.baseX,
    required this.baseY,
    required this.radiusX,
    required this.radiusY,
    required this.speedX,
    required this.speedY,
    this.phase = 0.0,
    required this.size,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final angleX = t * 2 * pi * speedX + phase;
    final angleY = t * 2 * pi * speedY + phase;
    final x = (baseX + radiusX * cos(angleX)) * screenWidth - size / 2;
    final y = (baseY + radiusY * sin(angleY)) * screenHeight - size / 2;

    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
