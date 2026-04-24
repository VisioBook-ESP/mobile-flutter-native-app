import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/widgets/widgets.dart';
import 'package:visiobook_mobile/features/payment/domain/subscription_plan.dart';
import 'package:visiobook_mobile/features/payment/presentation/providers/payment_provider.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool _isYearly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadAll();
    });
  }

  /// Order of plans for comparison: free < pro < enterprise
  static const _planOrder = ['free', 'premium', 'enterprise'];

  int _planIndex(String planId) {
    final idx = _planOrder.indexOf(planId);
    return idx == -1 ? 0 : idx;
  }

  bool _isCurrentPlan(String planId, String currentPlanId) {
    return planId == currentPlanId;
  }

  bool _isDowngrade(String planId, String currentPlanId) {
    return _planIndex(planId) < _planIndex(currentPlanId);
  }

  String _formatPrice(double price) {
    if (price == 0) return 'Gratuit';
    final formatted = price.toStringAsFixed(2).replaceAll('.', ',');
    return '$formatted\u20AC';
  }

  String _priceLabel(SubscriptionPlan plan) {
    if (plan.monthlyPrice == 0 && plan.yearlyPrice == 0) return 'Gratuit';
    if (_isYearly) {
      return '${_formatPrice(plan.yearlyPrice)}/an';
    }
    return '${_formatPrice(plan.monthlyPrice)}/mois';
  }

  int _savingsPercent(SubscriptionPlan plan) {
    if (plan.monthlyPrice <= 0) return 0;
    final yearlyEquivalent = plan.monthlyPrice * 12;
    if (yearlyEquivalent <= 0) return 0;
    final savings =
        ((yearlyEquivalent - plan.yearlyPrice) / yearlyEquivalent * 100)
            .round();
    return savings > 0 ? savings : 0;
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Choisir un plan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          centerTitle: true,
        ),
        body: paymentProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(context, paymentProvider),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentProvider provider) {
    final plans = provider.plans.isEmpty
        ? SubscriptionPlan.defaults
        : provider.plans;
    final currentPlanId = provider.currentPlanId;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          _buildIntervalToggle(context),
          const SizedBox(height: 20),
          ...plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPlanCard(context, plan, currentPlanId, provider),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // -- Interval toggle -------------------------------------------------------

  Widget _buildIntervalToggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isYearly
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : AppColors.neutral900.withValues(alpha: 0.08))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    'Mensuel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: !_isYearly
                          ? (isDark ? Colors.white : AppColors.neutral900)
                          : AppColors.neutral500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isYearly
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : AppColors.neutral900.withValues(alpha: 0.08))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    'Annuel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isYearly
                          ? (isDark ? Colors.white : AppColors.neutral900)
                          : AppColors.neutral500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Plan card --------------------------------------------------------------

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlan plan,
    String currentPlanId,
    PaymentProvider provider,
  ) {
    final isCurrent = _isCurrentPlan(plan.id, currentPlanId);
    final isDowngrade = _isDowngrade(plan.id, currentPlanId);
    final isRecommended = plan.id == 'premium';
    final savings = _savingsPercent(plan);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isRecommended
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.neutral900.withValues(alpha: 0.06))
            : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.neutral100),
        border: Border.all(
          color: isRecommended
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.neutral900.withValues(alpha: 0.2))
              : (isDark ? AppColors.neutral700 : AppColors.neutral200),
          width: isRecommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with plan name, badge, and price
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _planIcon(plan.id),
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Recommand\u00e9',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.neutral900,
                          ),
                        ),
                      ),
                    if (isCurrent)
                      Container(
                        margin: EdgeInsets.only(left: isRecommended ? 6 : 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : AppColors.neutral900.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: isDark
                              ? null
                              : Border.all(
                                  color: AppColors.neutral900.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                        ),
                        child: Text(
                          'Plan actuel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.neutral900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plan.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _priceLabel(plan),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (_isYearly && savings > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '\u00c9conomisez $savings%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Features list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: plan.features
                  .map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.check,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.neutral300
                                    : AppColors.neutral700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildActionButton(
              context,
              plan: plan,
              isCurrent: isCurrent,
              isDowngrade: isDowngrade,
              isRecommended: isRecommended,
              provider: provider,
            ),
          ),
        ],
      ),
    );
  }

  IconData _planIcon(String planId) {
    switch (planId) {
      case 'free':
        return LucideIcons.user;
      case 'premium':
        return LucideIcons.crown;
      case 'enterprise':
        return LucideIcons.sparkles;
      default:
        return LucideIcons.circle;
    }
  }

  // -- Action button ----------------------------------------------------------

  Widget _buildActionButton(
    BuildContext context, {
    required SubscriptionPlan plan,
    required bool isCurrent,
    required bool isDowngrade,
    required bool isRecommended,
    required PaymentProvider provider,
  }) {
    if (isCurrent) {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          text: 'Plan actuel',
          variant: isRecommended
              ? AppButtonVariant.outline
              : AppButtonVariant.primary,
          fullWidth: true,
          onPressed: null,
        ),
      );
    }

    if (isDowngrade) {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          text: 'Downgrade',
          variant: AppButtonVariant.outline,
          fullWidth: true,
          isLoading: provider.isProcessing,
          onPressed: () => _showDowngradeDialog(context, plan, provider),
        ),
      );
    }

    // Upgrade
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        text: 'S\u00e9lectionner',
        variant: AppButtonVariant.primary,
        fullWidth: true,
        isLoading: provider.isProcessing,
        onPressed: () => _handleUpgrade(context, plan, provider),
      ),
    );
  }

  // -- Actions ----------------------------------------------------------------

  Future<void> _handleUpgrade(
    BuildContext context,
    SubscriptionPlan plan,
    PaymentProvider provider,
  ) async {
    final interval = _isYearly ? 'year' : 'month';

    final result = await provider.createPaymentIntent(
      planId: plan.id,
      interval: interval,
    );

    if (result == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.error ?? 'Erreur lors de la cr\u00e9ation du paiement',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: result['clientSecret']!,
          customerId: result['customerId'],
          customerEphemeralKeySecret: result['ephemeralKey'],
          merchantDisplayName: 'VisioBook',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Attendre que le webhook Stripe traite le paiement
      await Future.delayed(const Duration(seconds: 2));

      // Paiement réussi → recharger les données
      await provider.loadAll();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement activ\u00e9 avec succ\u00e8s !'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } on StripeException catch (e) {
      if (context.mounted) {
        final message = e.error.localizedMessage ?? 'Paiement annul\u00e9';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    } on MissingPluginException {
      // flutter_stripe n'a pas d'implémentation desktop
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Le paiement Stripe n\u2019est disponible que sur mobile '
              '(iOS / Android).',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDowngradeDialog(
    BuildContext context,
    SubscriptionPlan plan,
    PaymentProvider provider,
  ) {
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
                color: AppColors.warning,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Changer de plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          content: Text(
            'Vous \u00eates sur le point de passer au plan ${plan.name}. '
            'Vous pourriez perdre l\u2019acc\u00e8s \u00e0 certaines '
            'fonctionnalit\u00e9s. Continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: AppColors.neutral500),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await provider.downgradePlan(plan.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Plan modifi\u00e9 avec succ\u00e8s'
                            : provider.error ??
                                  'Erreur lors du changement de plan',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text(
                'Confirmer',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
