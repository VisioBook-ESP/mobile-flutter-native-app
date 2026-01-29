import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:visiobook_mobile/features/projects/presentation/screens/dashboard_screen.dart';

/// Routes de l'application
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String projectDetail = '/project/:id';
  static const String player = '/player/:id';
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
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
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
        path: AppRoutes.projectDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _PlaceholderScreen(title: 'Project $id');
        },
      ),
      GoRoute(
        path: AppRoutes.player,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _PlaceholderScreen(title: 'Player $id');
        },
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
    final isOnAuth =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register;

    // Si on est sur splash, laisser le splash gerer la redirection
    if (isOnSplash) return null;

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

/// Ecran placeholder temporaire (sera remplace par les vrais ecrans)
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
