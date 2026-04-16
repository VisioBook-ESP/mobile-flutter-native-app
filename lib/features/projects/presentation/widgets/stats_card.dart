import 'package:flutter/material.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/glass_container.dart';

class StatsCard extends StatelessWidget {
  final int visiobooksCount;
  final int textsCount;

  const StatsCard({
    super.key,
    required this.visiobooksCount,
    required this.textsCount,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      borderRadius: AppTheme.radiusMd,
      child: Row(
        children: [
          Expanded(
            child: _StatItem(count: visiobooksCount, label: 'VisioBooks'),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _StatItem(count: textsCount, label: 'Textes'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;

  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.neutral400
                : AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}
