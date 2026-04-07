import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/gradient_background.dart';
import 'package:visiobook_mobile/features/player/presentation/screens/video_player_screen.dart';
import 'package:visiobook_mobile/features/player/presentation/widgets/generation_selector_sheet.dart';
import 'package:visiobook_mobile/features/export/presentation/providers/export_provider.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';

/// Ecran de detail d'un projet VisioBook
class ProjectViewScreen extends StatefulWidget {
  final String projectId;

  const ProjectViewScreen({super.key, required this.projectId});

  @override
  State<ProjectViewScreen> createState() => _ProjectViewScreenState();
}

class _ProjectViewScreenState extends State<ProjectViewScreen> {
  Project? _project;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProject();
    });
  }

  void _loadProject() {
    final projectProvider = context.read<ProjectProvider>();
    final project = projectProvider.projects.firstWhere(
      (p) => p.id == widget.projectId,
      orElse: () => Project(
        id: widget.projectId,
        title: 'Projet introuvable',
        status: ProjectStatus.error,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    setState(() {
      _project = project;
    });
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

  void _onModifier() {
    // Ouvrir l'ecran de configuration pour modifier le style, etc.
    context.push('/project/${widget.projectId}/config');
  }

  void _onPartager() {
    if (_project == null) return;
    final provider = context.read<ExportProvider>();
    provider.shareNative(_project!.id, _project!.title);
  }

  Future<void> _onVisionner() async {
    if (_project == null) return;

    final project = _project!;

    // Determiner quelle video lancer
    String? videoUrl;
    String? generationId;

    if (project.generations.length > 1) {
      // Plusieurs generations: afficher le selecteur
      final selectedGeneration = await GenerationSelectorSheet.show(
        context: context,
        generations: project.generations,
        projectTitle: project.title,
      );

      if (selectedGeneration == null || !mounted) return;

      videoUrl = selectedGeneration.videoUrl;
      generationId = selectedGeneration.id;
    } else if (project.generations.length == 1) {
      // Une seule generation
      videoUrl = project.generations.first.videoUrl;
      generationId = project.generations.first.id;
    } else {
      // Pas de generation, utiliser la video principale du projet
      videoUrl = project.videoUrl;
    }

    if (videoUrl == null || videoUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune video disponible')),
        );
      }
      return;
    }

    // Ouvrir le lecteur video
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            projectId: project.id,
            projectTitle: project.title,
            videoUrl: videoUrl!,
            generationId: generationId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_project == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final project = _project!;

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
            'Details de la BD',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover container
              _buildCoverSection(project),
              const SizedBox(height: 24),

              // Title
              Text(
                project.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Metadata line: Style • cases • duration • date
              _buildMetadataLine(project),
              const SizedBox(height: 24),

              // Visionner button (main action)
              _buildVisionnerButton(project),
              const SizedBox(height: 16),

              // Action buttons row: Modifier | Partager | Telecharger
              _buildActionButtonsRow(),
              const SizedBox(height: 24),

              // Texte source section
              _buildSourceTextSection(project),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverSection(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
      ),
      child: Center(
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: project.coverUrl != null
                ? Image.network(
                    project.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        LucideIcons.bookOpen,
                        size: 48,
                        color: AppColors.neutral400,
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      LucideIcons.bookOpen,
                      size: 48,
                      color: AppColors.neutral400,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataLine(Project project) {
    // Build metadata parts
    final parts = <String>[];

    if (project.style != null) {
      parts.add('Style ${project.style}');
    }

    // Duration
    if (project.videoDurationSeconds != null) {
      parts.add(project.formattedDuration);
    }

    // Date
    parts.add(_formatDate(project.createdAt));

    return Text(
      parts.join(' • '),
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
    );
  }

  Widget _buildVisionnerButton(Project project) {
    final isReady = project.status == ProjectStatus.ready;
    final isProcessing = project.status == ProjectStatus.processing;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isReady ? _onVisionner : null,
        icon: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.play, size: 20),
        label: Text(
          isProcessing ? 'En cours...' : 'Visionner',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neutral900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: LucideIcons.palette,
            label: 'Modifier',
            onTap: _onModifier,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: LucideIcons.share2,
            label: 'Partager',
            onTap: _onPartager,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceTextSection(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Texte source',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            project.title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.neutral700 : AppColors.neutral200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: AppColors.neutral700),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.neutral700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
