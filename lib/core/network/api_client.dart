import 'dart:async';
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

  Future<Response> generateProject(Map<String, dynamic> data) => _dio.post(
    '${EnvironmentConfig.projectServiceUrl}/projects/generate',
    data: data,
  );

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

  // Payment / Subscriptions
  Future<Response> getSubscriptionPlans() =>
      _dio.get('${EnvironmentConfig.paymentServiceUrl}/subscriptions/plans');

  Future<Response> getCurrentSubscription() =>
      _dio.get('${EnvironmentConfig.paymentServiceUrl}/subscriptions/current');

  Future<Response> createCheckoutSession(Map<String, dynamic> data) =>
      _dio.post(
        '${EnvironmentConfig.paymentServiceUrl}/subscriptions/checkout',
        data: data,
      );

  Future<Response> cancelSubscription({String? reason}) => _dio.post(
    '${EnvironmentConfig.paymentServiceUrl}/subscriptions/cancel',
    data: reason != null ? {'reason': reason} : {},
  );

  Future<Response> upgradeSubscription(String planId) => _dio.post(
    '${EnvironmentConfig.paymentServiceUrl}/subscriptions/upgrade',
    data: {'planId': planId},
  );

  Future<Response> downgradeSubscription(String planId) => _dio.post(
    '${EnvironmentConfig.paymentServiceUrl}/subscriptions/downgrade',
    data: {'planId': planId},
  );

  Future<Response> getStripePortalUrl({String? returnUrl}) => _dio.get(
    '${EnvironmentConfig.paymentServiceUrl}/subscriptions/portal',
    queryParameters: returnUrl != null ? {'returnUrl': returnUrl} : null,
  );

  Future<Response> getQuota() =>
      _dio.get('${EnvironmentConfig.paymentServiceUrl}/quotas');

  Future<Response> createPaymentIntent(Map<String, dynamic> data) => _dio.post(
    '${EnvironmentConfig.paymentServiceUrl}/subscriptions/payment-intent',
    data: data,
  );
}

/// Intercepteur pour ajouter le token et gérer le refresh.
/// Utilise un Completer pour éviter les race conditions :
/// si plusieurs requêtes reçoivent un 401 en même temps,
/// seule la première lance le refresh, les autres attendent.
class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;

  /// Completer actif pendant un refresh en cours.
  /// null = pas de refresh en cours.
  Completer<String?>? _refreshCompleter;

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
      final newToken = await _refreshTokenWithLock();

      if (newToken != null) {
        // Retry la requête originale avec le nouveau token
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retryResponse = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (retryError) {
          // Le retry a aussi échoué
          if (retryError is DioException) {
            return handler.next(retryError);
          }
        }
      }
    }
    handler.next(err);
  }

  /// Refresh le token avec un lock : si un refresh est déjà en cours,
  /// attend le résultat au lieu de lancer un second refresh.
  Future<String?> _refreshTokenWithLock() async {
    // Un refresh est déjà en cours → attendre son résultat
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    // Premier appelant : lancer le refresh
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter!.complete(null);
        return null;
      }

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
        _refreshCompleter!.complete(newAccessToken);
        return newAccessToken;
      }

      _refreshCompleter!.complete(null);
      return null;
    } catch (_) {
      // Refresh échoué, supprimer les tokens (déconnexion)
      await _storage.clearTokens();
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }
}
