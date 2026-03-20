import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/features/import/presentation/providers/import_provider.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/providers/project_detail_provider.dart';

/// Ecran de previsualisation du texte extrait
class TextPreviewScreen extends StatefulWidget {
  const TextPreviewScreen({super.key});

  @override
  State<TextPreviewScreen> createState() => _TextPreviewScreenState();
}

class _TextPreviewScreenState extends State<TextPreviewScreen> {
  bool _isEditing = false;
  late TextEditingController _textController;
  int _liveWordCount = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    // Initialize with current text after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ImportProvider>();
      final text = provider.uploadResult?.extractedText ?? '';
      _textController.text = text;
      setState(() {
        _liveWordCount = _countWords(text);
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  void _toggleEditing() {
    if (_isEditing) {
      // Switching from edit to view: save the text
      final provider = context.read<ImportProvider>();
      provider.updateExtractedText(_textController.text);
    } else {
      // Switching from view to edit: load current text into controller
      final provider = context.read<ImportProvider>();
      final text = provider.uploadResult?.extractedText ?? '';
      _textController.text = text;
      _liveWordCount = _countWords(text);
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  /// Genere un resume en extrayant les 2-3 premieres phrases du texte.
  /// Retourne null si le texte fait moins de 100 caracteres.
  String? _generateSummary(String text) {
    if (text.length < 100) {
      return null;
    }

    // Separer le texte en phrases par les terminaisons . ! ?
    final sentencePattern = RegExp(r'[^.!?]+[.!?]+');
    final matches = sentencePattern.allMatches(text).toList();

    if (matches.isEmpty) {
      // Pas de phrases detectees, tronquer a 200 caracteres
      if (text.length <= 200) {
        return '$text...';
      }
      return '${text.substring(0, 200).trimRight()}...';
    }

    final buffer = StringBuffer();
    int sentenceCount = 0;

    for (final match in matches) {
      final sentence = match.group(0)!;
      if (sentenceCount >= 3) {
        break;
      }
      if (buffer.length + sentence.length > 200 && sentenceCount > 0) {
        break;
      }
      buffer.write(sentence);
      sentenceCount++;
    }

    return '${buffer.toString().trim()}...';
  }

  /// Construit la carte de resume affichee au-dessus du texte complet.
  Widget _buildSummaryCard(BuildContext context, String summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: AppColors.neutral600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Résumé',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (_isEditing) {
              // Save before navigating back
              final provider = context.read<ImportProvider>();
              provider.updateExtractedText(_textController.text);
            }
            context.pop();
          },
        ),
        title: const Text('Aperçu du texte'),
        actions: [
          TextButton.icon(
            onPressed: _toggleEditing,
            icon: Icon(
              _isEditing ? LucideIcons.check : LucideIcons.pencil,
              size: 16,
            ),
            label: Text(_isEditing ? 'Terminer' : 'Modifier'),
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

            final displayWordCount = _isEditing
                ? _liveWordCount
                : (result.wordCount ?? 0);

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
                              '$displayWordCount mots',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.neutral500),
                            ),
                          ],
                        ),
                      ),
                      if (_isEditing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.pencil,
                                color: AppColors.info,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Edition',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: AppColors.info),
                              ),
                            ],
                          ),
                        )
                      else
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
                                'Prêt',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: Colors.green.shade700),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Resume + texte dans un Expanded scrollable
                Expanded(
                  child: _isEditing
                      ? _buildEditMode(context)
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              // Resume automatique (only in view mode)
                              if (result.extractedText != null &&
                                  _generateSummary(result.extractedText!) !=
                                      null)
                                _buildSummaryCard(
                                  context,
                                  _generateSummary(result.extractedText!)!,
                                ),
                              // Texte extrait
                              _buildViewModeContent(
                                context,
                                result.extractedText,
                              ),
                            ],
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
                        text: 'Configurer le VisioBook',
                        fullWidth: true,
                        size: AppButtonSize.lg,
                        icon: const Icon(
                          LucideIcons.settings,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Si en mode edition, sauvegarder d'abord
                          if (_isEditing) {
                            provider.updateExtractedText(_textController.text);
                            setState(() {
                              _isEditing = false;
                            });
                          }
                          final currentResult = provider.uploadResult;
                          if (currentResult == null) return;
                          // Initialiser le ProjectDetailProvider
                          final projectDetailProvider = context
                              .read<ProjectDetailProvider>();
                          projectDetailProvider.initFromImport(
                            fileId: currentResult.fileId ?? 'unknown',
                            fileName: file.name,
                            extractedText: currentResult.extractedText,
                            wordCount: currentResult.wordCount,
                          );
                          // Reset l'import provider
                          provider.reset();
                          // Naviguer vers la configuration
                          context.push(AppRoutes.projectConfig);
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

  Widget _buildViewModeContent(BuildContext context, String? text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(
          text ?? 'Texte non disponible',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      ),
    );
  }

  Widget _buildEditMode(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral900, width: 2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: TextField(
          controller: _textController,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            filled: false,
          ),
          onChanged: (value) {
            setState(() {
              _liveWordCount = _countWords(value);
            });
          },
        ),
      ),
    );
  }
}
