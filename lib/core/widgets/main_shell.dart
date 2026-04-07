import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:visiobook_mobile/core/widgets/glass_container.dart';
import 'package:visiobook_mobile/core/widgets/gradient_background.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  /// Maps branch index (0-3) to visual nav index (0,1,2,4).
  /// Branch 0 = Home (nav 0), Branch 1 = Texts (nav 1),
  /// Branch 2 = VisioBooks (nav 2), Branch 3 = Profile (nav 4).
  int _branchToNavIndex(int branchIndex) {
    switch (branchIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 4;
      default:
        return 0;
    }
  }

  /// Maps visual nav index (0,1,2,4) to branch index (0-3).
  int _navToBranchIndex(int navIndex) {
    switch (navIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: BottomNavBar(
          currentIndex: _branchToNavIndex(navigationShell.currentIndex),
          onTap: (index) => _onTap(context, index),
          onAddTap: () => _showImportModal(context),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int navIndex) {
    final branchIndex = _navToBranchIndex(navIndex);
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  void _showImportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
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
                  'Ajouter un texte',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _ModalOption(
                  icon: LucideIcons.upload,
                  title: 'Importer un fichier',
                  subtitle: 'PDF, TXT, DOCX, EPUB',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.fileImport);
                  },
                ),
                const SizedBox(height: 12),
                _ModalOption(
                  icon: LucideIcons.camera,
                  title: 'Scanner un document',
                  subtitle: 'Utilisez votre caméra',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(AppRoutes.scan);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
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
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: AppTheme.radiusMd,
        blur: 10,
        opacity: 0.5,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.neutral50
                    : AppColors.neutral900,
              ),
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
            Icon(
              LucideIcons.chevronRight,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.neutral500
                  : AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
