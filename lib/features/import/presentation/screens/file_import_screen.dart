import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/core/widgets/gradient_background.dart';
import 'package:visiobook_mobile/features/import/domain/import_file.dart';
import 'package:visiobook_mobile/features/history/presentation/providers/texts_provider.dart';
import 'package:visiobook_mobile/features/import/presentation/providers/import_provider.dart';

/// Ecran d'import de fichier
class FileImportScreen extends StatelessWidget {
  const FileImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              context.read<ImportProvider>().reset();
              context.pop();
            },
          ),
          title: Text(
            'Importer un fichier',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        body: SafeArea(
          child: Consumer<ImportProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sélectionnez un fichier',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Formats supportés: PDF, TXT, DOCX, EPUB\nTaille max: 50 MB',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Zone de selection / fichier selectionne
                    if (provider.hasFile)
                      _FileSelectedCard(file: provider.selectedFile!)
                    else
                      _FilePickerZone(onTap: () => provider.pickFile()),

                    // Erreur
                    if (provider.error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorMessage(message: provider.error!),
                    ],

                    // Progress bar
                    if (provider.isUploading) ...[
                      const SizedBox(height: 24),
                      _UploadProgress(progress: provider.uploadProgress),
                    ],

                    const Spacer(),

                    // Boutons
                    if (provider.hasFile && !provider.isUploading) ...[
                      AppButton(
                        text: 'Continuer',
                        fullWidth: true,
                        size: AppButtonSize.lg,
                        onPressed: () async {
                          final success = await provider.uploadFile();
                          if (success && context.mounted) {
                            // Start ingestion tracking if jobId available
                            final jobId = provider.lastIngestionJobId;
                            final fileId = provider.lastIngestionFileId;
                            if (jobId != null && fileId != null) {
                              context
                                  .read<TextsProvider>()
                                  .startIngestionTracking(
                                    fileId,
                                    jobId,
                                    provider.selectedFile?.name ?? 'Fichier',
                                  );
                            }
                            context.push(AppRoutes.textPreview);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Changer de fichier',
                        variant: AppButtonVariant.outline,
                        fullWidth: true,
                        onPressed: () => provider.pickFile(),
                      ),
                    ],

                    if (!provider.hasFile && !provider.isUploading)
                      AppButton(
                        text: 'Parcourir les fichiers',
                        fullWidth: true,
                        size: AppButtonSize.lg,
                        icon: const Icon(
                          LucideIcons.folderOpen,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () => provider.pickFile(),
                      ),

                    if (provider.isUploading)
                      AppButton(
                        text: 'Upload en cours...',
                        fullWidth: true,
                        size: AppButtonSize.lg,
                        isLoading: true,
                        onPressed: null,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Zone de drop/selection de fichier
class _FilePickerZone extends StatelessWidget {
  final VoidCallback onTap;

  const _FilePickerZone({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.neutral600 : AppColors.neutral300,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.neutral50,
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.neutral200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                LucideIcons.fileUp,
                size: 32,
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Appuyez pour sélectionner',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'ou glissez-déposez un fichier',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte du fichier selectionne
class _FileSelectedCard extends StatelessWidget {
  final ImportFile file;

  const _FileSelectedCard({required this.file});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.neutral50 : AppColors.neutral900,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.neutral50,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.neutral900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getFileIcon(file.type), color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        file.type.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.neutral700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      file.formattedSize,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.checkCircle2, color: AppColors.neutral900),
        ],
      ),
    );
  }

  IconData _getFileIcon(ImportFileType type) {
    switch (type) {
      case ImportFileType.pdf:
        return LucideIcons.fileText;
      case ImportFileType.txt:
        return LucideIcons.fileText;
      case ImportFileType.docx:
        return LucideIcons.fileText;
      case ImportFileType.epub:
        return LucideIcons.bookOpen;
      case ImportFileType.unknown:
        return LucideIcons.file;
    }
  }
}

/// Message d'erreur
class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre de progression de l'upload
class _UploadProgress extends StatelessWidget {
  final double progress;

  const _UploadProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upload en cours...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$percentage%',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.neutral200,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.neutral900,
            ),
          ),
        ),
      ],
    );
  }
}
