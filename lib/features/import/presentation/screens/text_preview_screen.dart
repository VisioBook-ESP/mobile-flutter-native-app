import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/features/import/presentation/providers/import_provider.dart';

/// Ecran de previsualisation du texte extrait
class TextPreviewScreen extends StatelessWidget {
  const TextPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Apercu du texte'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Allow text editing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edition bientot disponible')),
              );
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ImportProvider>(
          builder: (context, provider, _) {
            final result = provider.uploadResult;
            final file = provider.selectedFile;

            if (result == null || file == null) {
              return const Center(child: Text('Aucun texte disponible'));
            }

            return Column(
              children: [
                // Header avec infos fichier
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.neutral50,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.neutral900,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.fileText,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${result.wordCount ?? 0} mots',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.neutral500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.checkCircle,
                              color: Colors.green.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pret',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: Colors.green.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Texte extrait
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.neutral200),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Text(
                        result.extractedText ?? 'Texte non disponible',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    ),
                  ),
                ),

                // Boutons d'action
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AppButton(
                        text: 'Creer le VisioBook',
                        fullWidth: true,
                        size: AppButtonSize.lg,
                        icon: const Icon(
                          LucideIcons.sparkles,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Reset le provider et aller vers la configuration
                          provider.reset();
                          // TODO: Navigate to project configuration
                          context.go(AppRoutes.dashboard);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Configuration du projet bientot disponible',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Annuler',
                        variant: AppButtonVariant.outline,
                        fullWidth: true,
                        onPressed: () {
                          provider.reset();
                          context.go(AppRoutes.dashboard);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
