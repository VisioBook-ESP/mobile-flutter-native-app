import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/utils/validators.dart';
import 'package:visiobook_mobile/core/widgets/widgets.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:visiobook_mobile/features/payment/presentation/providers/payment_provider.dart';
import 'package:visiobook_mobile/features/profile/domain/user_profile.dart';
import 'package:visiobook_mobile/features/profile/presentation/providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _editingField;
  final _editController = TextEditingController();
  final _editFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
      context.read<PaymentProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  String _getInitials(UserProfile profile) {
    final first = profile.firstName;
    final last = profile.lastName;
    if (first != null && first.isNotEmpty && last != null && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    return profile.username[0].toUpperCase();
  }

  String _getDisplayName(UserProfile profile) {
    final first = profile.firstName;
    final last = profile.lastName;
    if (first != null && first.isNotEmpty && last != null && last.isNotEmpty) {
      return '$first $last';
    }
    if (first != null && first.isNotEmpty) return first;
    return profile.username;
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

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final profile = profileProvider.profile;

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
          'Mon Profil',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: profileProvider.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : profile == null
          ? _buildErrorState(profileProvider)
          : _buildContent(context, profile, profileProvider, paymentProvider),
    );
  }

  Widget _buildErrorState(ProfileProvider provider) {
    final isSessionExpired =
        provider.error?.contains('Session expir\u00e9e') ?? false;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'Impossible de charger le profil',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.neutral500),
            ),
            const SizedBox(height: 24),
            if (isSessionExpired)
              AppButton(
                text: 'Se reconnecter',
                fullWidth: true,
                onPressed: () async {
                  final router = GoRouter.of(context);
                  await context.read<AuthProvider>().logout();
                  router.go('/');
                },
              )
            else
              AppButton(
                text: 'R\u00e9essayer',
                onPressed: () => provider.loadProfile(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserProfile profile,
    ProfileProvider provider,
    PaymentProvider paymentProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(context, profile),
          const SizedBox(height: 24),
          _buildQuotaSection(context, paymentProvider),
          const SizedBox(height: 24),
          _buildPersonalInfoSection(context, profile, provider),
          const SizedBox(height: 24),
          _buildSecuritySection(context, provider),
          const SizedBox(height: 24),
          _buildPaymentSection(context, paymentProvider),
          const SizedBox(height: 24),
          _buildAboutSection(context),
          const SizedBox(height: 24),
          _buildAccountSection(context, provider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // -- Header ----------------------------------------------------------------

  Widget _buildHeaderSection(BuildContext context, UserProfile profile) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.neutral900,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(profile),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getDisplayName(profile),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: 4),
          Text(
            profile.createdAt != null
                ? 'Membre depuis le ${_formatDate(profile.createdAt!)}'
                : '@${profile.username}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // -- Quota ----------------------------------------------------------------

  Widget _buildQuotaSection(
    BuildContext context,
    PaymentProvider paymentProvider,
  ) {
    final quota = paymentProvider.quota;
    final currentPlan = paymentProvider.currentPlan;
    final planName = currentPlan?.name ?? 'Free';

    final projectsProgress = quota?.projectsUsagePercent.clamp(0.0, 1.0) ?? 0.0;
    final videosProgress = quota?.videosUsagePercent.clamp(0.0, 1.0) ?? 0.0;

    final projectsUsed = quota?.projectsUsed ?? 0;
    final projectsLimit = quota?.projectsLimit ?? 0;
    final videosUsed = quota?.videosUsed ?? 0;
    final videosLimit = quota?.videosLimit ?? 0;

    String limitLabel(int limit) => limit < 0 ? '\u221e' : '$limit';

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                  'Mon forfait',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neutral900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    planName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Generations (videos) usage
            Text(
              'G\u00e9n\u00e9rations',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral600),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: videosProgress,
                minHeight: 8,
                backgroundColor: AppColors.neutral200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.neutral900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$videosUsed / ${limitLabel(videosLimit)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            // Projects (storage) usage
            Text(
              'Projets',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral600),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: projectsProgress,
                minHeight: 8,
                backgroundColor: AppColors.neutral200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.neutral900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$projectsUsed / ${limitLabel(projectsLimit)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Changer de plan',
              fullWidth: true,
              onPressed: () => context.push(AppRoutes.plans),
            ),
            const SizedBox(height: 8),
            AppButton(
              text: 'G\u00e9rer mon abonnement',
              variant: AppButtonVariant.outline,
              fullWidth: true,
              onPressed: () => context.push(AppRoutes.subscription),
            ),
          ],
        ),
      ),
    );
  }

  // -- Personal Info ---------------------------------------------------------

  void _startEditing(String fieldKey, String currentValue) {
    setState(() {
      _editingField = fieldKey;
      _editController.text = currentValue;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingField = null;
    });
  }

  Future<void> _saveField(
    String fieldKey,
    String? Function(String?) validator,
    Future<bool> Function(String value) onSave,
  ) async {
    if (!(_editFormKey.currentState?.validate() ?? false)) return;
    final value = _editController.text.trim();
    final success = await onSave(value);
    if (mounted) {
      setState(() {
        _editingField = null;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis \u00e0 jour'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildPersonalInfoSection(
    BuildContext context,
    UserProfile profile,
    ProfileProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.user, size: 20, color: AppColors.neutral900),
            const SizedBox(width: 8),
            Text(
              'Informations personnelles',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCard(
          child: Column(
            children: [
              _buildEditableRow(
                context,
                fieldKey: 'lastName',
                label: 'Nom',
                value: profile.lastName ?? 'Non renseign\u00e9',
                currentValue: profile.lastName ?? '',
                validator: Validators.lastName,
                onSave: (value) => provider.updateProfile(lastName: value),
              ),
              const Divider(height: 1, color: AppColors.neutral200),
              _buildEditableRow(
                context,
                fieldKey: 'firstName',
                label: 'Pr\u00e9nom',
                value: profile.firstName ?? 'Non renseign\u00e9',
                currentValue: profile.firstName ?? '',
                validator: Validators.firstName,
                onSave: (value) => provider.updateProfile(firstName: value),
              ),
              const Divider(height: 1, color: AppColors.neutral200),
              _buildEditableRow(
                context,
                fieldKey: 'username',
                label: "Nom d'utilisateur",
                value: profile.username,
                currentValue: profile.username,
                validator: Validators.username,
                onSave: (value) => provider.updateProfile(username: value),
              ),
              const Divider(height: 1, color: AppColors.neutral200),
              _buildEditableRow(
                context,
                fieldKey: 'email',
                label: 'Email',
                value: profile.email,
                currentValue: profile.email,
                validator: Validators.email,
                hint:
                    'Un email de v\u00e9rification sera envoy\u00e9 \u00e0 la nouvelle adresse.',
                onSave: (value) => provider.updateProfile(email: value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow(
    BuildContext context, {
    required String fieldKey,
    required String label,
    required String value,
    required String currentValue,
    required String? Function(String?) validator,
    required Future<bool> Function(String value) onSave,
    String? hint,
  }) {
    final isEditing = _editingField == fieldKey;

    if (isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
            ),
            const SizedBox(height: 6),
            Form(
              key: _editFormKey,
              child: TextFormField(
                controller: _editController,
                validator: validator,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.neutral900,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.neutral900.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.neutral900.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppColors.neutral400,
                        ),
                        onPressed: _cancelEditing,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.check,
                          size: 18,
                          color: AppColors.neutral900,
                        ),
                        onPressed: () =>
                            _saveField(fieldKey, validator, onSave),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                onFieldSubmitted: (_) =>
                    _saveField(fieldKey, validator, onSave),
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.neutral500,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _startEditing(fieldKey, currentValue),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral500),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.pencil,
              size: 14,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  // -- Security --------------------------------------------------------------

  Widget _buildSecuritySection(BuildContext context, ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.lock, size: 20, color: AppColors.neutral900),
            const SizedBox(width: 8),
            Text(
              'S\u00e9curit\u00e9',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCard(
          child: InkWell(
            onTap: () => _showChangePasswordDialog(context, provider),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.keyRound,
                    size: 20,
                    color: AppColors.neutral600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Modifier le mot de passe',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppColors.neutral400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -- Payment ---------------------------------------------------------------

  Widget _buildPaymentSection(
    BuildContext context,
    PaymentProvider paymentProvider,
  ) {
    final subscription = paymentProvider.subscription;
    final currentPlan = paymentProvider.currentPlan;
    final planName = currentPlan?.name ?? 'Free';
    final isActive = subscription?.isActive ?? false;
    final isCanceled = subscription?.isCanceled ?? false;

    String statusLabel;
    Color statusColor;
    if (isCanceled) {
      statusLabel = 'Annul\u00e9';
      statusColor = AppColors.error;
    } else if (isActive) {
      statusLabel = 'Actif';
      statusColor = const Color(0xFF16A34A);
    } else {
      statusLabel = 'Gratuit';
      statusColor = AppColors.neutral500;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.creditCard,
              size: 20,
              color: AppColors.neutral900,
            ),
            const SizedBox(width: 8),
            Text('Paiement', style: Theme.of(context).textTheme.headlineSmall),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan $planName',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusLabel,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: statusColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (subscription?.currentPeriodEnd != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    isCanceled
                        ? 'Acc\u00e8s jusqu\'au ${_formatDate(subscription!.currentPeriodEnd!)}'
                        : 'Renouvellement le ${_formatDate(subscription!.currentPeriodEnd!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: AppButton(
                    text: 'G\u00e9rer mon abonnement',
                    variant: AppButtonVariant.outline,
                    fullWidth: true,
                    onPressed: () => context.push(AppRoutes.subscription),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -- About -----------------------------------------------------------------

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.info, size: 20, color: AppColors.neutral900),
            const SizedBox(width: 8),
            Text(
              '\u00c0 propos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCard(
          child: Column(
            children: [
              _buildSimpleRow(
                context,
                icon: LucideIcons.smartphone,
                label: "Version de l'app",
                trailing: Text(
                  '1.0.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Divider(height: 1, color: AppColors.neutral200),
              _buildSimpleRow(
                context,
                icon: LucideIcons.fileText,
                label: 'Mentions l\u00e9gales',
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.neutral400,
                ),
              ),
              const Divider(height: 1, color: AppColors.neutral200),
              _buildSimpleRow(
                context,
                icon: LucideIcons.scrollText,
                label: "Conditions g\u00e9n\u00e9rales d'utilisation",
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.neutral400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.neutral600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          trailing,
        ],
      ),
    );
  }

  // -- Account ---------------------------------------------------------------

  Widget _buildAccountSection(BuildContext context, ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.settings,
              size: 20,
              color: AppColors.neutral900,
            ),
            const SizedBox(width: 8),
            Text('Compte', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Se d\u00e9connecter',
            variant: AppButtonVariant.outline,
            fullWidth: true,
            icon: const Icon(LucideIcons.logOut, size: 18),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                GoRouter.of(context).go('/');
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _showDeleteAccountDialog(context, provider),
            child: const Text(
              'Supprimer mon compte',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -- Card helper -----------------------------------------------------------

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

  // -- Dialogs ---------------------------------------------------------------

  void _showChangePasswordDialog(
    BuildContext context,
    ProfileProvider provider,
  ) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Modifier le mot de passe',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppInput(
                          label: 'Nouveau mot de passe',
                          controller: newPasswordController,
                          obscureText: true,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          label: 'Confirmer le mot de passe',
                          controller: confirmPasswordController,
                          obscureText: true,
                          validator: (value) => Validators.confirmPassword(
                            value,
                            newPasswordController.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Annuler',
                          variant: AppButtonVariant.outline,
                          fullWidth: true,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Modifier',
                          fullWidth: true,
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final success = await provider.changePassword(
                                newPassword: newPasswordController.text,
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Mot de passe modifi\u00e9'
                                          : 'Erreur lors du changement',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    ProfileProvider provider,
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
              const Icon(LucideIcons.trash2, color: AppColors.error, size: 22),
              const SizedBox(width: 8),
              Text(
                'Supprimer le compte',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: AppColors.error),
              ),
            ],
          ),
          content: const Text(
            'Cette action est irr\u00e9versible. Toutes vos donn\u00e9es '
            'seront d\u00e9finitivement supprim\u00e9es.',
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
                final success = await provider.deleteAccount();
                if (success && context.mounted) {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    GoRouter.of(context).go('/');
                  }
                }
              },
              child: const Text(
                'Supprimer',
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
}
