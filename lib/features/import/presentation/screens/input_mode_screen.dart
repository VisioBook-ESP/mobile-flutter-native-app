import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';

/// Ecran de selection du mode d'import
class InputModeScreen extends StatelessWidget {
  const InputModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Nouveau projet'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comment souhaitez-vous\nimporter votre texte ?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez une methode pour ajouter du contenu',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
              ),
              const SizedBox(height: 32),
              _InputModeCard(
                icon: LucideIcons.upload,
                title: 'Importer un fichier',
                subtitle: 'PDF, TXT, DOCX, EPUB',
                description: 'Selectionnez un fichier depuis votre appareil',
                onTap: () => context.push(AppRoutes.fileImport),
              ),
              const SizedBox(height: 16),
              _InputModeCard(
                icon: LucideIcons.camera,
                title: 'Scanner un document',
                subtitle: 'Appareil photo',
                description: 'Prenez une photo de votre texte',
                onTap: () => context.push(AppRoutes.scan),
                isDisabled: true,
                disabledMessage: 'Bientot disponible',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;
  final bool isDisabled;
  final String? disabledMessage;

  const _InputModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
    this.isDisabled = false,
    this.disabledMessage,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = isDisabled ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDisabled
                  ? AppColors.neutral200
                  : Theme.of(context).colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? AppColors.neutral100
                      : AppColors.neutral900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isDisabled ? AppColors.neutral400 : Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (disabledMessage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutral100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              disabledMessage!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.neutral500),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral400,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDisabled) ...[
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.neutral400,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
