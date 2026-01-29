import 'package:dio/dio.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';

/// Resultat d'authentification
class AuthResult {
  final bool success;
  final String? error;
  final String? userId;

  AuthResult({required this.success, this.error, this.userId});
}

/// Service d'authentification
class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthService({
    required ApiClient apiClient,
    required SecureStorageService storage,
  }) : _apiClient = apiClient,
       _storage = storage;

  /// Connexion avec email et mot de passe
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.authLogin({
        'email': email,
        'password': password,
      });

      final data = response.data;
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userId = data['userId'] as String?;

      if (accessToken != null && refreshToken != null) {
        await _storage.saveAccessToken(accessToken);
        await _storage.saveRefreshToken(refreshToken);
        if (userId != null) {
          await _storage.saveUserId(userId);
        }
        return AuthResult(success: true, userId: userId);
      }

      return AuthResult(success: false, error: 'Reponse invalide du serveur');
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Inscription
  Future<AuthResult> register({
    required String firstName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.authRegister({
        'firstName': firstName,
        'email': email,
        'password': password,
      });

      final data = response.data;
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userId = data['userId'] as String?;

      if (accessToken != null && refreshToken != null) {
        await _storage.saveAccessToken(accessToken);
        await _storage.saveRefreshToken(refreshToken);
        if (userId != null) {
          await _storage.saveUserId(userId);
        }
        return AuthResult(success: true, userId: userId);
      }

      return AuthResult(success: false, error: 'Reponse invalide du serveur');
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Deconnexion
  Future<void> logout() async {
    await _storage.clearTokens();
  }

  /// Verifie si l'utilisateur est connecte
  Future<bool> isLoggedIn() async {
    return _storage.isLoggedIn();
  }

  /// Gestion des erreurs Dio
  AuthResult _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'Erreur serveur';
      if (data is Map && data['message'] != null) {
        message = data['message'];
      }

      switch (statusCode) {
        case 400:
          return AuthResult(success: false, error: message);
        case 401:
          return AuthResult(
            success: false,
            error: 'Email ou mot de passe incorrect',
          );
        case 409:
          return AuthResult(
            success: false,
            error: 'Cet email est deja utilise',
          );
        case 422:
          return AuthResult(success: false, error: 'Donnees invalides');
        default:
          return AuthResult(
            success: false,
            error: 'Erreur serveur ($statusCode)',
          );
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AuthResult(
        success: false,
        error: 'Connexion au serveur impossible',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return AuthResult(success: false, error: 'Pas de connexion internet');
    }

    return AuthResult(success: false, error: 'Erreur reseau');
  }
}
