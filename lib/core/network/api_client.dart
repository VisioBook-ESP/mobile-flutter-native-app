import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';

/// Client HTTP avec gestion des tokens
class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;

  Dio get dio => _dio;

  ApiClient({required SecureStorageService storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_storage, _dio));
  }

  // User Service
  Future<Response> authRegister(Map<String, dynamic> data) => _dio.post(
    '${EnvironmentConfig.userServiceUrl}/auth/register',
    data: data,
  );

  Future<Response> authLogin(Map<String, dynamic> data) =>
      _dio.post('${EnvironmentConfig.userServiceUrl}/auth/login', data: data);

  Future<Response> authRefresh(String refreshToken) => _dio.post(
    '${EnvironmentConfig.userServiceUrl}/auth/refresh',
    data: {'refreshToken': refreshToken},
  );

  Future<Response> authVerify(String token) => _dio.post(
    '${EnvironmentConfig.userServiceUrl}/auth/verify',
    data: {'token': token},
  );

  // Project Service
  Future<Response> getProjects() =>
      _dio.get('${EnvironmentConfig.projectServiceUrl}/projects');

  Future<Response> getRecentProjects() =>
      _dio.get('${EnvironmentConfig.projectServiceUrl}/projects/recent');

  Future<Response> getProject(String id) =>
      _dio.get('${EnvironmentConfig.projectServiceUrl}/projects/$id');

  Future<Response> createProject(Map<String, dynamic> data) =>
      _dio.post('${EnvironmentConfig.projectServiceUrl}/projects', data: data);

  Future<Response> updateProject(String id, Map<String, dynamic> data) => _dio
      .patch('${EnvironmentConfig.projectServiceUrl}/projects/$id', data: data);

  Future<Response> deleteProject(String id) =>
      _dio.delete('${EnvironmentConfig.projectServiceUrl}/projects/$id');

  // Versions & Workflow
  Future<Response> createVersion(String projectId) => _dio.post(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/versions',
  );

  Future<Response> startWorkflow(
    String projectId,
    String versionId,
  ) => _dio.post(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/versions/$versionId/workflow/start',
  );

  Future<Response> getWorkflowStatus(
    String projectId,
    String versionId,
    String executionId,
  ) => _dio.get(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/versions/$versionId/workflow/status/$executionId',
  );

  Future<Response> cancelWorkflow(
    String projectId,
    String versionId,
    String executionId,
  ) => _dio.post(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/versions/$versionId/workflow/cancel/$executionId',
  );

  Future<Response> retryWorkflow(
    String projectId,
    String versionId,
    String executionId,
  ) => _dio.post(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/versions/$versionId/workflow/retry/$executionId',
  );

  // Content
  Future<Response> getContent(String projectId) => _dio.get(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/content',
  );

  Future<Response> updateContent(String projectId, Map<String, dynamic> data) =>
      _dio.patch(
        '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/content',
        data: data,
      );

  Future<Response> getScenes(String projectId) => _dio.get(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/content/scenes',
  );

  Future<Response> getContentSummary(String projectId) => _dio.get(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/content/summary',
  );

  Future<Response> updateScene(
    String projectId,
    String sceneId,
    Map<String, dynamic> data,
  ) => _dio.patch(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/content/scenes/$sceneId',
    data: data,
  );

  Future<Response> getCharacters(String projectId) => _dio.get(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/content/characters',
  );

  // Share
  Future<Response> shareProject(String id, Map<String, dynamic> data) =>
      _dio.post(
        '${EnvironmentConfig.projectServiceUrl}/projects/$id/share',
        data: data,
      );

  Future<Response> getShareLinks(String id) =>
      _dio.get('${EnvironmentConfig.projectServiceUrl}/projects/$id/share');

  Future<Response> deleteShareLinks(String id) =>
      _dio.delete('${EnvironmentConfig.projectServiceUrl}/projects/$id/share');

  // Player / VisioBook
  Future<Response> getVisioBook(String projectId) => _dio.get(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/visiobook',
  );

  // Content Ingestion Service
  Future<Response> getFilesByToken() =>
      _dio.get('${EnvironmentConfig.ingestionServiceUrl}/folders/files');

  Future<Response> uploadFile(FormData formData) => _dio.post(
    '${EnvironmentConfig.ingestionServiceUrl}/upload/',
    data: formData,
    options: Options(contentType: 'multipart/form-data'),
  );

  Future<Response> startIngestion(Map<String, dynamic> data) =>
      _dio.post('${EnvironmentConfig.ingestionServiceUrl}/ingest/', data: data);

  Future<Response> getIngestionStatus(String jobId) =>
      _dio.get('${EnvironmentConfig.ingestionServiceUrl}/ingest/status/$jobId');

  Future<Response> extractText(FormData formData) => _dio.post(
    '${EnvironmentConfig.ingestionServiceUrl}/extract/text',
    data: formData,
    options: Options(contentType: 'multipart/form-data'),
  );

  Future<Response> extractMetadata(FormData formData) => _dio.post(
    '${EnvironmentConfig.ingestionServiceUrl}/extract/metadata',
    data: formData,
    options: Options(contentType: 'multipart/form-data'),
  );

  Future<Response> getDownloadUrl(String videoId) => _dio.get(
    '${EnvironmentConfig.projectServiceUrl}/storage/download/$videoId',
  );

  // Profile / User
  Future<Response> getProfile() =>
      _dio.get('${EnvironmentConfig.userServiceUrl}/users/me');

  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.put('${EnvironmentConfig.userServiceUrl}/users/me', data: data);

  Future<Response> deleteAccount() =>
      _dio.delete('${EnvironmentConfig.userServiceUrl}/users/me');
}

/// Intercepteur pour ajouter le token et gérer le refresh
class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Ne pas ajouter de token pour les endpoints d'auth
    final isAuthEndpoint = options.path.contains('/auth/');
    if (!isAuthEndpoint) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        // Extraire le userId du JWT et l'ajouter en header X-User-Id
        final userId = _extractUserIdFromJwt(token);
        if (userId != null) {
          options.headers['X-User-Id'] = userId;
        }
      }
    }
    handler.next(options);
  }

  /// Décode le payload JWT et extrait le champ "sub" (userId)
  String? _extractUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      // Ajouter le padding base64 manquant
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return json['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expiré, essayer de refresh
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            '${EnvironmentConfig.userServiceUrl}/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken = response.data['access_token'] as String?;
          final newRefreshToken = response.data['refresh_token'] as String?;

          if (newAccessToken != null) {
            await _storage.saveAccessToken(newAccessToken);
            if (newRefreshToken != null) {
              await _storage.saveRefreshToken(newRefreshToken);
            }

            // Retry la requête originale avec le nouveau token
            err.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final retryResponse = await _dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Refresh échoué, supprimer les tokens
          await _storage.clearTokens();
        }
      }
    }
    handler.next(err);
  }
}
