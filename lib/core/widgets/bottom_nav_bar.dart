import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';

/// Bottom navigation bar
/// - Fond noir (neutral900)
/// - 5 items: Home, Mes Textes, Play (central), Add (+), Profil
/// - Index mapping: 0=Home, 1=Mes Textes, 2=Play (callback), 3=Add (callback), 4=Profil
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onAddTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onPlayTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.neutral900,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: LucideIcons.home,
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: LucideIcons.fileText,
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _PlayButton(onTap: onPlayTap),
                _NavItem(
                  icon: LucideIcons.plus,
                  isSelected: false,
                  onTap: () => onAddTap?.call(),
                ),
                _NavItem(
                  icon: LucideIcons.user,
                  isSelected: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(
            icon,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _PlayButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: Icon(LucideIcons.play, color: AppColors.neutral900, size: 28),
        ),
      ),
    );
  }
}
