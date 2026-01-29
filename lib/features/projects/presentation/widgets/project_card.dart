import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectCard({super.key, required this.project, this.onTap});

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 144;
    const double coverHeight = 200;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              width: cardWidth,
              height: coverHeight,
              color: AppColors.neutral100,
              child: project.coverUrl != null
                  ? Image.network(
                      project.coverUrl!,
                      fit: BoxFit.cover,
                      width: cardWidth,
                      height: coverHeight,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.neutral400,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder();
                      },
                    )
                  : _buildPlaceholder(),
            ),
            // Titre et statut
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  _buildStatusBadge(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(LucideIcons.bookOpen, size: 32, color: AppColors.neutral400),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    IconData? icon;

    switch (project.status) {
      case ProjectStatus.draft:
        color = AppColors.neutral500;
        icon = LucideIcons.edit3;
        break;
      case ProjectStatus.processing:
        color = AppColors.info;
        icon = LucideIcons.loader;
        break;
      case ProjectStatus.ready:
        color = AppColors.success;
        icon = LucideIcons.checkCircle;
        break;
      case ProjectStatus.error:
        color = AppColors.error;
        icon = LucideIcons.alertCircle;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          project.status.label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
