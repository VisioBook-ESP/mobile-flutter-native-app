import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/features/generation/domain/generation_state.dart';
import 'package:visiobook_mobile/features/generation/presentation/providers/generation_provider.dart';

/// Ecran de generation de video
/// Affiche la progression pendant la generation d'un VisioBook
class GenerationScreen extends StatefulWidget {
  final String projectId;
  final String versionId;
  final String executionId;

  const GenerationScreen({
    super.key,
    required this.projectId,
    required this.versionId,
    required this.executionId,
  });

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _successController;
  late Animation<double> _successScaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GenerationProvider>();
      // Ne demarrer le polling que si pas deja actif pour ce projet
      if (!provider.hasActiveGeneration(widget.projectId)) {
        provider.startPolling(
          widget.projectId,
          widget.versionId,
          widget.executionId,
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral900,
      body: Consumer<GenerationProvider>(
        builder: (context, provider, _) {
          final generation = provider.getGeneration(widget.projectId);

          if (generation == null) {
            return _buildLoadingState();
          }

          if (generation.isCancelled) {
            return _buildCancelledState(context);
          }

          final state = generation.workflowState;
          if (state == null) {
            return _buildLoadingState();
          }

          switch (state.status) {
            case WorkflowStatus.pending:
            case WorkflowStatus.running:
            case WorkflowStatus.processing:
              return _buildGeneratingState(context, provider, state);
            case WorkflowStatus.completed:
              _pulseController.stop();
              _successController.forward();
              return _buildCompletedState(context, state);
            case WorkflowStatus.failed:
              return _buildErrorState(context, provider, state);
            case WorkflowStatus.cancelled:
              return _buildCancelledState(context);
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildGeneratingState(
    BuildContext context,
    GenerationProvider provider,
    WorkflowState state,
  ) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          LucideIcons.wand2,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        provider.getStepLabel(widget.projectId),
                        key: ValueKey(provider.getStepLabel(widget.projectId)),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        provider.getStepDescription(widget.projectId),
                        key: ValueKey(
                          provider.getStepDescription(widget.projectId),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildProgressBar(state),
                    const SizedBox(height: 12),
                    Text(
                      '${(state.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildStepIndicators(state.currentStep),
                    const SizedBox(height: 20),
                    if (state.estimatedTimeRemaining != null)
                      Text(
                        _formatTimeRemaining(state.estimatedTimeRemaining!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Boutons: retour au dashboard + annuler
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      size: 18,
                      color: Colors.white70,
                    ),
                    label: const Text(
                      'Continuer en arrière-plan',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showCancelConfirmation(context, provider),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Annuler la génération',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.4),
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(WorkflowState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: state.progress),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        builder: (context, value, _) {
          return LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicators(GenerationStep currentStep) {
    final steps = [
      _StepInfo(GenerationStep.analysis, 'Analyse', LucideIcons.fileSearch),
      _StepInfo(
        GenerationStep.referenceGeneration,
        'Réfs',
        LucideIcons.palette,
      ),
      _StepInfo(GenerationStep.imageGeneration, 'Images', LucideIcons.image),
      _StepInfo(GenerationStep.audioGeneration, 'Audio', LucideIcons.mic),
      _StepInfo(GenerationStep.assembly, 'Montage', LucideIcons.clapperboard),
    ];

    final currentIndex = GenerationStep.values.indexOf(currentStep);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepDot(isCompleted: isCompleted, isCurrent: isCurrent),
              const SizedBox(height: 6),
              Text(
                step.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: isCurrent
                      ? Colors.white
                      : isCompleted
                      ? AppColors.success
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepDot({required bool isCompleted, required bool isCurrent}) {
    if (isCompleted) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success,
        ),
        child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
      );
    }

    if (isCurrent) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildCompletedState(BuildContext context, WorkflowState state) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _successScaleAnimation,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Votre VisioBook est prêt !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Votre vidéo a été générée avec succès.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AppButton(
                text: 'Voir le résultat',
                fullWidth: true,
                size: AppButtonSize.lg,
                icon: const Icon(
                  LucideIcons.play,
                  size: 20,
                  color: AppColors.neutral900,
                ),
                onPressed: () {
                  context.read<GenerationProvider>().clearGeneration(
                    widget.projectId,
                  );
                  context.go(
                    AppRoutes.player.replaceAll(':id', widget.projectId),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<GenerationProvider>().clearGeneration(
                      widget.projectId,
                    );
                    context.go(
                      AppRoutes.projectView.replaceAll(':id', widget.projectId),
                    );
                  },
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

  Widget _buildErrorState(
    BuildContext context,
    GenerationProvider provider,
    WorkflowState state,
  ) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  size: 44,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Échec de la génération',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Une erreur inattendue est survenue.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              AppButton(
                text: 'Réessayer',
                fullWidth: true,
                size: AppButtonSize.lg,
                icon: const Icon(
                  LucideIcons.refreshCw,
                  size: 20,
                  color: AppColors.neutral900,
                ),
                onPressed: () {
                  provider.startPolling(
                    widget.projectId,
                    widget.versionId,
                    widget.executionId,
                  );
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Ajuster les paramètres',
                variant: AppButtonVariant.outline,
                fullWidth: true,
                onPressed: () {
                  provider.clearGeneration(widget.projectId);
                  context.go(
                    AppRoutes.projectEditConfig.replaceAll(
                      ':id',
                      widget.projectId,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  provider.clearGeneration(widget.projectId);
                  context.go(AppRoutes.dashboard);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Retour au dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.6),
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withValues(alpha: 0.6),
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

  Widget _buildCancelledState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Icon(
                  LucideIcons.xCircle,
                  size: 44,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Génération annulée',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'La génération de votre VisioBook a été annulée.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AppButton(
                text: 'Retour au projet',
                fullWidth: true,
                size: AppButtonSize.lg,
                onPressed: () {
                  context.read<GenerationProvider>().clearGeneration(
                    widget.projectId,
                  );
                  context.go(
                    AppRoutes.projectView.replaceAll(':id', widget.projectId),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmation(
    BuildContext context,
    GenerationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.neutral800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text(
          'Annuler la génération ?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'La progression actuelle sera perdue. '
          'Vous devrez relancer la génération.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Continuer',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              provider.cancelGeneration(widget.projectId);
            },
            child: const Text(
              'Annuler la génération',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      return 'Environ $minutes min restante${minutes > 1 ? 's' : ''}';
    }
    final seconds = duration.inSeconds;
    return 'Environ $seconds seconde${seconds > 1 ? 's' : ''} restante${seconds > 1 ? 's' : ''}';
  }
}

class _StepInfo {
  final GenerationStep step;
  final String label;
  final IconData icon;

  const _StepInfo(this.step, this.label, this.icon);
}
