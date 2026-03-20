import 'package:dio/dio.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';

/// Resultat d'authentification
class AuthResult {
  final bool success;
  final String? error;
  final String? userId;
  final String? userName;

  AuthResult({required this.success, this.error, this.userId, this.userName});
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
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;

      if (accessToken != null) {
        await _storage.saveAccessToken(accessToken);
        if (refreshToken != null) {
          await _storage.saveRefreshToken(refreshToken);
        }
        final userId = _extractUserIdFromJwt(accessToken);
        if (userId != null) {
          await _storage.saveUserId(userId);
        }
        final userName = _extractUserName(data);
        if (userName != null) {
          await _storage.saveUserName(userName);
        }
        return AuthResult(success: true, userId: userId, userName: userName);
      }

      return AuthResult(success: false, error: 'Réponse invalide du serveur');
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Inscription
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _apiClient.authRegister({
        'email': email,
        'username': username,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': 'user',
      });

      final data = response.data;
      final accessToken = data['access_token'] as String?;

      if (accessToken != null) {
        await _storage.saveAccessToken(accessToken);
        final userId = _extractUserIdFromJwt(accessToken);
        if (userId != null) {
          await _storage.saveUserId(userId);
        }
        await _storage.saveUserName(firstName);
        return AuthResult(success: true, userId: userId, userName: firstName);
      }

      // Si pas de token dans la reponse register, login automatique
      return login(email: email, password: password);
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

  /// Recupere le nom stocke localement
  Future<String?> getSavedUserName() async {
    return _storage.getUserName();
  }

  /// Extrait le nom d'utilisateur depuis la reponse API
  String? _extractUserName(dynamic data) {
    if (data is Map) {
      // Format: { user: { first_name, username, ... } }
      if (data['user'] is Map) {
        final user = data['user'] as Map;
        return user['first_name'] as String? ??
            user['username'] as String? ??
            user['email'] as String?;
      }
      // Format plat: { first_name, username, ... }
      return data['first_name'] as String? ??
          data['username'] as String? ??
          data['email'] as String?;
    }
    return null;
  }

  /// Extrait le sub (userId) du JWT sans verification de signature
  String? _extractUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decoder le payload (base64url)
      String payload = parts[1];
      // Ajouter le padding base64 si necessaire
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = Uri.decodeFull(
        String.fromCharCodes(_base64UrlDecode(payload)),
      );

      // Parser le JSON
      final regex = RegExp(r'"sub"\s*:\s*"([^"]+)"');
      final match = regex.firstMatch(decoded);
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }

  List<int> _base64UrlDecode(String input) {
    String normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    return List<int>.from(
      Uri.parse('data:;base64,$normalized').data!.contentAsBytes(),
    );
  }

  /// Gestion des erreurs Dio
  AuthResult _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'Erreur serveur';
      if (data is Map) {
        if (data['detail'] != null) {
          message = data['detail'].toString();
        } else if (data['message'] != null) {
          message = data['message'].toString();
        }
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
            error: 'Cet email ou nom d\'utilisateur est déjà utilisé',
          );
        case 422:
          return AuthResult(success: false, error: 'Données invalides');
        default:
          return AuthResult(success: false, error: message);
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

    return AuthResult(success: false, error: 'Erreur réseau');
  }
}
