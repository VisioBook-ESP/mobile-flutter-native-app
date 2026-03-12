import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/features/project_detail/domain/project_config.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/providers/project_detail_provider.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/widgets/option_selector.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/widgets/style_selector.dart';

/// Ecran de detail et configuration d'un projet
class ProjectDetailScreen extends StatefulWidget {
  final String? projectId;

  const ProjectDetailScreen({super.key, this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProjectDetailProvider>();
      if (widget.projectId != null) {
        provider.loadProject(widget.projectId!);
      }
      // Si pas d'ID, on suppose que le provider a deja ete initialise depuis l'import
      if (provider.project != null) {
        _titleController.text = provider.project!.title;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            context.read<ProjectDetailProvider>().reset();
            context.pop();
          },
        ),
        title: const Text('Configuration'),
        actions: [
          Consumer<ProjectDetailProvider>(
            builder: (context, provider, _) {
              if (provider.isSaving) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return TextButton(
                onPressed: () async {
                  provider.setTitle(_titleController.text);
                  await provider.saveProject();
                  if (context.mounted && provider.error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Projet sauvegardé')),
                    );
                  }
                },
                child: const Text('Sauvegarder'),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProjectDetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == ProjectDetailState.error) {
            return _buildErrorState(context, provider);
          }

          if (!provider.hasProject) {
            return const Center(child: Text('Aucun projet'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre du projet
                      _buildTitleField(context, provider),
                      const SizedBox(height: 24),

                      // Apercu du texte
                      if (provider.extractedText != null) ...[
                        _buildTextPreview(context, provider),
                        const SizedBox(height: 24),
                      ],

                      // Style graphique
                      StyleSelector(
                        selectedStyle: provider.config.style,
                        onStyleChanged: provider.setStyle,
                      ),
                      const SizedBox(height: 24),

                      // Langue audio
                      OptionSelector<AudioLanguage>(
                        title: 'Langue audio',
                        subtitle: 'Choisissez la langue de la narration',
                        icon: LucideIcons.languages,
                        selectedValue: provider.config.language,
                        options: AudioLanguage.values
                            .map(
                              (l) => OptionItem(
                                value: l,
                                label: l.label,
                                prefix: l.codeUpperCase,
                              ),
                            )
                            .toList(),
                        onChanged: provider.setLanguage,
                      ),
                      const SizedBox(height: 16),

                      // Duree
                      OptionSelector<VideoDuration>(
                        title: 'Durée',
                        subtitle: 'Ajustez la longueur de votre vidéo',
                        icon: LucideIcons.clock,
                        selectedValue: provider.config.duration,
                        options: VideoDuration.values
                            .map(
                              (d) => OptionItem(
                                value: d,
                                label: d.label,
                                description: d.description,
                              ),
                            )
                            .toList(),
                        onChanged: provider.setDuration,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Bouton generer
              _buildBottomBar(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleField(
    BuildContext context,
    ProjectDetailProvider provider,
  ) {
    if (_titleController.text.isEmpty && provider.project != null) {
      _titleController.text = provider.project!.title;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Titre du projet', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Entrez un titre',
            filled: true,
            fillColor: AppColors.neutral50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.neutral900,
                width: 2,
              ),
            ),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: (value) => provider.setTitle(value),
        ),
      ],
    );
  }

  Widget _buildTextPreview(
    BuildContext context,
    ProjectDetailProvider provider,
  ) {
    return Container(
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
              Icon(LucideIcons.fileText, size: 20, color: AppColors.neutral600),
              const SizedBox(width: 8),
              Text(
                'Apercu du texte',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.wordCount ?? 0} mots',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            provider.extractedText!.length > 300
                ? '${provider.extractedText!.substring(0, 300)}...'
                : provider.extractedText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.neutral600,
              height: 1.5,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ProjectDetailProvider provider) {
    return Container(
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
      child: SafeArea(
        top: false,
        child: AppButton(
          text: 'Générer le VisioBook',
          fullWidth: true,
          size: AppButtonSize.lg,
          isLoading: provider.isGenerating,
          icon: provider.isGenerating
              ? null
              : const Icon(LucideIcons.sparkles, size: 20, color: Colors.white),
          onPressed: provider.isGenerating
              ? null
              : () async {
                  provider.setTitle(_titleController.text);
                  final workflowId = await provider.generateProject();
                  if (workflowId != null && context.mounted) {
                    // Naviguer vers l'ecran de generation
                    context.push(
                      AppRoutes.generation
                          .replaceAll(':id', provider.project!.id)
                          .replaceAll(':workflowId', workflowId),
                    );
                  } else if (provider.error != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(provider.error!)));
                  }
                },
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ProjectDetailProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Réessayer',
              onPressed: () {
                if (widget.projectId != null) {
                  provider.loadProject(widget.projectId!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
