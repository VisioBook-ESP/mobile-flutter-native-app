import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/widgets.dart';
import 'package:visiobook_mobile/features/payment/domain/quota.dart';
import 'package:visiobook_mobile/features/payment/domain/subscription.dart';
import 'package:visiobook_mobile/features/payment/domain/subscription_plan.dart';
import 'package:visiobook_mobile/features/payment/presentation/providers/payment_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadAll();
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier',
      'f\u00e9vrier',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'ao\u00fbt',
      'septembre',
      'octobre',
      'novembre',
      'd\u00e9cembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'canceled':
        return 'Annul\u00e9';
      case 'trialing':
        return 'Essai';
      case 'past_due':
        return 'En retard';
      case 'inactive':
        return 'Inactif';
      default:
        return status;
    }
  }

  Color _planBadgeColor(String planId) {
    switch (planId) {
      case 'pro':
        return AppColors.info;
      case 'enterprise':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.neutral400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();

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
          'Mon abonnement',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: paymentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, paymentProvider),
    );
  }

  Widget _buildContent(BuildContext context, PaymentProvider provider) {
    final plan = provider.currentPlan;
    final subscription = provider.subscription;
    final quota = provider.quota ?? Quota.defaultFree();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentPlanSection(context, provider, plan, subscription),
          const SizedBox(height: 24),
          _buildUsageSection(context, provider, quota),
          if (!provider.isFree) ...[
            const SizedBox(height: 24),
            _buildBillingSection(context, provider),
          ],
          if (provider.isFree) ...[
            const SizedBox(height: 24),
            _buildUpgradeCta(context),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // -- Section 1: Plan actuel -----------------------------------------------

  Widget _buildCurrentPlanSection(
    BuildContext context,
    PaymentProvider provider,
    SubscriptionPlan? plan,
    Subscription? subscription,
  ) {
    final planName = plan?.name ?? 'Free';
    final planId = provider.currentPlanId;
    final badgeColor = _planBadgeColor(planId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.crown,
              size: 20,
              color: AppColors.neutral900,
            ),
            const SizedBox(width: 8),
            Text(
              'Plan actuel',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        planName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildStatusChip(subscription),
                  ],
                ),
                if (subscription != null && !provider.isFree) ...[
                  const SizedBox(height: 12),
                  if (subscription.cancelAtPeriodEnd &&
                      subscription.cancelAt != null)
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Annulation effective le '
                            '${_formatDate(subscription.cancelAt!)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.warning),
                          ),
                        ),
                      ],
                    )
                  else if (subscription.currentPeriodEnd != null)
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: AppColors.neutral500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Renouvellement le '
                            '${_formatDate(subscription.currentPeriodEnd!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: AppButton(
                    text: 'Changer de plan',
                    variant: AppButtonVariant.outline,
                    onPressed: () => context.push(AppRoutes.plans),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(Subscription? subscription) {
    final status = subscription?.status ?? 'active';
    final label = _statusLabel(status);

    Color chipColor;
    switch (status) {
      case 'active':
      case 'trialing':
        chipColor = AppColors.success;
      case 'canceled':
        chipColor = AppColors.error;
      case 'past_due':
        chipColor = AppColors.warning;
      default:
        chipColor = AppColors.neutral400;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }

  // -- Section 2: Utilisation -----------------------------------------------

  Widget _buildUsageSection(
    BuildContext context,
    PaymentProvider provider,
    Quota quota,
  ) {
    final isEnterprise = provider.currentPlanId == 'enterprise';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.barChart3,
              size: 20,
              color: AppColors.neutral900,
            ),
            const SizedBox(width: 8),
            Text(
              'Utilisation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuotaItem(
                  context,
                  title: 'G\u00e9n\u00e9rations',
                  icon: LucideIcons.sparkles,
                  used: quota.videosUsed,
                  limit: isEnterprise ? -1 : quota.videosLimit,
                  progress: isEnterprise ? 0.0 : quota.videosUsagePercent,
                ),
                const SizedBox(height: 20),
                _buildQuotaItem(
                  context,
                  title: 'Projets',
                  icon: LucideIcons.folderOpen,
                  used: quota.projectsUsed,
                  limit: isEnterprise ? -1 : quota.projectsLimit,
                  progress: isEnterprise ? 0.0 : quota.projectsUsagePercent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuotaItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int used,
    required int limit,
    required double progress,
  }) {
    final bool isUnlimited = limit < 0;
    final String usageText = isUnlimited
        ? '$used utilis\u00e9es (illimit\u00e9)'
        : '$used / $limit utilis\u00e9es';

    final Color barColor;
    if (isUnlimited) {
      barColor = AppColors.neutral300;
    } else if (progress >= 0.9) {
      barColor = AppColors.error;
    } else if (progress >= 0.7) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.neutral900;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.neutral600),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isUnlimited ? 0.0 : progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.neutral200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          usageText,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
        ),
      ],
    );
  }

  // -- Section 3: Facturation -----------------------------------------------

  Widget _buildBillingSection(BuildContext context, PaymentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.receipt,
              size: 20,
              color: AppColors.neutral900,
            ),
            const SizedBox(width: 8),
            Text(
              'Facturation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'G\u00e9rer la facturation',
                    variant: AppButtonVariant.outline,
                    fullWidth: true,
                    icon: const Icon(LucideIcons.externalLink, size: 18),
                    isLoading: provider.isProcessing,
                    onPressed: () => _openBillingPortal(context, provider),
                  ),
                ),
                if (!(provider.subscription?.cancelAtPeriodEnd ?? false)) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => _showCancelDialog(context, provider),
                      child: const Text(
                        'Annuler l\'abonnement',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openBillingPortal(
    BuildContext context,
    PaymentProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = await provider.getPortalUrl();
    if (!mounted) return;

    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le portail de facturation'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCancelDialog(BuildContext context, PaymentProvider provider) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          title: Row(
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: AppColors.error,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Annuler l\'abonnement',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre abonnement restera actif jusqu\'\u00e0 la fin '
                'de la p\u00e9riode en cours. Pourriez-vous nous dire '
                'pourquoi vous souhaitez annuler\u00a0?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Raison (optionnel)',
                  hintStyle: const TextStyle(color: AppColors.neutral400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Garder mon abonnement',
                style: TextStyle(color: AppColors.neutral500),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final reason = reasonController.text.trim();
                final success = await provider.cancelSubscription(
                  reason: reason.isNotEmpty ? reason : null,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Abonnement annul\u00e9'
                            : provider.error ?? 'Erreur lors de l\'annulation',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text(
                'Confirmer l\'annulation',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // -- CTA Upgrade ----------------------------------------------------------

  Widget _buildUpgradeCta(BuildContext context) {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(LucideIcons.rocket, size: 40, color: AppColors.info),
            const SizedBox(height: 12),
            Text(
              'Passez \u00e0 Premium',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'D\u00e9bloquez plus de projets, de g\u00e9n\u00e9rations '
              'et des vid\u00e9os plus longues pour donner vie \u00e0 '
              'vos contenus.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Voir les plans',
              onPressed: () => context.push(AppRoutes.plans),
            ),
          ],
        ),
      ),
    );
  }

  // -- Card helper ----------------------------------------------------------

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: child,
    );
  }
}
