import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/widgets.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';
import 'package:visiobook_mobile/features/projects/presentation/widgets/project_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Charger les projets au demarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    if (index == 1) {
      _showProfileModal();
    }
  }

  void _onAddTap() {
    _showAddModal();
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            const SizedBox(height: 24),
            Text(
              'Nouveau projet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _ModalOption(
              icon: LucideIcons.upload,
              title: 'Importer un fichier',
              subtitle: 'PDF, TXT, DOCX, EPUB',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to import screen
              },
            ),
            const SizedBox(height: 12),
            _ModalOption(
              icon: LucideIcons.camera,
              title: 'Scanner un document',
              subtitle: 'Utilisez votre camera',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to scan screen
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            const SizedBox(height: 24),
            Text('Profil', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            AppButton(
              text: 'Se deconnecter',
              variant: AppButtonVariant.outline,
              fullWidth: true,
              onPressed: () {
                final authProvider = context.read<AuthProvider>();
                final navigator = GoRouter.of(context);
                Navigator.pop(context);
                authProvider.logout().then((_) {
                  navigator.go(AppRoutes.splash);
                });
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer<ProjectProvider>(
          builder: (context, projectProvider, _) {
            if (projectProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (projectProvider.state == ProjectsState.error) {
              return _buildErrorState(projectProvider.error);
            }

            return RefreshIndicator(
              onRefresh: () => projectProvider.loadProjects(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    if (projectProvider.readyProjects.isNotEmpty) ...[
                      _SectionHeader(title: 'Mes VisioBooks'),
                      _buildProjectsList(projectProvider.readyProjects),
                      const SizedBox(height: 24),
                    ],
                    if (projectProvider.draftProjects.isNotEmpty) ...[
                      _SectionHeader(title: 'En cours'),
                      _buildProjectsList(projectProvider.draftProjects),
                    ],
                    if (projectProvider.projects.isEmpty) _buildEmptyState(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        onAddTap: _onAddTap,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              LucideIcons.user,
              size: 32,
              color: AppColors.neutral400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour !',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 2),
                Consumer<ProjectProvider>(
                  builder: (context, provider, _) {
                    final count = provider.projects.length;
                    return Text(
                      '$count projet${count > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(List<Project> projects) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < projects.length - 1 ? 16 : 0,
            ),
            child: ProjectCard(
              project: project,
              onTap: () {
                context.push('/project/${project.id}');
              },
            ),
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
            Icon(LucideIcons.bookOpen, size: 64, color: AppColors.neutral300),
            const SizedBox(height: 16),
            Text(
              'Aucun projet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.neutral500),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour creer votre premier VisioBook',
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
              text: 'Reessayer',
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
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

class _ModalOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModalOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.neutral900),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }
}
