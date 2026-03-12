import 'package:flutter/material.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';

/// A shimmering placeholder widget used as a loading skeleton.
///
/// Uses an [AnimationController] to animate a [LinearGradient] across the
/// widget, giving the appearance of a shimmer effect. No external packages
/// are required.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppTheme.radiusMd,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * value, 0.0),
              end: Alignment(2.0 * value, 0.0),
              colors: const [
                AppColors.neutral100,
                AppColors.neutral200,
                AppColors.neutral100,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton placeholder that mimics the layout of [ProjectCard]:
/// 144x200 cover area + title line + status line.
class SkeletonProjectCard extends StatelessWidget {
  const SkeletonProjectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 144,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover placeholder
          const SkeletonLoader(width: 144, height: 200),
          const SizedBox(height: 8),
          // Title placeholder
          const SkeletonLoader(
            width: 110,
            height: 14,
            borderRadius: AppTheme.radiusSm,
          ),
          const SizedBox(height: 6),
          // Status line placeholder
          const SkeletonLoader(
            width: 70,
            height: 12,
            borderRadius: AppTheme.radiusSm,
          ),
        ],
      ),
    );
  }
}

/// A skeleton placeholder that mimics a list item with a leading circle
/// avatar and two lines of text.
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Leading circle
          const SkeletonLoader(width: 44, height: 44, borderRadius: 22),
          const SizedBox(width: 16),
          // Two lines of text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: MediaQuery.of(context).size.width * 0.45,
                  height: 14,
                  borderRadius: AppTheme.radiusSm,
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 12,
                  borderRadius: AppTheme.radiusSm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for the dashboard loading state: greeting placeholder,
/// stats placeholder, and a horizontal list of [SkeletonProjectCard]s.
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Greeting placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SkeletonLoader(
              width: 200,
              height: 24,
              borderRadius: AppTheme.radiusSm,
            ),
          ),
          const SizedBox(height: 24),
          // Stats placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SkeletonLoader(
              width: MediaQuery.of(context).size.width - 48,
              height: 80,
              borderRadius: AppTheme.radiusMd,
            ),
          ),
          const SizedBox(height: 32),
          // Section header placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SkeletonLoader(
              width: 140,
              height: 18,
              borderRadius: AppTheme.radiusSm,
            ),
          ),
          // Horizontal list of skeleton project cards
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
                  child: const SkeletonProjectCard(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
