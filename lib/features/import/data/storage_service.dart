import 'dart:io';

import 'package:dio/dio.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/features/import/domain/import_file.dart';

/// Resultat d'une operation storage
class StorageResult<T> {
  final bool success;
  final T? data;
  final String? error;

  StorageResult({required this.success, this.data, this.error});
}

/// Service pour les operations de stockage (upload, transform)
class StorageService {
  final ApiClient _apiClient;

  StorageService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Upload un fichier vers le storage service
  /// Retourne l'ID du fichier uploade et son URL
  Future<StorageResult<UploadResult>> uploadFile(
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
        'type': importFile.type.name,
      });

      final response = await _apiClient.uploadFile(formData);

      final data = response.data;
      return StorageResult(
        success: true,
        data: UploadResult.success(
          fileId: data['fileId'] ?? data['id'] ?? '',
          fileUrl: data['fileUrl'] ?? data['url'] ?? '',
          extractedText: data['extractedText'],
          wordCount: data['wordCount'],
        ),
      );
    } on DioException catch (e) {
      return StorageResult(success: false, error: _handleError(e));
    } catch (e) {
      return StorageResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Transforme un fichier (OCR, extraction texte)
  Future<StorageResult<Map<String, dynamic>>> transformFile(
    String fileId, {
    String? outputFormat,
  }) async {
    try {
      final response = await _apiClient.transformFile({
        'fileId': fileId,
        if (outputFormat != null) 'outputFormat': outputFormat,
      });

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

  String _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'Erreur serveur';
      if (data is Map && data['message'] != null) {
        message = data['message'];
      }

      switch (statusCode) {
        case 400:
          return 'Format de fichier non supporte';
        case 413:
          return 'Fichier trop volumineux (max 50MB)';
        case 415:
          return 'Type de fichier non supporte';
        default:
          return message;
      }
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Pas de connexion internet';
    }

    if (e.type == DioExceptionType.sendTimeout) {
      return 'Upload trop lent, veuillez reessayer';
    }

    return 'Erreur reseau';
  }
}
