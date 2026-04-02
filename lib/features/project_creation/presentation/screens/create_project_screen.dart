import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/widgets.dart';
import 'package:visiobook_mobile/features/project_detail/domain/project_config.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/widgets/option_selector.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/widgets/style_selector.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';

class CreateProjectScreen extends StatefulWidget {
  final String? textId;
  final String? textName;
  final String? extractedText;

  const CreateProjectScreen({
    super.key,
    this.textId,
    this.textName,
    this.extractedText,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _titleController = TextEditingController();
  bool _isLoading = false;
  String? _selectedTextId;
  String? _selectedTextName;
  ProjectConfig _config = const ProjectConfig();

  @override
  void initState() {
    super.initState();
    if (widget.textName != null) {
      _titleController.text = widget.textName!;
    }
    _selectedTextId = widget.textId;
    _selectedTextName = widget.textName;
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generateProject() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<ProjectProvider>();
      final result = await provider.generateProject(
        title: _titleController.text.trim(),
        fileId: _selectedTextId,
        config: _config.toJson(),
      );

      if (!mounted) return;

      if (result != null) {
        context.go(
          AppRoutes.generation
              .replaceAll(':id', result['projectId']!)
              .replaceAll(':versionId', result['versionId']!)
              .replaceAll(':executionId', result['executionId']!),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erreur lors de la generation'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearSelectedText() {
    setState(() {
      _selectedTextId = null;
      _selectedTextName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasTitle = _titleController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Nouveau VisioBook'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  _buildSectionLabel('Titre du projet'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Mon VisioBook...',
                      filled: true,
                      fillColor: AppColors.neutral50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(
                          color: AppColors.neutral200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(
                          color: AppColors.neutral900,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Source
                  _buildSectionLabel('Source du texte'),
                  const SizedBox(height: 12),
                  if (_selectedTextId != null)
                    _buildSelectedSourceCard()
                  else
                    _buildSourceOptions(),
                  const SizedBox(height: 28),

                  // Style graphique
                  StyleSelector(
                    selectedStyle: _config.style,
                    onStyleChanged: (style) {
                      setState(() {
                        _config = _config.copyWith(style: style);
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Vibe / Ambiance
                  OptionSelector<VideoVibe>(
                    title: 'Ambiance',
                    subtitle: 'Choisissez l\'ambiance de votre video',
                    icon: LucideIcons.music,
                    selectedValue: _config.vibe,
                    options: VideoVibe.values
                        .map((v) => OptionItem(value: v, label: v.label))
                        .toList(),
                    onChanged: (vibe) {
                      setState(() {
                        _config = _config.copyWith(vibe: vibe);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Langue
                  OptionSelector<AudioLanguage>(
                    title: 'Langue',
                    subtitle: 'Choisissez la langue de la narration',
                    icon: LucideIcons.languages,
                    selectedValue: _config.language,
                    options: AudioLanguage.values
                        .map(
                          (l) => OptionItem(
                            value: l,
                            label: l.label,
                            prefix: l.codeUpperCase,
                          ),
                        )
                        .toList(),
                    onChanged: (language) {
                      setState(() {
                        _config = _config.copyWith(language: language);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Format
                  OptionSelector<VideoFormat>(
                    title: 'Format',
                    subtitle: 'Orientation de la video',
                    icon: LucideIcons.monitor,
                    selectedValue: _config.format,
                    options: VideoFormat.values
                        .map(
                          (f) => OptionItem(
                            value: f,
                            label: f.label,
                            description: f.description,
                          ),
                        )
                        .toList(),
                    onChanged: (format) {
                      setState(() {
                        _config = _config.copyWith(format: format);
                      });
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom bar
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
            child: SafeArea(
              top: false,
              child: AppButton(
                text: 'Generer le VisioBook',
                onPressed: hasTitle && !_isLoading ? _generateProject : null,
                isLoading: _isLoading,
                fullWidth: true,
                size: AppButtonSize.lg,
                icon: _isLoading
                    ? null
                    : const Icon(
                        LucideIcons.sparkles,
                        size: 20,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _buildSelectedSourceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.neutral900, width: 2),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.checkCircle,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedTextName ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.neutral900,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _clearSelectedText,
            child: const Icon(
              LucideIcons.x,
              color: AppColors.neutral400,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceOptions() {
    return Column(
      children: [
        _buildSourceOptionCard(
          icon: LucideIcons.fileText,
          label: 'Choisir un texte existant',
          onTap: () => context.push('/history/texts'),
        ),
        const SizedBox(height: 12),
        _buildSourceOptionCard(
          icon: LucideIcons.upload,
          label: 'Importer un fichier',
          onTap: () => context.push('/import/file'),
        ),
        const SizedBox(height: 12),
        _buildSourceOptionCard(
          icon: LucideIcons.camera,
          label: 'Scanner un document',
          onTap: () => context.push('/import/scan'),
        ),
      ],
    );
  }

  Widget _buildSourceOptionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.neutral400, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral900),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.neutral400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
