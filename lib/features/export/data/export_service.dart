import 'package:dio/dio.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/features/export/domain/export_state.dart';

/// Resultat d'operation sur l'export
class ExportResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ExportResult({required this.success, this.data, this.error});
}

/// Service pour les operations d'export et de partage
class ExportService {
  final ApiClient _apiClient;

  ExportService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Telecharge la video du projet
  Future<ExportResult<String>> downloadVideo({
    required String projectId,
    required String savePath,
    required ExportQuality quality,
    void Function(double progress)? onProgress,
  }) async {
    // Mode mock
    if (EnvironmentConfig.useMockData) {
      // Simulation de telechargement progressif
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        onProgress?.call(i / 10.0);
      }
      return ExportResult(success: true, data: savePath);
    }

    try {
      // Récupérer le VisioBook pour obtenir l'URL de la vidéo
      final visiobookResponse = await _apiClient.getVisioBook(projectId);
      final downloadUrl =
          visiobookResponse.data['videoUrl'] as String? ??
          visiobookResponse.data['url'] as String? ??
          visiobookResponse.data['downloadUrl'] as String?;
      if (downloadUrl == null) {
        return ExportResult(
          success: false,
          error: 'URL de téléchargement non disponible',
        );
      }
      await _apiClient.dio.download(
        downloadUrl,
        savePath,
        queryParameters: {'quality': quality.name},
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(received / total);
          }
        },
      );
      return ExportResult(success: true, data: savePath);
    } on DioException catch (e) {
      return ExportResult(success: false, error: _handleError(e));
    } catch (e) {
      return ExportResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Genere un lien de partage pour un projet
  Future<ExportResult<String>> generateShareLink(String projectId) async {
    // Mode mock
    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return ExportResult(
        success: true,
        data: 'https://visiobook.app/share/$projectId',
      );
    }

    try {
      final response = await _apiClient.shareProject(projectId, {});
      final link = response.data['shareLink'] as String?;
      if (link == null) {
        return ExportResult(
          success: false,
          error: 'Aucun lien de partage retourné',
        );
      }
      return ExportResult(success: true, data: link);
    } on DioException catch (e) {
      return ExportResult(success: false, error: _handleError(e));
    } catch (e) {
      return ExportResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Gestion des erreurs Dio
  String _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'Erreur serveur';
      if (data is Map && data['message'] != null) {
        message = data['message'] as String;
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
