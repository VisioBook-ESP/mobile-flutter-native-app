import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/skeleton_loader.dart';
import 'package:visiobook_mobile/features/history/domain/user_file.dart';
import 'package:visiobook_mobile/features/generation/domain/ingestion_state.dart';
import 'package:visiobook_mobile/features/history/presentation/providers/texts_provider.dart';

/// Filtre actif pour la liste des textes
enum _TextFilter { tous, recents }

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TextsProvider>().loadFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filtre et retourne les fichiers selon la recherche et le filtre actif
  List<UserFile> _getFilteredFiles(List<UserFile> files) {
    var filtered = List<UserFile>.from(files);

    switch (_selectedFilter) {
      case _TextFilter.tous:
        break;
      case _TextFilter.recents:
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        filtered = filtered
            .where((f) => f.createdAt.isAfter(sevenDaysAgo))
            .toList();
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((f) => f.name.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
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
              child: Builder(
                builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.neutral50
                          : AppColors.neutral900,
                    ),
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
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.neutral100,
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
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.neutral50
                              : AppColors.neutral900,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  );
                },
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Liste des textes
            Expanded(
              child: Consumer<TextsProvider>(
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

                  final filtered = _getFilteredFiles(provider.files);

                  if (provider.files.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (filtered.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadFiles(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.neutral200,
                      ),
                      itemBuilder: (context, index) {
                        final file = filtered[index];
                        return _buildFileItem(context, file);
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

  Widget _buildFilterChip(String label, _TextFilter filter) {
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
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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

  Widget _buildFileItem(BuildContext context, UserFile file) {
    final date = file.createdAt;
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final wordCount = file.wordCount ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textsProvider = context.read<TextsProvider>();
    final isIngesting = textsProvider.isIngesting(file.id);
    final ingestionState = textsProvider.getIngestionState(file.id);
    final isFailed = ingestionState?.status == IngestionStatus.failed;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(
          _getFileIcon(file.fileType),
          color: isIngesting
              ? Colors.blue
              : isDark
              ? AppColors.neutral300
              : AppColors.neutral600,
          size: 22,
        ),
      ),
      title: Text(
        file.name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.neutral50 : AppColors.neutral900,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isIngesting
            ? 'Ingestion en cours...'
            : isFailed
            ? 'Échec de l\'ingestion'
            : '$wordCount mots · $formattedDate',
        style: TextStyle(
          fontSize: 13,
          color: isIngesting
              ? Colors.blue
              : isFailed
              ? AppColors.error
              : AppColors.neutral500,
        ),
      ),
      trailing: isIngesting
          ? const Icon(LucideIcons.loader, color: Colors.blue, size: 20)
          : isFailed
          ? const Icon(
              LucideIcons.alertCircle,
              color: AppColors.error,
              size: 20,
            )
          : const Icon(
              LucideIcons.chevronRight,
              color: AppColors.neutral400,
              size: 20,
            ),
      onTap: () => context.push('/text/${file.id}'),
    );
  }

  IconData _getFileIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return LucideIcons.fileText;
      case 'txt':
        return LucideIcons.fileText;
      case 'docx':
        return LucideIcons.fileText;
      case 'epub':
        return LucideIcons.bookOpen;
      default:
        return LucideIcons.file;
    }
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: const Icon(
                LucideIcons.fileText,
                size: 36,
                color: AppColors.neutral400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun texte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.neutral50 : AppColors.neutral900,
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

  Widget _buildNoResultsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            Text(
              'Aucun résultat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.neutral50 : AppColors.neutral900,
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
