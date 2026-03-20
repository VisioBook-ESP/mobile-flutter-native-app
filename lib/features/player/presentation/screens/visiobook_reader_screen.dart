import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/features/player/domain/visiobook_reader_state.dart';
import 'package:visiobook_mobile/features/player/presentation/providers/player_provider.dart';

/// Ecran de lecture VisioBook - PageView vertical avec snap
class VisioBookReaderScreen extends StatefulWidget {
  final String projectId;

  const VisioBookReaderScreen({super.key, required this.projectId});

  @override
  State<VisioBookReaderScreen> createState() => _VisioBookReaderScreenState();
}

class _VisioBookReaderScreenState extends State<VisioBookReaderScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadVisioBook(widget.projectId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) return '$minutes min $seconds sec';
    return '$seconds sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral900,
      body: SafeArea(
        child: Consumer<PlayerProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (provider.error != null) {
              return _buildError(provider);
            }

            if (provider.visioBook == null) {
              return const SizedBox.shrink();
            }

            final panels = provider.allPanels;

            return Column(
              children: [
                _buildTopBar(provider),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: provider.onPageChanged,
                    // +1 pour l'ecran de fin
                    itemCount: panels.length + 1,
                    itemBuilder: (context, index) {
                      if (index < panels.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: _PanelCard(
                            panel: panels[index],
                            index: index,
                            isActive: index == provider.currentPanelIndex,
                          ),
                        );
                      }
                      return _buildEndScreen(provider);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(PlayerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go(AppRoutes.dashboard),
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              provider.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (provider.totalPanels > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.currentPanelIndex + 1} / ${provider.totalPanels}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(PlayerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              color: AppColors.neutral500,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: const TextStyle(color: AppColors.neutral200, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Reessayer',
              size: AppButtonSize.lg,
              onPressed: () => provider.loadVisioBook(widget.projectId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndScreen(PlayerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
              ),
              child: const Icon(
                LucideIcons.checkCircle,
                color: AppColors.success,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fin du VisioBook',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${provider.totalPanels} vignettes | ${_formatDuration(provider.readingDuration)}',
              style: const TextStyle(color: AppColors.neutral500, fontSize: 15),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Rejouer',
                fullWidth: true,
                size: AppButtonSize.lg,
                icon: const Icon(
                  LucideIcons.rotateCcw,
                  size: 18,
                  color: AppColors.neutral900,
                ),
                onPressed: () {
                  provider.replay();
                  _goToPage(0);
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go(AppRoutes.dashboard),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: const Text(
                  'Retour au projet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'un panel avec placeholder ou thumbnail
class _PanelCard extends StatelessWidget {
  final VisiobookPanel panel;
  final int index;
  final bool isActive;

  const _PanelCard({
    required this.panel,
    required this.index,
    required this.isActive,
  });

  static const _panelColors = [
    Color(0xFF1a1a2e),
    Color(0xFF16213e),
    Color(0xFF0f3460),
    Color(0xFF533483),
    Color(0xFF2c3e50),
    Color(0xFF1b2631),
    Color(0xFF0e4d45),
    Color(0xFF2d1b4e),
    Color(0xFF1c2833),
    Color(0xFF0b3d36),
    Color(0xFF3c1642),
    Color(0xFF1a3a4a),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _panelColors[index % _panelColors.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          width: isActive ? 1 : 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail ou placeholder
          _buildBackground(color),
          // Indicateur central
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isActive
                  ? _PlayingIndicator(key: ValueKey('playing_$index'))
                  : Icon(
                      LucideIcons.play,
                      key: ValueKey('paused_$index'),
                      color: Colors.white.withValues(alpha: 0.2),
                      size: 48,
                    ),
            ),
          ),
          // Panel ID
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                panel.id,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          // Narrator text (cartouche en haut)
          if (panel.narratorText != null)
            Positioned(
              top: 8,
              left: 8,
              right: 50,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8DC).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFD4A574),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  panel.narratorText!,
                  style: const TextStyle(
                    color: Color(0xFF2C1810),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          // Dialogue text (bulle en bas)
          if (panel.dialogueText != null)
            Positioned(
              bottom: 12,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  panel.dialogueText!,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          // Badge "En lecture"
          if (isActive)
            Positioned(
              bottom: panel.dialogueText != null ? 56 : 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.radio,
                        size: 12,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'En lecture',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color fallbackColor) {
    // Essaye de charger la thumbnail, sinon gradient
    return Image.network(
      panel.thumbnailUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fallbackColor,
                Color.lerp(fallbackColor, Colors.black, 0.3)!,
              ],
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fallbackColor,
                Color.lerp(fallbackColor, Colors.black, 0.3)!,
              ],
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white.withValues(alpha: 0.3),
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}

/// Barres animees simulant une video en lecture
class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator({super.key});

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (i) {
            final offset = i * 0.15;
            final value = (_controller.value + offset) % 1.0;
            final height = 16.0 + 24.0 * value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
