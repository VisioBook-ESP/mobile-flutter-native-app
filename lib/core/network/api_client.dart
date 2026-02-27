import 'package:dio/dio.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';

/// Client HTTP avec gestion des tokens
class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;

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
      .put('${EnvironmentConfig.projectServiceUrl}/projects/$id', data: data);

  Future<Response> deleteProject(String id) =>
      _dio.delete('${EnvironmentConfig.projectServiceUrl}/projects/$id');

  Future<Response> generateProject(String id) =>
      _dio.post('${EnvironmentConfig.projectServiceUrl}/projects/$id/generate');

  Future<Response> getWorkflowStatus(
    String projectId,
    String workflowId,
  ) => _dio.get(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/workflows/$workflowId',
  );

  Future<Response> shareProject(String id, Map<String, dynamic> data) =>
      _dio.post(
        '${EnvironmentConfig.projectServiceUrl}/projects/$id/share',
        data: data,
      );

  // Player / VisioBook
  Future<Response> getVisioBook(String projectId) => _dio.get(
    '${EnvironmentConfig.projectServiceUrl}/projects/$projectId/visiobook',
  );

  // Storage Service
  Future<Response> uploadFile(FormData formData) => _dio.post(
    '${EnvironmentConfig.storageServiceUrl}/storage/upload',
    data: formData,
    options: Options(contentType: 'multipart/form-data'),
  );

  Future<Response> transformFile(Map<String, dynamic> data) => _dio.post(
    '${EnvironmentConfig.storageServiceUrl}/storage/transform',
    data: data,
  );

  Future<Response> getStreamUrl(String videoId) => _dio.get(
    '${EnvironmentConfig.storageServiceUrl}/storage/stream/$videoId',
  );

  Future<Response> getDownloadUrl(String videoId) => _dio.get(
    '${EnvironmentConfig.storageServiceUrl}/storage/download/$videoId',
  );
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
      }
    }
    handler.next(options);
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
