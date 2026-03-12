import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/features/export/presentation/widgets/export_share_sheet.dart';
import 'package:visiobook_mobile/features/player/domain/visiobook_reader_state.dart';
import 'package:visiobook_mobile/features/player/presentation/providers/player_provider.dart';

/// Ecran de lecture VisioBook style Webtoon (defilement vertical)
class VisioBookReaderScreen extends StatefulWidget {
  final String projectId;

  const VisioBookReaderScreen({super.key, required this.projectId});

  @override
  State<VisioBookReaderScreen> createState() => _VisioBookReaderScreenState();
}

class _VisioBookReaderScreenState extends State<VisioBookReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showControls = true;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().loadVisioBook(widget.projectId);
      _startAutoHideTimer();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final provider = context.read<PlayerProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth * 0.75 + 16;
    final scrollOffset = _scrollController.offset;
    final currentScene = (scrollOffset / cardHeight).round();
    final clampedIndex = currentScene.clamp(0, provider.totalScenes - 1);

    provider.updateCurrentScene(clampedIndex);

    // Reset auto-hide timer on scroll
    _resetAutoHideTimer();
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _resetAutoHideTimer() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
    _startAutoHideTimer();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startAutoHideTimer();
    }
  }

  void _scrollToScene(int index) {
    if (!_scrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth * 0.75 + 16;
    _scrollController.animateTo(
      index * cardHeight,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes min $seconds sec';
    }
    return '$seconds sec';
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral900,
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          return GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              children: [
                // Main content
                _buildMainContent(provider),
                // Floating top bar
                _buildTopBar(provider),
                // Floating bottom bar
                _buildBottomBar(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(PlayerProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (provider.error != null) {
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
                style: const TextStyle(
                  color: AppColors.neutral200,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Réessayer',
                size: AppButtonSize.lg,
                onPressed: () => provider.loadVisioBook(widget.projectId),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.visioBook == null) {
      return const SizedBox.shrink();
    }

    return _buildSceneList(provider);
  }

  Widget _buildSceneList(PlayerProvider provider) {
    final scenes = provider.visioBook!.scenes;
    // Add 1 extra item for the end screen
    final itemCount = scenes.length + 1;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        bottom: MediaQuery.of(context).padding.bottom + 60,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < scenes.length) {
          return _buildSceneCard(scenes[index], provider);
        }
        // End screen as the last item
        return _buildEndScreen(provider);
      },
    );
  }

  Widget _buildSceneCard(VisioBookScene scene, PlayerProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth * 0.75;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: screenWidth,
        height: imageHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Scene image
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.network(
                scene.imageUrl,
                fit: BoxFit.cover,
                width: screenWidth,
                height: imageHeight,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  final total = loadingProgress.expectedTotalBytes;
                  final progress = total != null
                      ? loadingProgress.cumulativeBytesLoaded / total
                      : null;
                  return Container(
                    color: AppColors.neutral800,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress,
                        color: AppColors.neutral500,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.neutral800,
                    child: const Center(
                      child: Icon(
                        LucideIcons.imageOff,
                        color: AppColors.neutral500,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Subtitle overlay
            if (provider.showSubtitles && scene.subtitleText != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                  child: Text(
                    scene.subtitleText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndScreen(PlayerProvider provider) {
    if (!provider.hasReachedEnd) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final duration = provider.readingDuration;

    return SizedBox(
      height: screenHeight * 0.85,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Check circle icon
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
              // Title
              const Text(
                'Fin du VisioBook',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Stats
              Text(
                '${provider.totalScenes} scenes | ${_formatDuration(duration)}',
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              // Replay button
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
                    _scrollToScene(0);
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Share button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ExportShareSheet.show(
                      context: context,
                      projectId: widget.projectId,
                      projectTitle: provider.title,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  icon: const Icon(
                    LucideIcons.share2,
                    size: 18,
                    color: Colors.white70,
                  ),
                  label: const Text(
                    'Partager',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Back to project button
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
      ),
    );
  }

  Widget _buildTopBar(PlayerProvider provider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !_showControls,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  icon: const Icon(
                    LucideIcons.arrowLeft,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 4),
                // Title
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
                const SizedBox(width: 8),
                // Scene counter
                if (provider.totalScenes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.currentSceneIndex + 1}/${provider.totalScenes}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(PlayerProvider provider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !_showControls,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              left: 12,
              right: 16,
              top: 16,
            ),
            child: Row(
              children: [
                // Play/pause
                IconButton(
                  onPressed: provider.togglePause,
                  icon: Icon(
                    provider.isPaused ? LucideIcons.play : LucideIcons.pause,
                    color: Colors.white,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
                // Mute
                IconButton(
                  onPressed: provider.toggleMute,
                  icon: Icon(
                    provider.isMuted
                        ? LucideIcons.volumeX
                        : LucideIcons.volume2,
                    color: Colors.white,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
                // Subtitles toggle (CC)
                IconButton(
                  onPressed: provider.toggleSubtitles,
                  icon: Icon(
                    LucideIcons.subtitles,
                    color: provider.showSubtitles
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 12),
                // Progress bar
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: provider.progress,
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
