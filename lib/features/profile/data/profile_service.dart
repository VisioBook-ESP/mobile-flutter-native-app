import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/features/profile/domain/user_profile.dart';

class ProfileService {
  final ApiClient _apiClient;

  ProfileService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Recuperer le profil de l'utilisateur connecte
  Future<UserProfile> getProfile() async {
    if (EnvironmentConfig.useMockData) {
      return _mockProfile();
    }

    final response = await _apiClient.getProfile();
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mettre a jour le profil
  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (username != null) data['username'] = username;
    if (email != null) data['email'] = email;

    if (EnvironmentConfig.useMockData) {
      final mock = _mockProfile();
      return mock.copyWith(
        firstName: firstName ?? mock.firstName,
        lastName: lastName ?? mock.lastName,
        username: username ?? mock.username,
        email: email ?? mock.email,
      );
    }

    final response = await _apiClient.updateProfile(data);
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Changer le mot de passe
  Future<void> changePassword({required String newPassword}) async {
    if (EnvironmentConfig.useMockData) {
      return;
    }

    await _apiClient.updateProfile({'password': newPassword});
  }

  /// Supprimer le compte
  Future<void> deleteAccount() async {
    if (EnvironmentConfig.useMockData) {
      return;
    }

    await _apiClient.deleteAccount();
  }

  /// Recuperer les credits
  Future<int> getCredits() async {
    return 0;
  }

  UserProfile _mockProfile() {
    return UserProfile(
      id: 'mock-user-001',
      username: 'demo_user',
      email: 'demo@visiobook.com',
      firstName: 'Demo',
      lastName: 'User',
      avatarUrl: null,
      credits: 150,
    );
  }
}
