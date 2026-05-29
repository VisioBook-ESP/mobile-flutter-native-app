import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/widgets.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';
import 'package:visiobook_mobile/features/projects/presentation/widgets/project_card.dart';
import 'package:visiobook_mobile/features/projects/presentation/widgets/stats_card.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/features/generation/presentation/providers/generation_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les projets au demarrage
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProjectProvider>().loadProjects();
      if (!mounted) return;
      // En mode mock, demarrer les generations pour les projets en processing
      if (EnvironmentConfig.useMockData) {
        final processingIds = context
            .read<ProjectProvider>()
            .projects
            .where((p) => p.status == ProjectStatus.processing)
            .map((p) => p.id)
            .toList();
        if (processingIds.isNotEmpty) {
          context.read<GenerationProvider>().startMockGenerations(
            processingIds,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Consumer<ProjectProvider>(
          builder: (context, projectProvider, _) {
            if (projectProvider.isLoading) {
              return const SkeletonDashboard();
            }

            if (projectProvider.state == ProjectsState.error) {
              return _buildErrorState(projectProvider.error);
            }

            return Consumer<GenerationProvider>(
              builder: (context, genProvider, _) {
                // Filtrer les projets "ready" en excluant ceux avec une
                // generation active (en cours ou en erreur)
                final readyProjects = projectProvider.readyProjects.where((p) {
                  if (!genProvider.hasActiveGeneration(p.id)) return true;
                  if (genProvider.isInProgress(p.id)) return false;
                  if (genProvider.isFailed(p.id)) return false;
                  return true;
                }).toList();

                // Les projets "en cours" incluent les drafts/processing + les
                // projets ready dont la generation est en cours ou a echoue
                final draftProjects = [
                  ...projectProvider.draftProjects,
                  ...projectProvider.readyProjects.where((p) {
                    if (!genProvider.hasActiveGeneration(p.id)) return false;
                    return genProvider.isInProgress(p.id) ||
                        genProvider.isFailed(p.id);
                  }),
                ];

                return RefreshIndicator(
                  onRefresh: () => projectProvider.loadProjects(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildGreeting(context),
                        const SizedBox(height: 24),
                        if (projectProvider.projects.isNotEmpty) ...[
                          StatsCard(
                            visiobooksCount: readyProjects.length,
                            textsCount: projectProvider.textsCount,
                          ),
                          const SizedBox(height: 32),
                        ],
                        if (readyProjects.isNotEmpty) ...[
                          _SectionHeader(title: 'Mes VisioBooks'),
                          _buildProjectsList(readyProjects),
                          const SizedBox(height: 24),
                        ],
                        if (draftProjects.isNotEmpty) ...[
                          _SectionHeader(title: 'En cours'),
                          _buildProjectsList(draftProjects),
                          const SizedBox(height: 24),
                        ],
                        if (projectProvider.projects.isEmpty)
                          _buildEmptyState(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final userName = context.watch<AuthProvider>().userName;
    final greeting = userName != null ? 'Bonjour, $userName !' : 'Bonjour !';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(greeting, style: Theme.of(context).textTheme.displaySmall),
    );
  }

  Widget _buildProjectsList(List<Project> projects) {
    return SizedBox(
      height: 280,
      child: Consumer<GenerationProvider>(
        builder: (context, genProvider, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final hasGeneration = genProvider.hasActiveGeneration(project.id);
              final progress = hasGeneration
                  ? genProvider.getProgress(project.id)
                  : null;

              // Calculer le statut effectif base sur la generation
              ProjectStatus? effectiveStatus;
              if (hasGeneration) {
                if (genProvider.isInProgress(project.id)) {
                  effectiveStatus = ProjectStatus.processing;
                } else if (genProvider.isFailed(project.id)) {
                  effectiveStatus = ProjectStatus.error;
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  right: index < projects.length - 1 ? 16 : 0,
                ),
                child: ProjectCard(
                  project: project,
                  generationProgress: progress,
                  effectiveStatus: effectiveStatus,
                  onTap: () {
                    if (hasGeneration) {
                      final gen = genProvider.getGeneration(project.id)!;
                      final hasFailed = genProvider.isFailed(project.id);
                      final isInProgress = genProvider.isInProgress(project.id);

                      if (isInProgress || hasFailed) {
                        // En cours ou echouee : afficher l'ecran de generation
                        context.push(
                          '/project/${project.id}/generate/${gen.versionId}/${gen.executionId}',
                        );
                      } else {
                        // Generation terminee avec succes
                        genProvider.clearGeneration(project.id);
                        context.push('/project/${project.id}');
                      }
                    } else {
                      context.push('/project/${project.id}');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(
              LucideIcons.bookOpen,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.neutral600
                  : AppColors.neutral300,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun projet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.neutral400
                    : AppColors.neutral500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Importez un texte pour créer votre premier VisioBook',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.neutral500
                    : AppColors.neutral400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Réessayer',
              onPressed: () {
                context.read<ProjectProvider>().loadProjects();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.neutral400
              : AppColors.neutral600,
        ),
      ),
    );
  }
}
