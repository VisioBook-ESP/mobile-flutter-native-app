import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/features/profile/data/profile_service.dart';
import 'package:visiobook_mobile/features/profile/domain/user_profile.dart';

enum ProfileState { initial, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileState _state = ProfileState.initial;
  UserProfile? _profile;
  String? _error;

  ProfileProvider({required ProfileService profileService})
    : _profileService = profileService;

  ProfileState get state => _state;
  UserProfile? get profile => _profile;
  String? get error => _error;
  bool get isLoading => _state == ProfileState.loading;

  /// Charger le profil utilisateur
  Future<void> loadProfile() async {
    _state = ProfileState.loading;
    _error = null;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile();
      _state = ProfileState.loaded;
    } on DioException catch (e) {
      _state = ProfileState.error;
      _error = _handleDioError(e);
    } catch (e) {
      _state = ProfileState.error;
      _error = 'Erreur inattendue: $e';
    }
    notifyListeners();
  }

  /// Mettre a jour le profil
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
  }) async {
    _state = ProfileState.loading;
    _error = null;
    notifyListeners();

    try {
      _profile = await _profileService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
      );
      _state = ProfileState.loaded;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _state = ProfileState.error;
      _error = _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _state = ProfileState.error;
      _error = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  /// Changer le mot de passe
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _state = ProfileState.loading;
    _error = null;
    notifyListeners();

    try {
      await _profileService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _state = ProfileState.loaded;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _state = ProfileState.error;
      _error = _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _state = ProfileState.error;
      _error = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  /// Supprimer le compte
  Future<bool> deleteAccount() async {
    _state = ProfileState.loading;
    _error = null;
    notifyListeners();

    try {
      await _profileService.deleteAccount();
      _profile = null;
      _state = ProfileState.initial;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _state = ProfileState.error;
      _error = _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _state = ProfileState.error;
      _error = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  /// Rafraichir les credits
  Future<void> refreshCredits() async {
    try {
      final credits = await _profileService.getCredits();
      if (_profile != null) {
        _profile = _profile!.copyWith(credits: credits);
        notifyListeners();
      }
    } catch (_) {
      // Silencieux : ne pas bloquer l'UI pour un refresh de credits
    }
  }

  /// Reset l'erreur
  void clearError() {
    _error = null;
    if (_state == ProfileState.error) {
      _state = _profile != null ? ProfileState.loaded : ProfileState.initial;
    }
    notifyListeners();
  }

  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data['detail'] != null) return data['detail'].toString();
        if (data['message'] != null) return data['message'].toString();
      }
      switch (e.response!.statusCode) {
        case 400:
          return 'Données invalides';
        case 401:
          return 'Session expirée, veuillez vous reconnecter';
        case 403:
          return 'Accès refusé';
        case 404:
          return 'Profil introuvable';
        default:
          return 'Erreur serveur';
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connexion au serveur impossible';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Pas de connexion internet';
    }

    return 'Erreur réseau';
  }
}
