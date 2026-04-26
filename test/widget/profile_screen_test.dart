import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/auth/data/auth_service.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:visiobook_mobile/features/payment/data/payment_service.dart';
import 'package:visiobook_mobile/features/payment/presentation/providers/payment_provider.dart';
import 'package:visiobook_mobile/features/profile/data/profile_service.dart';
import 'package:visiobook_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:visiobook_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:visiobook_mobile/core/services/settings_provider.dart';

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

  Widget buildSubject() {
    final storage = _FakeStorage();
    final apiClient = ApiClient(storage: storage);
    final profileService = ProfileService(apiClient: apiClient);
    final paymentService = PaymentService(apiClient: apiClient);
    final authService = AuthService(apiClient: apiClient, storage: storage);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(profileService: profileService),
        ),
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => PaymentProvider(paymentService: paymentService),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  testWidgets('ProfileScreen renders without error', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // Screen renders with the title
    expect(find.text('Mon Profil'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows profile content after loading', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    // Let the post-frame callbacks fire and mock data load
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The screen title
    expect(find.text('Mon Profil'), findsOneWidget);

    // Section titles from the profile screen
    expect(find.text('Informations personnelles'), findsOneWidget);

    // Mock profile data: Demo User
    expect(find.text('Demo User'), findsOneWidget);
    expect(find.text('demo@visiobook.com'), findsWidgets);
  });

  testWidgets('ProfileScreen shows section titles', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify key section headings are present
    expect(find.text('Mon forfait'), findsOneWidget);
    expect(find.text('Informations personnelles'), findsOneWidget);
    // Section Paiement supprimée
    expect(find.text('Compte'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows user fields after loading', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Profile field labels
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);

    // Mock profile values
    expect(find.text('User'), findsOneWidget); // lastName
    expect(find.text('Demo'), findsWidgets); // firstName appears in header too
  });

  testWidgets('ProfileScreen shows password change section', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Security section heading
    expect(find.textContaining('curit'), findsOneWidget);
    // Password change row
    expect(find.text('Modifier le mot de passe'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows delete account section', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Account section heading
    expect(find.text('Compte'), findsOneWidget);
    // Delete account button
    expect(find.text('Supprimer mon compte'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows credit/quota display', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Quota section heading
    expect(find.text('Mon forfait'), findsOneWidget);
    // Usage labels from quota section
    expect(find.textContaining('rations'), findsOneWidget);
    expect(find.text('Stockage'), findsOneWidget);
    // Change plan button
    expect(find.text('Changer de plan'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows logout button', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Logout button
    expect(find.textContaining('connecter'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows editable name and email fields', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Personal info section should have editable rows
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text("Nom d'utilisateur"), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows subscription info in Mon forfait section', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Mon forfait section
    expect(find.text('Mon forfait'), findsOneWidget);
    // Should show manage subscription button (appears in both quota and payment sections)
    expect(find.text('Changer de plan'), findsOneWidget);
    // Should show change plan button
    expect(find.text('Changer de plan'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows about section', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // About section
    expect(find.textContaining('propos'), findsOneWidget);
    // App version
    expect(find.text('1.0.0'), findsOneWidget);
  });
}
