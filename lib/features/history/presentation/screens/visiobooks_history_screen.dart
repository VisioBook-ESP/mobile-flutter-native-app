import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/skeleton_loader.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';
import 'package:visiobook_mobile/features/generation/presentation/providers/generation_provider.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';

enum _VisioBookFilter { tous, prets, enCours }

class VisiobooksHistoryScreen extends StatefulWidget {
  const VisiobooksHistoryScreen({super.key});

  @override
  State<VisiobooksHistoryScreen> createState() =>
      _VisiobooksHistoryScreenState();
}

class _VisiobooksHistoryScreenState extends State<VisiobooksHistoryScreen> {
  _VisioBookFilter _selectedFilter = _VisioBookFilter.tous;

  List<Project> _filterProjects(ProjectProvider provider) {
    switch (_selectedFilter) {
      case _VisioBookFilter.tous:
        return provider.projects;
      case _VisioBookFilter.prets:
        return provider.readyProjects;
      case _VisioBookFilter.enCours:
        return provider.projects
            .where(
              (p) =>
                  p.status == ProjectStatus.processing ||
                  p.status == ProjectStatus.draft,
            )
            .toList();
    }
  }

  void _showContextMenu(BuildContext context, Project project) {
    final provider = context.read<ProjectProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              project.title,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            _contextMenuItem(
              icon: LucideIcons.palette,
              label: 'Modifier la configuration',
              onTap: () {
                Navigator.pop(ctx);
                context.push('/project/${project.id}/config');
              },
            ),
            _contextMenuItem(
              icon: LucideIcons.copy,
              label: 'Dupliquer',
              onTap: () async {
                Navigator.pop(ctx);
                final result = await provider.duplicateProject(project.id);
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${result.title}" créé')),
                  );
                }
              },
            ),
            _contextMenuItem(
              icon: LucideIcons.trash2,
              label: 'Supprimer',
              color: AppColors.error,
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dlgCtx) => AlertDialog(
                    title: const Text('Supprimer le VisioBook'),
                    content: Text(
                      'Voulez-vous vraiment supprimer "${project.title}" ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dlgCtx, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dlgCtx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  provider.deleteProject(project.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _contextMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final isDarkCtx = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icon,
        color:
            color ?? (isDarkCtx ? AppColors.neutral300 : AppColors.neutral700),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color:
              color ?? (isDarkCtx ? AppColors.neutral50 : AppColors.neutral900),
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Mes VisioBooks',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildFilterChips(),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ProjectProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                      itemCount: 4,
                      itemBuilder: (_, _) => const SkeletonProjectCard(),
                    );
                  }

                  final projects = _filterProjects(provider);

                  if (projects.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadProjects(),
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        final genProvider = context.watch<GenerationProvider>();
                        final hasGen = genProvider.hasActiveGeneration(
                          project.id,
                        );
                        return _VisioBookCard(
                          project: project,
                          generationProgress: hasGen
                              ? genProvider.getProgress(project.id)
                              : null,
                          onTap: () {
                            if (hasGen &&
                                genProvider.isInProgress(project.id)) {
                              final gen = genProvider.getGeneration(
                                project.id,
                              )!;
                              context.push(
                                '/project/${project.id}/generate/${gen.versionId}/${gen.executionId}',
                              );
                            } else {
                              if (hasGen) {
                                genProvider.clearGeneration(project.id);
                              }
                              context.push('/project/${project.id}');
                            }
                          },
                          onLongPress: () => _showContextMenu(context, project),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildChip('Tous', _VisioBookFilter.tous),
          const SizedBox(width: 8),
          _buildChip('Pr\u00eats', _VisioBookFilter.prets),
          const SizedBox(width: 8),
          _buildChip('En cours', _VisioBookFilter.enCours),
        ],
      ),
    );
  }

  Widget _buildChip(String label, _VisioBookFilter filter) {
    final isSelected = _selectedFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.neutral900)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.neutral100),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.neutral300 : AppColors.neutral600),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.playCircle, size: 64, color: AppColors.neutral300),
            const SizedBox(height: 16),
            Text(
              'Aucun VisioBook',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.neutral500),
            ),
            const SizedBox(height: 8),
            Text(
              'Cr\u00e9ez votre premier VisioBook\npour le voir ici',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisioBookCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double? generationProgress;

  const _VisioBookCard({
    required this.project,
    required this.onTap,
    required this.onLongPress,
    this.generationProgress,
  });

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.ready:
        return AppColors.success;
      case ProjectStatus.processing:
        return AppColors.warning;
      case ProjectStatus.draft:
        return AppColors.info;
      case ProjectStatus.error:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildCover(context)),
          if (generationProgress != null &&
              project.status == ProjectStatus.processing)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: generationProgress!),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: AppColors.neutral200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.info,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(generationProgress! * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            project.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(project.updatedAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.neutral400),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image or placeholder
          if (project.coverUrl != null)
            Image.network(
              project.coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPlaceholder(),
            )
          else
            _buildPlaceholder(),

          // Status badge (top-left)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _statusColor(project.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    project.status.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Duration badge (bottom-right)
          if (project.videoDurationSeconds != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  project.formattedDuration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.neutral100,
          child: Center(
            child: Icon(
              LucideIcons.playCircle,
              size: 40,
              color: AppColors.neutral400,
            ),
          ),
        );
      },
    );
  }
}
