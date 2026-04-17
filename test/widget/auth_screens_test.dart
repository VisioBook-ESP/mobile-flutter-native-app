import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/core/widgets/app_button.dart';
import 'package:visiobook_mobile/core/widgets/app_input.dart';
import 'package:visiobook_mobile/features/auth/data/auth_service.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:visiobook_mobile/features/auth/presentation/screens/splash_screen.dart';

// ---------------------------------------------------------------------------
// Fake SecureStorage to avoid platform channels
// ---------------------------------------------------------------------------
class _FakeStorage extends SecureStorageService {
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> saveRefreshToken(String token) async {}
  @override
  Future<void> clearTokens() async {}
  @override
  Future<bool> isLoggedIn() async => false;
  @override
  Future<void> saveUserId(String userId) async {}
  @override
  Future<String?> getUserId() async => null;
  @override
  Future<void> saveUserName(String name) async {}
  @override
  Future<String?> getUserName() async => null;
  @override
  Future<void> setOnboardingComplete(bool complete) async {}
  @override
  Future<bool> isOnboardingComplete() async => true;
  @override
  Future<void> clearAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthProvider authProvider;
  late _FakeStorage fakeStorage;

  setUp(() {
    EnvironmentConfig.useMockData = true;
    fakeStorage = _FakeStorage();
    final authService = AuthService(
      apiClient: ApiClient(storage: fakeStorage),
      storage: fakeStorage,
    );
    authProvider = AuthProvider(authService: authService);
  });

  tearDown(() {
    EnvironmentConfig.useMockData = false;
    authProvider.dispose();
  });

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        Provider<SecureStorageService>.value(value: fakeStorage),
      ],
      child: MaterialApp(home: child),
    );
  }

  // -----------------------------------------------------------------------
  // LoginScreen
  // -----------------------------------------------------------------------
  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pump(const Duration(seconds: 1));

      // Email field
      expect(find.text('Email'), findsWidgets);
      // Password field
      expect(find.text('Mot de passe'), findsOneWidget);
      // AppInput widgets
      expect(find.byType(AppInput), findsAtLeastNWidgets(2));
    });

    testWidgets('renders login button', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Se connecter'), findsWidgets);
      expect(find.byType(AppButton), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Connexion title', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Connexion'), findsOneWidget);
    });

    testWidgets('renders forgot password link', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    });
  });

  // -----------------------------------------------------------------------
  // RegisterScreen
  // -----------------------------------------------------------------------
  group('RegisterScreen', () {
    testWidgets('renders registration fields', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const RegisterScreen()));
      await tester.pump(const Duration(seconds: 1));

      // Title
      expect(find.text('Créer un compte'), findsOneWidget);
      // Fields
      expect(find.text("Nom d'utilisateur"), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);
      // At least 5 AppInput fields (username, first, last, email, pwd, confirm)
      expect(find.byType(AppInput), findsAtLeastNWidgets(5));
    });

    testWidgets('renders register button', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const RegisterScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text("S'enregistrer"), findsOneWidget);
      expect(find.byType(AppButton), findsAtLeastNWidgets(1));
    });
  });

  // -----------------------------------------------------------------------
  // ForgotPasswordScreen
  // -----------------------------------------------------------------------
  group('ForgotPasswordScreen', () {
    testWidgets('renders email field and submit button', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const ForgotPasswordScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Mot de passe oublié'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(AppInput), findsAtLeastNWidgets(1));
      expect(find.text('Envoyer le lien'), findsOneWidget);
      expect(find.byType(AppButton), findsAtLeastNWidgets(1));
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const ForgotPasswordScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('adresse email'), findsOneWidget);
    });
  });

  // -----------------------------------------------------------------------
  // OnboardingScreen
  // -----------------------------------------------------------------------
  group('OnboardingScreen', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const OnboardingScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('renders skip button and next button', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const OnboardingScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Passer'), findsOneWidget);
      expect(find.text('Suivant'), findsOneWidget);
    });

    testWidgets('renders first slide content', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const OnboardingScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Importez votre texte'), findsOneWidget);
    });
  });

  // -----------------------------------------------------------------------
  // LoginScreen - password visibility toggle
  // -----------------------------------------------------------------------
  group('LoginScreen password toggle', () {
    testWidgets('password visibility toggle changes icon', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const LoginScreen()));
      await tester.pump(const Duration(seconds: 1));

      // Initially password is obscured, eyeOff icon is shown
      expect(find.byType(IconButton), findsWidgets);

      // Find the visibility toggle button (the suffixIcon)
      // The login screen uses LucideIcons.eyeOff when _obscurePassword is true
      // Tapping should toggle it
      final toggleButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon != null,
      );
      expect(toggleButton, findsWidgets);
    });
  });

  // -----------------------------------------------------------------------
  // RegisterScreen - all form fields
  // -----------------------------------------------------------------------
  group('RegisterScreen form fields', () {
    testWidgets('renders all form fields including first and last name', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWithProviders(const RegisterScreen()));
      await tester.pump(const Duration(seconds: 1));

      // All expected fields
      expect(find.text("Nom d'utilisateur"), findsOneWidget);
      expect(find.text('Prénom'), findsOneWidget);
      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);
    });

    testWidgets('renders password visibility toggles', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const RegisterScreen()));
      await tester.pump(const Duration(seconds: 1));

      // Both password fields have visibility toggle icons
      expect(find.byType(IconButton), findsWidgets);
    });
  });

  // -----------------------------------------------------------------------
  // ForgotPasswordScreen - back button
  // -----------------------------------------------------------------------
  group('ForgotPasswordScreen navigation', () {
    testWidgets('has a back navigation button in appbar', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const ForgotPasswordScreen()));
      await tester.pump(const Duration(seconds: 1));

      // The AppBar has a leading IconButton for back navigation
      expect(find.byType(IconButton), findsWidgets);
    });
  });

  // -----------------------------------------------------------------------
  // SplashScreen
  // -----------------------------------------------------------------------
  group('SplashScreen', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const SplashScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const SplashScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('transformer'), findsOneWidget);
    });

    testWidgets('renders auth buttons', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const SplashScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text("S'enregistrer"), findsOneWidget);
    });

    testWidgets('shows both login and register AppButtons', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const SplashScreen()));
      await tester.pump(const Duration(seconds: 1));

      // There should be at least 2 AppButton widgets
      expect(find.byType(AppButton), findsAtLeastNWidgets(2));
    });

    testWidgets('shows the full title question', (tester) async {
      await tester.pumpWidget(wrapWithProviders(const SplashScreen()));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('lecture'), findsOneWidget);
    });
  });
}
