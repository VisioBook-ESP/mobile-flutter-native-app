import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/features/auth/data/auth_service.dart';

/// Etats possibles de l'authentification
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Provider pour gerer l'etat d'authentification
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthState _state = AuthState.initial;
  String? _error;
  String? _userName;

  AuthProvider({required AuthService authService}) : _authService = authService;

  AuthState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated;
  String? get userName => _userName;

  /// Verifie l'etat de connexion au demarrage
  Future<void> checkAuthStatus() async {
    // Mode mock: auto-login
    if (EnvironmentConfig.useMockData) {
      _state = AuthState.authenticated;
      _userName = 'Marine';
      notifyListeners();
      return;
    }

    _state = AuthState.loading;
    notifyListeners();

    final isLoggedIn = await _authService.isLoggedIn();

    _state = isLoggedIn ? AuthState.authenticated : AuthState.unauthenticated;
    notifyListeners();
  }

  /// Connexion
  Future<bool> login({required String email, required String password}) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password);

    if (result.success) {
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } else {
      _state = AuthState.error;
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Inscription
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    final result = await _authService.register(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    if (result.success) {
      _state = AuthState.authenticated;
      _userName = username;
      notifyListeners();
      return true;
    } else {
      _state = AuthState.error;
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Deconnexion
  Future<void> logout() async {
    await _authService.logout();
    _state = AuthState.unauthenticated;
    _userName = null;
    _error = null;
    notifyListeners();
  }

  /// Reset l'erreur
  void clearError() {
    _error = null;
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }
}
