import 'dart:io';

import 'package:dio/dio.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/features/import/domain/import_file.dart';

/// Resultat d'une operation storage
class StorageResult<T> {
  final bool success;
  final T? data;
  final String? error;

  StorageResult({required this.success, this.data, this.error});
}

/// Service pour les operations d'upload et d'ingestion de contenu
class StorageService {
  final ApiClient _apiClient;

  StorageService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Upload un fichier vers le content-ingestion-service
  /// Retourne le fileId pour lancer l'ingestion ensuite
  Future<StorageResult<UploadResult>> uploadFile(
    ImportFile importFile, {
    String? projectId,
    Function(double)? onProgress,
  }) async {
    try {
      final file = File(importFile.path);
      if (!await file.exists()) {
        return StorageResult(success: false, error: 'Fichier introuvable');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          importFile.path,
          filename: importFile.name,
        ),
        'project_id': projectId ?? '',
      });

      final response = await _apiClient.dio.post(
        '${EnvironmentConfig.ingestionServiceUrl}/upload/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onProgress != null
            ? (sent, total) {
                if (total > 0) {
                  onProgress(sent / total);
                }
              }
            : null,
      );

      final data = response.data;
      return StorageResult(
        success: true,
        data: UploadResult.success(
          fileId: data['fileId'] as String? ?? '',
          fileUrl: '',
        ),
      );
    } on DioException catch (e) {
      return StorageResult(success: false, error: _handleError(e));
    } catch (e) {
      return StorageResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Lance l'ingestion asynchrone d'un fichier deja uploade
  /// Retourne le jobId pour suivre la progression
  Future<StorageResult<String>> startIngestion({
    required String fileId,
    required String projectId,
    bool cleanText = true,
    bool extractMetadata = true,
    int chunkSize = 1000,
    int overlap = 100,
  }) async {
    try {
      final response = await _apiClient.startIngestion({
        'fileId': fileId,
        'projectId': projectId,
        'options': {
          'cleanText': cleanText,
          'extractMetadata': extractMetadata,
          'chunkSize': chunkSize,
          'overlap': overlap,
        },
      });

      final jobId = response.data['jobId'] as String?;
      if (jobId == null) {
        return StorageResult(success: false, error: 'Aucun jobId retourne');
      }
      return StorageResult(success: true, data: jobId);
    } on DioException catch (e) {
      return StorageResult(success: false, error: _handleError(e));
    } catch (e) {
      return StorageResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Recupere le statut d'un job d'ingestion
  Future<StorageResult<Map<String, dynamic>>> getIngestionStatus(
    String jobId,
  ) async {
    try {
      final response = await _apiClient.getIngestionStatus(jobId);
      return StorageResult(
        success: true,
        data: response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return StorageResult(success: false, error: _handleError(e));
    } catch (e) {
      return StorageResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Extraction directe de texte (upload + extraction en une etape)
  Future<StorageResult<UploadResult>> extractTextFromFile(
    ImportFile importFile, {
    Function(double)? onProgress,
  }) async {
    try {
      final file = File(importFile.path);
      if (!await file.exists()) {
        return StorageResult(success: false, error: 'Fichier introuvable');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          importFile.path,
          filename: importFile.name,
        ),
      });

      final response = await _apiClient.dio.post(
        '${EnvironmentConfig.ingestionServiceUrl}/extract/text',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onProgress != null
            ? (sent, total) {
                if (total > 0) {
                  onProgress(sent / total);
                }
              }
            : null,
      );

      final data = response.data;
      return StorageResult(
        success: true,
        data: UploadResult.success(
          fileId: '',
          fileUrl: '',
          extractedText: data['text'] as String?,
          wordCount: data['wordCount'] as int?,
        ),
      );
    } on DioException catch (e) {
      return StorageResult(success: false, error: _handleError(e));
    } catch (e) {
      return StorageResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Recupere la liste des fichiers de l'utilisateur
  Future<StorageResult<List<Map<String, dynamic>>>> getFiles() async {
    try {
      final response = await _apiClient.getFilesByToken();
      final data = response.data;

      if (data is List) {
        return StorageResult(
          success: true,
          data: data.cast<Map<String, dynamic>>(),
        );
      }

      if (data is Map && data['files'] is List) {
        return StorageResult(
          success: true,
          data: (data['files'] as List).cast<Map<String, dynamic>>(),
        );
      }

      return StorageResult(success: true, data: []);
    } on DioException catch (e) {
      return StorageResult(success: false, error: _handleError(e));
    } catch (e) {
      return StorageResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'Erreur serveur';
      if (data is Map && data['detail'] != null) {
        message = data['detail'].toString();
      } else if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }

      switch (statusCode) {
        case 400:
          return message;
        case 413:
          return 'Fichier trop volumineux (max 50MB)';
        case 415:
          return 'Type de fichier non supporté';
        default:
          return message;
      }
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Pas de connexion internet';
    }

    if (e.type == DioExceptionType.sendTimeout) {
      return 'Upload trop lent, veuillez réessayer';
    }

    return 'Erreur réseau';
  }
}
