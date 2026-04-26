import 'package:flutter/material.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/features/project_detail/domain/project_config.dart';

/// Selecteur de style graphique
class StyleSelector extends StatelessWidget {
  final VideoStyle selectedStyle;
  final ValueChanged<VideoStyle> onStyleChanged;

  const StyleSelector({
    super.key,
    required this.selectedStyle,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Style graphique', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: VideoStyle.values.length,
            itemBuilder: (context, index) {
              final style = VideoStyle.values[index];
              final isSelected = style == selectedStyle;

              return Padding(
                padding: EdgeInsets.only(
                  right: index < VideoStyle.values.length - 1 ? 12 : 0,
                ),
                child: _StyleCard(
                  style: style,
                  isSelected: isSelected,
                  onTap: () => onStyleChanged(style),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  final VideoStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const _StyleCard({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : AppColors.neutral900)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.neutral200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMd - 1),
              ),
              child: Container(
                height: 80,
                width: double.infinity,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.7),
                child: Image.network(
                  style.previewUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.image, color: AppColors.neutral400),
                  ),
                ),
              ),
            ),
            // Label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      style.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 16,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : AppColors.neutral900,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
