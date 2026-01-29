import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Prets a\ntransformer\nla lecture ?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const Spacer(),
              AppButton(
                text: 'Se connecter',
                fullWidth: true,
                size: AppButtonSize.lg,
                onPressed: () => context.push(AppRoutes.login),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: "S'enregistrer",
                variant: AppButtonVariant.outline,
                fullWidth: true,
                size: AppButtonSize.lg,
                onPressed: () => context.push(AppRoutes.register),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
