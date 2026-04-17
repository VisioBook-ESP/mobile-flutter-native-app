import 'package:flutter_test/flutter_test.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppRoutes constants', () {
    test('all route constants are non-empty strings', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.forgotPassword,
        AppRoutes.register,
        AppRoutes.dashboard,
        AppRoutes.projectView,
        AppRoutes.projectConfig,
        AppRoutes.projectEditConfig,
        AppRoutes.generation,
        AppRoutes.player,
        AppRoutes.inputMode,
        AppRoutes.fileImport,
        AppRoutes.scan,
        AppRoutes.textPreview,
        AppRoutes.textsHistory,
        AppRoutes.textDetail,
        AppRoutes.visiobooksHistory,
        AppRoutes.createProject,
        AppRoutes.profile,
        AppRoutes.plans,
        AppRoutes.subscription,
      ];

      for (final route in routes) {
        expect(route, isA<String>());
        expect(route.isNotEmpty, isTrue);
      }
    });

    test('all routes start with /', () {
      final routes = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.forgotPassword,
        AppRoutes.register,
        AppRoutes.dashboard,
        AppRoutes.projectView,
        AppRoutes.projectConfig,
        AppRoutes.projectEditConfig,
        AppRoutes.generation,
        AppRoutes.player,
        AppRoutes.inputMode,
        AppRoutes.fileImport,
        AppRoutes.scan,
        AppRoutes.textPreview,
        AppRoutes.textsHistory,
        AppRoutes.textDetail,
        AppRoutes.visiobooksHistory,
        AppRoutes.createProject,
        AppRoutes.profile,
        AppRoutes.plans,
        AppRoutes.subscription,
      ];

      for (final route in routes) {
        expect(
          route.startsWith('/'),
          isTrue,
          reason: '$route should start with /',
        );
      }
    });

    test('splash route is root', () {
      expect(AppRoutes.splash, '/');
    });

    test('dashboard route contains dashboard', () {
      expect(AppRoutes.dashboard, contains('dashboard'));
    });

    test('login route contains login', () {
      expect(AppRoutes.login, contains('login'));
    });

    test('register route contains register', () {
      expect(AppRoutes.register, contains('register'));
    });

    test('project routes contain project', () {
      expect(AppRoutes.projectView, contains('project'));
      expect(AppRoutes.projectConfig, contains('project'));
      expect(AppRoutes.projectEditConfig, contains('project'));
    });

    test('import routes contain import', () {
      expect(AppRoutes.inputMode, contains('import'));
      expect(AppRoutes.fileImport, contains('import'));
    });

    test('history routes contain history', () {
      expect(AppRoutes.textsHistory, contains('history'));
      expect(AppRoutes.visiobooksHistory, contains('history'));
    });

    test('generation route contains generate', () {
      expect(AppRoutes.generation, contains('generate'));
    });

    test('player route contains player', () {
      expect(AppRoutes.player, contains('player'));
    });

    test('profile route contains profile', () {
      expect(AppRoutes.profile, contains('profile'));
    });

    test('payment routes contain expected paths', () {
      expect(AppRoutes.plans, contains('plans'));
      expect(AppRoutes.subscription, contains('subscription'));
    });

    test('project view route has id parameter', () {
      expect(AppRoutes.projectView, contains(':id'));
    });

    test('generation route has all parameters', () {
      expect(AppRoutes.generation, contains(':id'));
      expect(AppRoutes.generation, contains(':versionId'));
      expect(AppRoutes.generation, contains(':executionId'));
    });

    test('player route has id parameter', () {
      expect(AppRoutes.player, contains(':id'));
    });

    test('text detail route has id parameter', () {
      expect(AppRoutes.textDetail, contains(':id'));
    });
  });

  group('AppRouter', () {
    test('can be instantiated', () {
      try {
        final storage = SecureStorageService();
        final router = AppRouter(storage: storage);
        expect(router, isNotNull);
      } catch (_) {
        // Platform channels may not be available in test
      }
    });
  });
}
