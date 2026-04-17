import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/utils/validators.dart';
import 'package:visiobook_mobile/core/widgets/widgets.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _success = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final provider = context.read<AuthProvider>();
    final success = await provider.resetPassword(
      resetToken: _tokenController.text.trim(),
      newPassword: _passwordController.text,
      confirmPassword: _confirmController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) _success = true;
    });

    if (!success && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
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
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _success ? _buildSuccessState() : _buildFormState(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            'Nouveau mot de passe',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Entrez le code reçu par email et choisissez un nouveau mot de passe.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: 32),
          AppInput(
            label: 'Code de réinitialisation',
            placeholder: 'Collez le code reçu par email',
            controller: _tokenController,
            validator: Validators.required,
          ),
          const SizedBox(height: 16),
          AppInput(
            label: 'Nouveau mot de passe',
            placeholder: '••••••••',
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: Validators.password,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 16),
          AppInput(
            label: 'Confirmer le mot de passe',
            placeholder: '••••••••',
            controller: _confirmController,
            obscureText: _obscureConfirm,
            validator: (value) =>
                Validators.confirmPassword(value, _passwordController.text),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Réinitialiser',
            fullWidth: true,
            size: AppButtonSize.lg,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleSubmit,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 48),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            LucideIcons.checkCircle,
            size: 36,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Mot de passe modifié',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'Votre mot de passe a été réinitialisé avec succès. Vous pouvez maintenant vous connecter.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: 48),
        AppButton(
          text: 'Se connecter',
          fullWidth: true,
          size: AppButtonSize.lg,
          onPressed: () => context.go(AppRoutes.login),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
