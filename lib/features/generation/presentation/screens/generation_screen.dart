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
  final String workflowId;

  const GenerationScreen({
    super.key,
    required this.projectId,
    required this.workflowId,
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

    // Animation de pulsation pour l'icone principale
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation de succes (checkmark)
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    // Demarrer le polling de la generation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GenerationProvider>().startPolling(
        widget.projectId,
        widget.workflowId,
      );
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
          // Gerer l'animation de succes
          if (provider.workflowState?.status == WorkflowStatus.completed) {
            _pulseController.stop();
            _successController.forward();
          }

          if (provider.isCancelled) {
            return _buildCancelledState(context);
          }

          final state = provider.workflowState;
          if (state == null) {
            return _buildLoadingState();
          }

          switch (state.status) {
            case WorkflowStatus.pending:
            case WorkflowStatus.processing:
              return _buildGeneratingState(context, provider, state);
            case WorkflowStatus.completed:
              return _buildCompletedState(context, state);
            case WorkflowStatus.failed:
              return _buildErrorState(context, provider, state);
          }
        },
      ),
    );
  }

  /// Etat de chargement initial (avant de recevoir le premier etat)
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  /// Etat principal: generation en cours
  Widget _buildGeneratingState(
    BuildContext context,
    GenerationProvider provider,
    WorkflowState state,
  ) {
    return SafeArea(
      child: Column(
        children: [
          // Contenu central
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icone pulsante
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

                    // Label de l'etape en cours
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        provider.currentStepLabel,
                        key: ValueKey(provider.currentStepLabel),
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

                    // Description de l'etape
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        provider.currentStepDescription,
                        key: ValueKey(provider.currentStepDescription),
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

                    // Barre de progression
                    _buildProgressBar(state),
                    const SizedBox(height: 12),

                    // Pourcentage
                    Text(
                      '${(state.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Indicateurs d'etapes
                    _buildStepIndicators(state.currentStep),
                    const SizedBox(height: 20),

                    // Temps estime restant
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

          // Bouton annuler
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showCancelConfirmation(context, provider),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: const Text(
                  'Annuler',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barre de progression animee
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

  /// Indicateurs d'etapes (4 pastilles)
  Widget _buildStepIndicators(GenerationStep currentStep) {
    final steps = [
      _StepInfo(GenerationStep.analysis, 'Analyse', LucideIcons.fileSearch),
      _StepInfo(GenerationStep.images, 'Images', LucideIcons.image),
      _StepInfo(GenerationStep.audio, 'Audio', LucideIcons.mic),
      _StepInfo(
        GenerationStep.assembly,
        'Assemblage',
        LucideIcons.clapperboard,
      ),
    ];

    final currentIndex = GenerationStep.values.indexOf(currentStep);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepDot(isCompleted: isCompleted, isCurrent: isCurrent),
              const SizedBox(height: 6),
              Text(
                step.label,
                style: TextStyle(
                  fontSize: 11,
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

  /// Pastille individuelle d'etape
  Widget _buildStepDot({required bool isCompleted, required bool isCurrent}) {
    if (isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success,
        ),
        child: const Icon(LucideIcons.check, size: 14, color: Colors.white),
      );
    }

    if (isCurrent) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 24,
          height: 24,
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
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
    );
  }

  /// Etat: generation terminee
  Widget _buildCompletedState(BuildContext context, WorkflowState state) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animation de succes
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

              // Bouton voir le resultat
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
                  context.read<GenerationProvider>().reset();
                  context.go(
                    AppRoutes.player.replaceAll(':id', widget.projectId),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Bouton retour au projet
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<GenerationProvider>().reset();
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

  /// Etat: erreur de generation
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
              // Icone d'erreur
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

              // Bouton reessayer
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
                  provider.startPolling(widget.projectId, widget.workflowId);
                },
              ),
              const SizedBox(height: 12),

              // Bouton ajuster les parametres
              AppButton(
                text: 'Ajuster les paramètres',
                variant: AppButtonVariant.outline,
                fullWidth: true,
                onPressed: () {
                  provider.reset();
                  context.go(
                    AppRoutes.projectEditConfig.replaceAll(
                      ':id',
                      widget.projectId,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Bouton retour au dashboard
              GestureDetector(
                onTap: () {
                  provider.reset();
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

  /// Etat: generation annulee
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
                  context.read<GenerationProvider>().reset();
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

  /// Affiche un dialogue de confirmation avant d'annuler
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
              provider.cancelGeneration();
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

  /// Formate le temps restant estime
  String _formatTimeRemaining(Duration duration) {
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      return 'Environ $minutes min restante${minutes > 1 ? 's' : ''}';
    }
    final seconds = duration.inSeconds;
    return 'Environ $seconds seconde${seconds > 1 ? 's' : ''} restante${seconds > 1 ? 's' : ''}';
  }
}

/// Donnees d'une etape pour l'affichage des indicateurs
class _StepInfo {
  final GenerationStep step;
  final String label;
  final IconData icon;

  const _StepInfo(this.step, this.label, this.icon);
}
