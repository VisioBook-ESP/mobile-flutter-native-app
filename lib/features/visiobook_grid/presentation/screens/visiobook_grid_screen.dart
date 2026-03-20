import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/features/visiobook_grid/data/mock_visiobook_data.dart';
import 'package:visiobook_mobile/features/visiobook_grid/domain/visiobook_models.dart';

class VisiobookGridScreen extends StatefulWidget {
  const VisiobookGridScreen({super.key});

  @override
  State<VisiobookGridScreen> createState() => _VisiobookGridScreenState();
}

class _VisiobookGridScreenState extends State<VisiobookGridScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

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
    Color(0xFF2d132c),
    Color(0xFF0a2e36),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visiobook = MockVisiobookData.getMockVisiobook();

    final allPanels = <VisiobookPanel>[];
    for (final page in visiobook.pages) {
      allPanels.addAll(page.panels);
    }

    return Scaffold(
      backgroundColor: AppColors.neutral900,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, visiobook, allPanels.length),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: allPanels.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: _buildPanel(
                      context,
                      allPanels[index],
                      index,
                      isActive: index == _currentIndex,
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

  Widget _buildTopBar(
    BuildContext context,
    VisiobookData visiobook,
    int totalPanels,
  ) {
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
              visiobook.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentIndex + 1} / $totalPanels',
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

  Widget _buildPanel(
    BuildContext context,
    VisiobookPanel panel,
    int index, {
    required bool isActive,
  }) {
    final color = _panelColors[index % _panelColors.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.3)!],
        ),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: isActive ? 1 : 0.5,
        ),
      ),
      child: Stack(
        children: [
          // Icone centrale : play si inactif, animation si actif
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
                color: Colors.black.withValues(alpha: 0.4),
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
          // Narrator text
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
          // Dialogue text
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
          // Indicateur "en lecture" en bas
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.radio,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
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
}

/// Barres animees qui simulent une video en cours de lecture
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
