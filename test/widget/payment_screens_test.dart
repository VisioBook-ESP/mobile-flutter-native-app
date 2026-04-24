import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/payment/data/payment_service.dart';
import 'package:visiobook_mobile/features/payment/presentation/providers/payment_provider.dart';
import 'package:visiobook_mobile/features/payment/presentation/screens/plans_screen.dart';
import 'package:visiobook_mobile/features/payment/presentation/screens/subscription_screen.dart';

class _FakeStorage implements SecureStorageService {
  @override
  Future<String?> getAccessToken() async => 'fake-token';
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveAccessToken(String t) async {}
  @override
  Future<void> saveRefreshToken(String t) async {}
  @override
  Future<void> clearTokens() async {}
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<void> saveUserId(String userId) async {}
  @override
  Future<String?> getUserId() async => 'fake-id';
  @override
  Future<void> saveUserName(String name) async {}
  @override
  Future<String?> getUserName() async => 'Demo';
  @override
  Future<void> setOnboardingComplete(bool complete) async {}
  @override
  Future<bool> isOnboardingComplete() async => true;
  @override
  Future<void> clearAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => EnvironmentConfig.useMockData = true);
  tearDown(() => EnvironmentConfig.useMockData = false);

  PaymentProvider createPaymentProvider() {
    final storage = _FakeStorage();
    final apiClient = ApiClient(storage: storage);
    final paymentService = PaymentService(apiClient: apiClient);
    return PaymentProvider(paymentService: paymentService);
  }

  Widget wrapWithRouter(Widget screen) {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(path: '/test', builder: (context, state) => screen),
        // Dummy routes for navigation targets
        GoRoute(
          path: '/plans',
          builder: (context, state) => const Scaffold(body: Text('Plans')),
        ),
        GoRoute(
          path: '/subscription',
          builder: (context, state) =>
              const Scaffold(body: Text('Subscription')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('SubscriptionScreen', () {
    testWidgets('renders without error and shows content', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => createPaymentProvider(),
          child: wrapWithRouter(const SubscriptionScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // AppBar title
      expect(find.text('Mon abonnement'), findsOneWidget);
      // Section headings
      expect(find.text('Plan actuel'), findsOneWidget);
      expect(find.text('Utilisation'), findsOneWidget);
    });

    testWidgets('shows upgrade CTA for free plan', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => createPaymentProvider(),
          child: wrapWithRouter(const SubscriptionScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Free plan shows upgrade CTA
      expect(find.textContaining('Premium'), findsOneWidget);
    });
  });

  group('PlansScreen', () {
    testWidgets('renders without error and shows plan cards', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => createPaymentProvider(),
          child: wrapWithRouter(const PlansScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // AppBar title
      expect(find.text('Choisir un plan'), findsOneWidget);

      // Toggle labels
      expect(find.text('Mensuel'), findsOneWidget);
      expect(find.text('Annuel'), findsOneWidget);

      // Plan names from SubscriptionPlan.defaults
      expect(find.text('Free'), findsWidgets);
      expect(find.text('Premium'), findsWidgets);
      expect(find.text('Enterprise'), findsWidgets);
    });

    testWidgets('shows plan features list', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => createPaymentProvider(),
          child: wrapWithRouter(const PlansScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Features from SubscriptionPlan.defaults
      expect(find.textContaining('rations/mois'), findsWidgets);
      expect(find.textContaining('Go de stockage'), findsWidgets);
      expect(find.textContaining('illimit'), findsWidgets);
      expect(find.text('Support d\u00e9di\u00e9'), findsOneWidget);
    });
  });

  group('SubscriptionScreen usage', () {
    testWidgets('shows usage bars and quota labels', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => createPaymentProvider(),
          child: wrapWithRouter(const SubscriptionScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Utilisation section heading
      expect(find.text('Utilisation'), findsOneWidget);
      // Quota item titles
      expect(find.textContaining('rations'), findsWidgets);
      expect(find.text('Stockage'), findsOneWidget);
      // Progress bars exist
      expect(find.byType(LinearProgressIndicator), findsWidgets);
      // Usage text (e.g. "X / Y utilisees")
      expect(find.textContaining('utilis'), findsWidgets);
    });
  });

  group('PlansScreen interval toggle', () {
    testWidgets('tapping Annuel toggles interval', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => createPaymentProvider(),
          child: wrapWithRouter(const PlansScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify both toggle labels exist
      expect(find.text('Mensuel'), findsOneWidget);
      expect(find.text('Annuel'), findsOneWidget);

      // Tap on Annuel
      await tester.tap(find.text('Annuel'));
      await tester.pump();

      // All 3 plan names should still be visible after toggle
      expect(find.text('Free'), findsWidgets);
      expect(find.text('Premium'), findsWidgets);
      expect(find.text('Enterprise'), findsWidgets);
    });

    testWidgets('all 3 plan names are visible', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => createPaymentProvider(),
          child: wrapWithRouter(const PlansScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Free'), findsWidgets);
      expect(find.text('Premium'), findsWidgets);
      expect(find.text('Enterprise'), findsWidgets);
    });
  });

  group('SubscriptionScreen cancel', () {
    testWidgets('shows Changer de plan button', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => createPaymentProvider(),
          child: wrapWithRouter(const SubscriptionScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Changer de plan'), findsOneWidget);
    });
  });
}
