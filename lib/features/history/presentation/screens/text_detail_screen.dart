import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/core/widgets/gradient_background.dart';
import 'package:visiobook_mobile/core/widgets/skeleton_loader.dart';
import 'package:visiobook_mobile/features/history/domain/user_file.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/history/presentation/providers/texts_provider.dart';

/// Ecran de detail d'un texte (depuis la bibliotheque de fichiers)
class TextDetailScreen extends StatefulWidget {
  final String projectId;

  const TextDetailScreen({super.key, required this.projectId});

  @override
  State<TextDetailScreen> createState() => _TextDetailScreenState();
}

class _TextDetailScreenState extends State<TextDetailScreen> {
  UserFile? _file;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final textsProvider = context.read<TextsProvider>();
      final file = textsProvider.getFileById(widget.projectId);
      if (file != null) {
        setState(() => _file = file);
      } else {
        // Si les fichiers ne sont pas charges, les charger
        textsProvider.loadFiles().then((_) {
          final loaded = textsProvider.getFileById(widget.projectId);
          if (loaded != null && mounted) {
            setState(() => _file = loaded);
          }
        });
      }
    });
  }

  int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  String? _generateSummary(String text) {
    if (text.length < 100) return null;

    final sentencePattern = RegExp(r'[^.!?]+[.!?]+');
    final matches = sentencePattern.allMatches(text).toList();

    if (matches.isEmpty) {
      if (text.length <= 200) return '$text...';
      return '${text.substring(0, 200).trimRight()}...';
    }

    final buffer = StringBuffer();
    int sentenceCount = 0;

    for (final match in matches) {
      final sentence = match.group(0)!;
      if (sentenceCount >= 3) break;
      if (buffer.length + sentence.length > 200 && sentenceCount > 0) break;
      buffer.write(sentence);
      sentenceCount++;
    }

    return '${buffer.toString().trim()}...';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Détail du texte',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        body: SafeArea(
          child: Consumer<TextsProvider>(
            builder: (context, textsProvider, _) {
              if (textsProvider.isLoading && _file == null) {
                return const SkeletonTextDetail();
              }

              final file = _file;
              if (file == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.fileQuestion,
                        size: 48,
                        color: AppColors.neutral400,
                      ),
                      const SizedBox(height: 16),
                      const Text('Texte introuvable'),
                    ],
                  ),
                );
              }

              final text = file.extractedText ?? '';
              final wordCount = file.wordCount ?? _countWords(text);
              final summary = text.isNotEmpty ? _generateSummary(text) : null;

              return Column(
                children: [
                  // Header avec infos fichier
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.neutral50,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : AppColors.neutral900,
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
                                '$wordCount mots',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.neutral500),
                              ),
                            ],
                          ),
                        ),
                        if (file.fileType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : AppColors.neutral200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              file.fileType!.toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.neutral300
                                        : AppColors.neutral700,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Ingestion status banner
                  Builder(
                    builder: (context) {
                      final ingestionState = textsProvider.getIngestionState(
                        file.id,
                      );
                      if (ingestionState == null) {
                        return const SizedBox.shrink();
                      }

                      final isIngesting = ingestionState.isInProgress;
                      final isFailed =
                          ingestionState.status == IngestionStatus.failed;

                      if (!isIngesting && !isFailed) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: isIngesting
                            ? Colors.blue.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            if (isIngesting) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ingestion en cours...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.blue.shade200
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ] else if (isFailed) ...[
                              Icon(
                                LucideIcons.alertCircle,
                                size: 16,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ingestionState.error ??
                                      'L\'ingestion a échoué',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  // Resume + texte
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (summary != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : AppColors.neutral200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.sparkles,
                                          size: 16,
                                          color: isDark
                                              ? AppColors.neutral400
                                              : AppColors.neutral600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Résumé',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.neutral300
                                                    : AppColors.neutral600,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      summary,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? AppColors.neutral300
                                                : AppColors.neutral700,
                                            height: 1.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : AppColors.neutral200,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                              child: Text(
                                text.isNotEmpty ? text : 'Texte non disponible',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(height: 1.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bouton generer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Builder(
                      builder: (context) {
                        final isFileIngesting = textsProvider.isIngesting(
                          file.id,
                        );
                        return Column(
                          children: [
                            AppButton(
                              text: isFileIngesting
                                  ? 'Ingestion en cours...'
                                  : 'Créer un projet',
                              fullWidth: true,
                              size: AppButtonSize.lg,
                              isLoading: isFileIngesting,
                              icon: isFileIngesting
                                  ? null
                                  : const Icon(
                                      LucideIcons.plus,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                              onPressed: isFileIngesting
                                  ? null
                                  : () {
                                      context.push(
                                        AppRoutes.createProject,
                                        extra: {
                                          'textId': file.id,
                                          'textName': file.name,
                                          'extractedText': file.extractedText,
                                        },
                                      );
                                    },
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              text: 'Retour',
                              variant: AppButtonVariant.outline,
                              fullWidth: true,
                              onPressed: () => context.pop(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
