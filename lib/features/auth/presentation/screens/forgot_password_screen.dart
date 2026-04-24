import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/utils/validators.dart';
import 'package:visiobook_mobile/core/widgets/widgets.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final provider = context.read<AuthProvider>();
    final success = await provider.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) _submitted = true;
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
            child: _submitted ? _buildSuccessState() : _buildFormState(),
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
            'Mot de passe oublié',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: 48),
          AppInput(
            label: 'Email',
            placeholder: 'votre@email.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Envoyer le lien',
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            LucideIcons.mailCheck,
            size: 36,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 32),
        Text('Email envoyé', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 16),
        Text(
          'Si un compte existe avec l\'adresse ${_emailController.text.trim()}, vous recevrez un email avec les instructions pour réinitialiser votre mot de passe.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: 48),
        AppButton(
          text: 'Retour à la connexion',
          fullWidth: true,
          size: AppButtonSize.lg,
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'J\'ai reçu le code',
          variant: AppButtonVariant.outline,
          fullWidth: true,
          onPressed: () => context.push(AppRoutes.resetPassword),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
