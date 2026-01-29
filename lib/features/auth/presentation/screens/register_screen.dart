import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/utils/validators.dart';
import 'package:visiobook_mobile/core/widgets/widgets.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      firstName: _firstNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
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
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      'Creer un compte',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 48),
                    if (authProvider.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.alertCircle,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authProvider.error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    AppInput(
                      label: 'Prenom',
                      placeholder: 'Votre prenom',
                      controller: _firstNameController,
                      keyboardType: TextInputType.name,
                      validator: Validators.firstName,
                      enabled: !authProvider.isLoading,
                    ),
                    const SizedBox(height: 20),
                    AppInput(
                      label: 'Email',
                      placeholder: 'votre@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      enabled: !authProvider.isLoading,
                    ),
                    const SizedBox(height: 20),
                    AppInput(
                      label: 'Mot de passe',
                      placeholder: 'Minimum 8 caracteres',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                      enabled: !authProvider.isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          color: AppColors.neutral500,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppInput(
                      label: 'Confirmer le mot de passe',
                      placeholder: 'Retapez votre mot de passe',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      enabled: !authProvider.isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? LucideIcons.eyeOff
                              : LucideIcons.eye,
                          color: AppColors.neutral500,
                        ),
                        onPressed: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      text: "S'enregistrer",
                      fullWidth: true,
                      size: AppButtonSize.lg,
                      isLoading: authProvider.isLoading,
                      onPressed: authProvider.isLoading
                          ? null
                          : _handleRegister,
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
