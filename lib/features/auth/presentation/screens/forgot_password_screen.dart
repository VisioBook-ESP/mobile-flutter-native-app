import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/utils/validators.dart';
import 'package:visiobook_mobile/core/widgets/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _submitted ? _buildSuccessState() : _buildFormState(),
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
            'Mot de passe oublie',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Entrez votre adresse email et nous vous enverrons un lien pour reinitialiser votre mot de passe.',
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
            onPressed: _handleSubmit,
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
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            LucideIcons.mailCheck,
            size: 36,
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: 32),
        Text('Email envoye', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 16),
        Text(
          'Si un compte existe avec l\'adresse ${_emailController.text.trim()}, vous recevrez un email avec les instructions pour reinitialiser votre mot de passe.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.neutral500),
        ),
        const SizedBox(height: 48),
        AppButton(
          text: 'Retour a la connexion',
          fullWidth: true,
          size: AppButtonSize.lg,
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
