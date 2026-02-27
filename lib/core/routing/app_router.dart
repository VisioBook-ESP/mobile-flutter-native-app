import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:visiobook_mobile/features/import/presentation/screens/file_import_screen.dart';
import 'package:visiobook_mobile/features/import/presentation/screens/input_mode_screen.dart';
import 'package:visiobook_mobile/features/import/presentation/screens/scanner_screen.dart';
import 'package:visiobook_mobile/features/import/presentation/screens/text_preview_screen.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/screens/project_detail_screen.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/screens/project_view_screen.dart';
import 'package:visiobook_mobile/features/generation/presentation/screens/generation_screen.dart';
import 'package:visiobook_mobile/features/player/presentation/screens/visiobook_reader_screen.dart';
import 'package:visiobook_mobile/features/projects/presentation/screens/dashboard_screen.dart';

/// Routes de l'application
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String projectView = '/project/:id';
  static const String projectConfig = '/project/config';
  static const String projectEditConfig = '/project/:id/config';
  static const String generation = '/project/:id/generate/:workflowId';
  static const String player = '/player/:id';
  // Import routes
  static const String inputMode = '/import';
  static const String fileImport = '/import/file';
  static const String scan = '/import/scan';
  static const String textPreview = '/import/preview';
}

/// Configuration du router
class AppRouter {
  final SecureStorageService _storage;

  AppRouter({required SecureStorageService storage}) : _storage = storage;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: _handleRedirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.projectView,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProjectViewScreen(projectId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.projectConfig,
        builder: (context, state) => const ProjectDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.projectEditConfig,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProjectDetailScreen(projectId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.generation,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final workflowId = state.pathParameters['workflowId']!;
          return GenerationScreen(projectId: id, workflowId: workflowId);
        },
      ),
      GoRoute(
        path: AppRoutes.player,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VisioBookReaderScreen(projectId: id);
        },
      ),
      // Import routes
      GoRoute(
        path: AppRoutes.inputMode,
        builder: (context, state) => const InputModeScreen(),
      ),
      GoRoute(
        path: AppRoutes.fileImport,
        builder: (context, state) => const FileImportScreen(),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.textPreview,
        builder: (context, state) => const TextPreviewScreen(),
      ),
    ],
  );

  Future<String?> _handleRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    // Mode mock: pas de redirection automatique, laisser le splash gerer
    if (EnvironmentConfig.useMockData) {
      return null;
    }

    final isLoggedIn = await _storage.isLoggedIn();
    final isOnSplash = state.matchedLocation == AppRoutes.splash;
    final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;
    final isOnAuth =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.forgotPassword ||
        state.matchedLocation == AppRoutes.register;

    // Si on est sur splash ou onboarding, laisser l'ecran gerer la redirection
    if (isOnSplash || isOnOnboarding) return null;

    // Si pas connecte et pas sur une page auth, rediriger vers login
    if (!isLoggedIn && !isOnAuth) {
      return AppRoutes.login;
    }

    // Si connecte et sur une page auth, rediriger vers dashboard
    if (isLoggedIn && isOnAuth) {
      return AppRoutes.dashboard;
    }

    return null;
  }
}
