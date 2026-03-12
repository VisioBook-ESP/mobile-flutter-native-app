import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/skeleton_loader.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';

/// Filtre actif pour la liste des textes
enum _TextFilter { tous, recents, utilises }

/// Ecran "Mes Textes" - liste scrollable des textes importes
class TextsHistoryScreen extends StatefulWidget {
  const TextsHistoryScreen({super.key});

  @override
  State<TextsHistoryScreen> createState() => _TextsHistoryScreenState();
}

class _TextsHistoryScreenState extends State<TextsHistoryScreen> {
  String _searchQuery = '';
  _TextFilter _selectedFilter = _TextFilter.tous;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filtre et retourne les projets selon la recherche et le filtre actif
  List<Project> _getFilteredProjects(List<Project> projects) {
    var filtered = List<Project>.from(projects);

    // Appliquer le filtre
    switch (_selectedFilter) {
      case _TextFilter.tous:
        break;
      case _TextFilter.recents:
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        filtered = filtered
            .where((p) => p.updatedAt.isAfter(sevenDaysAgo))
            .toList();
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _TextFilter.utilises:
        filtered = filtered
            .where((p) => p.status == ProjectStatus.ready)
            .toList();
    }

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) => p.title.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  /// Retourne l'icone correspondant au statut du projet
  IconData _getStatusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.draft:
        return LucideIcons.fileText;
      case ProjectStatus.processing:
        return LucideIcons.loader;
      case ProjectStatus.ready:
        return LucideIcons.checkCircle;
      case ProjectStatus.error:
        return LucideIcons.alertCircle;
    }
  }

  /// Retourne la couleur correspondant au statut du projet
  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.draft:
        return AppColors.neutral500;
      case ProjectStatus.processing:
        return AppColors.warning;
      case ProjectStatus.ready:
        return AppColors.success;
      case ProjectStatus.error:
        return AppColors.error;
    }
  }

  /// Approximation du nombre de mots a partir de la description
  int _approximateWordCount(String? description) {
    if (description == null || description.isEmpty) return 0;
    return description.split(RegExp(r'\s+')).length;
  }

  /// Affiche le menu contextuel (modifier, dupliquer, supprimer)
  void _showContextMenu(
    BuildContext context,
    Project project,
    ProjectProvider provider,
  ) {
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
              icon: LucideIcons.edit3,
              label: 'Modifier',
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
                final confirmed = await _showDeleteConfirmation(
                  context,
                  project,
                );
                if (confirmed) {
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
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.neutral700, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.neutral900,
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      onTap: onTap,
    );
  }

  /// Affiche le dialogue de confirmation de suppression
  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    Project project,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Supprimer le texte'),
        content: Text('Voulez-vous vraiment supprimer "${project.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.neutral900),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mes Textes',
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

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Rechercher un texte...',
                  hintStyle: const TextStyle(color: AppColors.neutral400),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    color: AppColors.neutral400,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: AppColors.neutral400,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.neutral100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.neutral900,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filtres
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFilterChip('Tous', _TextFilter.tous),
                  const SizedBox(width: 8),
                  _buildFilterChip('Récents', _TextFilter.recents),
                  const SizedBox(width: 8),
                  _buildFilterChip('Utilisés', _TextFilter.utilises),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Liste des textes
            Expanded(
              child: Consumer<ProjectProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: List.generate(
                          6,
                          (_) => const SkeletonListItem(),
                        ),
                      ),
                    );
                  }

                  final filtered = _getFilteredProjects(provider.projects);

                  if (provider.projects.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (filtered.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadProjects(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.neutral200),
                      itemBuilder: (context, index) {
                        final project = filtered[index];
                        return _buildInputItem(context, project, provider);
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

  /// Construit un chip de filtre
  Widget _buildFilterChip(String label, _TextFilter filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neutral900 : AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.neutral600,
          ),
        ),
      ),
    );
  }

  /// Construit un item de la liste (InputItem)
  Widget _buildInputItem(
    BuildContext context,
    Project project,
    ProjectProvider provider,
  ) {
    final date = project.updatedAt;
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final wordCount = _approximateWordCount(project.description);
    final statusIcon = _getStatusIcon(project.status);
    final statusColor = _getStatusColor(project.status);

    return Dismissible(
      key: Key(project.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteConfirmation(context, project),
      onDismissed: (_) => provider.deleteProject(project.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.error,
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(statusIcon, color: statusColor, size: 22),
        ),
        title: Text(
          project.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$wordCount mots · $formattedDate',
          style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
        ),
        trailing: IconButton(
          icon: const Icon(
            LucideIcons.moreVertical,
            color: AppColors.neutral400,
            size: 20,
          ),
          onPressed: () => _showContextMenu(context, project, provider),
        ),
        onTap: () => context.push('/project/${project.id}/config'),
      ),
    );
  }

  /// Etat vide quand aucun projet n'existe
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: const Icon(
                LucideIcons.fileText,
                size: 36,
                color: AppColors.neutral400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun texte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Importez votre premier texte pour commencer',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.neutral500),
            ),
          ],
        ),
      ),
    );
  }

  /// Etat quand la recherche/filtre ne retourne aucun resultat
  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.searchX,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun résultat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun texte ne correspond à "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}
