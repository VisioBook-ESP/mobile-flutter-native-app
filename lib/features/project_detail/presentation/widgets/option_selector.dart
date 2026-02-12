import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';

/// Widget generique pour selectionner une option dans une liste
class OptionSelector<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final T selectedValue;
  final List<OptionItem<T>> options;
  final ValueChanged<T> onChanged;

  const OptionSelector({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.firstWhere(
      (o) => o.value == selectedValue,
      orElse: () => options.first,
    );

    return InkWell(
      onTap: () => _showOptionsSheet(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.neutral700, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    selected.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionTile(
                  option: option,
                  isSelected: option.value == selectedValue,
                  onTap: () {
                    onChanged(option.value);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class OptionItem<T> {
  final T value;
  final String label;
  final String? description;
  final String? prefix;

  const OptionItem({
    required this.value,
    required this.label,
    this.description,
    this.prefix,
  });
}

class _OptionTile<T> extends StatelessWidget {
  final OptionItem<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.neutral900 : AppColors.neutral200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          color: isSelected ? AppColors.neutral50 : Colors.transparent,
        ),
        child: Row(
          children: [
            if (option.prefix != null) ...[
              Text(option.prefix!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, color: AppColors.neutral900),
          ],
        ),
      ),
    );
  }
}
