import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/features/projects/domain/project.dart';

/// Resultat d'operation sur les projets
class ProjectResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ProjectResult({required this.success, this.data, this.error});
}

/// Service pour les operations sur les projets
class ProjectService {
  final ApiClient _apiClient;

  ProjectService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Recupere tous les projets de l'utilisateur
  Future<ProjectResult<List<Project>>> getProjects() async {
    try {
      final response = await _apiClient.getProjects();
      final data = response.data;

      if (data is List) {
        final projects = data.map((json) => Project.fromJson(json)).toList();
        return ProjectResult(success: true, data: projects);
      }

      if (data is Map && data['projects'] is List) {
        final projects = (data['projects'] as List)
            .map((json) => Project.fromJson(json))
            .toList();
        return ProjectResult(success: true, data: projects);
      }

      return ProjectResult(success: true, data: []);
    } on DioException catch (e) {
      return ProjectResult(success: false, error: _handleError(e));
    } catch (e) {
      return ProjectResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Recupere les projets recents de l'utilisateur
  Future<ProjectResult<List<Project>>> getRecentProjects() async {
    try {
      final response = await _apiClient.getRecentProjects();
      final data = response.data;

      if (data is List) {
        final projects = data.map((json) => Project.fromJson(json)).toList();
        return ProjectResult(success: true, data: projects);
      }

      if (data is Map && data['projects'] is List) {
        final projects = (data['projects'] as List)
            .map((json) => Project.fromJson(json))
            .toList();
        return ProjectResult(success: true, data: projects);
      }

      return ProjectResult(success: true, data: []);
    } on DioException catch (e) {
      return ProjectResult(success: false, error: _handleError(e));
    } catch (e) {
      return ProjectResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Recupere un projet par son ID
  Future<ProjectResult<Project>> getProject(String id) async {
    try {
      final response = await _apiClient.getProject(id);
      final project = Project.fromJson(response.data);
      return ProjectResult(success: true, data: project);
    } on DioException catch (e) {
      return ProjectResult(success: false, error: _handleError(e));
    } catch (e) {
      return ProjectResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Cree un nouveau projet (pour duplication etc.)
  Future<ProjectResult<Project>> createProject({required String title}) async {
    try {
      final response = await _apiClient.createProject({'title': title});
      final project = Project.fromJson(response.data);
      return ProjectResult(success: true, data: project);
    } on DioException catch (e) {
      return ProjectResult(success: false, error: _handleError(e));
    } catch (e) {
      return ProjectResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Supprime un projet
  Future<ProjectResult<void>> deleteProject(String id) async {
    try {
      await _apiClient.deleteProject(id);
      return ProjectResult(success: true);
    } on DioException catch (e) {
      return ProjectResult(success: false, error: _handleError(e));
    } catch (e) {
      return ProjectResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Cree et lance la generation en un seul appel POST /projects/generate
  /// Envoie { title, fileId?, config } et recoit { projectId, versionId, executionId }
  Future<ProjectResult<Map<String, String>>> generateProject({
    required String title,
    String? fileId,
    required Map<String, dynamic> config,
  }) async {
    try {
      final response = await _apiClient.generateProject({
        'title': title,
        if (fileId != null) 'fileId': fileId,
        'config': config,
      });
      final data = response.data as Map<String, dynamic>;
      final projectId = data['projectId'] as String?;
      final versionId = data['versionId'] as String?;
      final executionId = data['executionId'] as String?;

      if (projectId == null || versionId == null || executionId == null) {
        return ProjectResult(
          success: false,
          error: 'Reponse incomplete du serveur',
        );
      }

      return ProjectResult(
        success: true,
        data: {
          'projectId': projectId,
          'versionId': versionId,
          'executionId': executionId,
        },
      );
    } on DioException catch (e) {
      return ProjectResult(success: false, error: _handleError(e));
    } catch (e) {
      return ProjectResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  String _handleError(DioException e) {
    // Debug: afficher les details de l'erreur
    debugPrint('[ProjectService] Error: ${e.response?.statusCode}');
    debugPrint('[ProjectService] URL: ${e.requestOptions.uri}');
    debugPrint('[ProjectService] Body: ${e.response?.data}');
    debugPrint('[ProjectService] Headers: ${e.requestOptions.headers}');

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'Erreur serveur';
      if (data is Map && data['message'] != null) {
        message = data['message'];
      }

      switch (statusCode) {
        case 404:
          return 'Projet non trouvé';
        case 403:
          return 'Accès refusé';
        default:
          return message;
      }
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Pas de connexion internet';
    }

    return 'Erreur réseau';
  }
}
