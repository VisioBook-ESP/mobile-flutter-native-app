import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';

/// Bottom sheet pour selectionner une generation de video
class GenerationSelectorSheet extends StatelessWidget {
  final List<Generation> generations;
  final String projectTitle;
  final Function(Generation) onGenerationSelected;

  const GenerationSelectorSheet({
    super.key,
    required this.generations,
    required this.projectTitle,
    required this.onGenerationSelected,
  });

  /// Affiche le bottom sheet et retourne la generation selectionnee
  static Future<Generation?> show({
    required BuildContext context,
    required List<Generation> generations,
    required String projectTitle,
  }) async {
    return showModalBottomSheet<Generation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenerationSelectorSheet(
        generations: generations,
        projectTitle: projectTitle,
        onGenerationSelected: (generation) {
          Navigator.of(context).pop(generation);
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fev',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aout',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisir une version',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${generations.length} versions disponibles pour "$projectTitle"',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Generations list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: generations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final generation = generations[index];
                final isLatest = index == 0;
                return _GenerationTile(
                  generation: generation,
                  index: generations.length - index,
                  isLatest: isLatest,
                  formattedDate: _formatDate(generation.createdAt),
                  formattedTime: _formatTime(generation.createdAt),
                  onTap: () => onGenerationSelected(generation),
                );
              },
            ),
          ),
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _GenerationTile extends StatelessWidget {
  final Generation generation;
  final int index;
  final bool isLatest;
  final String formattedDate;
  final String formattedTime;
  final VoidCallback onTap;

  const _GenerationTile({
    required this.generation,
    required this.index,
    required this.isLatest,
    required this.formattedDate,
    required this.formattedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: generation.thumbnailUrl != null
                    ? Image.network(
                        generation.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                LucideIcons.film,
                                size: 24,
                                color: AppColors.neutral400,
                              ),
                            ),
                      )
                    : const Center(
                        child: Icon(
                          LucideIcons.film,
                          size: 24,
                          color: AppColors.neutral400,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Version $index',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isLatest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Derniere',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedDate a $formattedTime',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
