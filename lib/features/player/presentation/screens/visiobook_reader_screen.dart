import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
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

/// Carte d'un panel avec video autoplay ou thumbnail fallback
class _PanelCard extends StatefulWidget {
  final VisiobookPanel panel;
  final int index;
  final bool isActive;

  const _PanelCard({
    required this.panel,
    required this.index,
    required this.isActive,
  });

  @override
  State<_PanelCard> createState() => _PanelCardState();
}

class _PanelCardState extends State<_PanelCard> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

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
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant _PanelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _handleActiveChange();
    }
  }

  void _initVideo() {
    final videoUrl = widget.panel.videoUrl;
    if (videoUrl.isEmpty) {
      _videoError = true;
      return;
    }

    final uri = Uri.tryParse(videoUrl);
    if (uri == null) {
      _videoError = true;
      return;
    }

    _videoController = VideoPlayerController.networkUrl(uri);
    _videoController!.setLooping(true);
    _videoController!.setVolume(0); // Muted per spec
    _videoController!
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() => _videoInitialized = true);
            if (widget.isActive) {
              _videoController!.play();
            }
          }
        })
        .catchError((_) {
          if (mounted) {
            setState(() => _videoError = true);
          }
        });
  }

  void _handleActiveChange() {
    if (_videoController == null || !_videoInitialized) return;
    if (widget.isActive) {
      _videoController!.seekTo(Duration.zero);
      _videoController!.play();
    } else {
      _videoController!.pause();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _panelColors[widget.index % _panelColors.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isActive
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          width: widget.isActive ? 1 : 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video ou thumbnail fallback
          _buildBackground(color),
          // Narrator text (cartouche en haut)
          if (widget.panel.narratorText != null)
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
                  widget.panel.narratorText!,
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
          if (widget.panel.dialogueText != null)
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
                  widget.panel.dialogueText!,
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
        ],
      ),
    );
  }

  Widget _buildBackground(Color fallbackColor) {
    // Video initialisee et pas d'erreur → afficher la video
    if (_videoInitialized && !_videoError && _videoController != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail en dessous pendant le premier frame
          _buildThumbnail(fallbackColor),
          // Video par dessus
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ],
      );
    }

    // Fallback: thumbnail ou gradient
    return _buildThumbnail(fallbackColor);
  }

  Widget _buildThumbnail(Color fallbackColor) {
    if (widget.panel.thumbnailUrl.isEmpty) {
      return _buildGradient(fallbackColor);
    }

    return Image.network(
      widget.panel.thumbnailUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildGradient(fallbackColor),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildGradient(fallbackColor);
      },
    );
  }

  Widget _buildGradient(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.3)!],
        ),
      ),
    );
  }
}
