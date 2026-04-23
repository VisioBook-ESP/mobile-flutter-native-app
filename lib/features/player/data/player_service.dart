import 'package:dio/dio.dart';
import 'package:visiobook_mobile/config/environment.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/features/player/domain/visiobook_reader_state.dart';

class PlayerResult<T> {
  final bool success;
  final T? data;
  final String? error;

  PlayerResult({required this.success, this.data, this.error});
}

class PlayerService {
  final ApiClient _apiClient;

  PlayerService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch VisioBook data for a project
  Future<PlayerResult<VisiobookData>> getVisioBook(String projectId) async {
    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      return PlayerResult(
        success: true,
        data: _generateMockVisioBook(projectId),
      );
    }

    try {
      // Essayer d'abord l'endpoint /visiobook dédié
      try {
        final response = await _apiClient.getVisioBook(projectId);
        final data = VisiobookData.fromJson(
          response.data as Map<String, dynamic>,
        );
        return PlayerResult(success: true, data: data);
      } on DioException catch (e) {
        // Si 404, fallback sur les scènes du projet
        if (e.response?.statusCode != 404) rethrow;
      }

      // Fallback : construire depuis les scènes + données projet
      final projectResponse = await _apiClient.getProject(projectId);
      final scenesResponse = await _apiClient.getScenes(projectId);
      final projectData = projectResponse.data as Map<String, dynamic>;
      final scenesData = scenesResponse.data;
      final scenes = scenesData is List
          ? scenesData
          : (scenesData is Map ? scenesData['items'] as List? ?? [] : []);

      final data = VisiobookData.fromScenesResponse(
        projectJson: projectData,
        scenes: scenes,
      );
      return PlayerResult(success: true, data: data);
    } on DioException catch (e) {
      return PlayerResult(success: false, error: _handleError(e));
    } catch (e) {
      return PlayerResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  VisiobookData _generateMockVisioBook(String projectId) {
    return VisiobookData(
      projectId: projectId,
      title: "L'Explorateur des Etoiles",
      coverUrl: 'https://picsum.photos/seed/cover/400/560',
      totalPages: 3,
      style: 'realistic',
      language: 'fr',
      createdAt: DateTime.now(),
      pages: [
        VisiobookPage(
          pageNumber: 1,
          panels: [
            VisiobookPanel(
              id: 'panel_001',
              order: 0,
              videoUrl: 'https://storage.example.com/panels/panel_001.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p1/1080/1350',
              narratorText:
                  'Dans une galaxie lointaine, un explorateur nomme Atlas preparait son voyage.',
              videoDurationMs: 10000,
            ),
            VisiobookPanel(
              id: 'panel_002',
              order: 1,
              videoUrl: 'https://storage.example.com/panels/panel_002.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p2/1080/1350',
              dialogueText: 'Atlas : Les etoiles m\'appellent...',
              videoDurationMs: 8000,
            ),
            VisiobookPanel(
              id: 'panel_003',
              order: 2,
              videoUrl: 'https://storage.example.com/panels/panel_003.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p3/1080/1350',
              dialogueText: 'Luna : Tu ne peux pas partir seul !',
              videoDurationMs: 7000,
            ),
            VisiobookPanel(
              id: 'panel_004',
              order: 3,
              videoUrl: 'https://storage.example.com/panels/panel_004.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p4/1080/1350',
              narratorText:
                  'Mais rien ne pouvait arreter Atlas. Il embarqua a bord du Nebula.',
              videoDurationMs: 12000,
            ),
          ],
        ),
        VisiobookPage(
          pageNumber: 2,
          panels: [
            VisiobookPanel(
              id: 'panel_005',
              order: 0,
              videoUrl: 'https://storage.example.com/panels/panel_005.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p5/1080/1350',
              narratorText:
                  "L'espace s'etendait devant lui, infini et silencieux.",
              videoDurationMs: 10000,
            ),
            VisiobookPanel(
              id: 'panel_006',
              order: 1,
              videoUrl: 'https://storage.example.com/panels/panel_006.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p6/1080/1350',
              dialogueText: "Atlas : C'est... magnifique.",
              videoDurationMs: 8000,
            ),
            VisiobookPanel(
              id: 'panel_007',
              order: 2,
              videoUrl: 'https://storage.example.com/panels/panel_007.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p7/1080/1350',
              narratorText:
                  'Des forets cristallines brillaient sous un ciel violet.',
              videoDurationMs: 9000,
            ),
          ],
        ),
        VisiobookPage(
          pageNumber: 3,
          panels: [
            VisiobookPanel(
              id: 'panel_008',
              order: 0,
              videoUrl: 'https://storage.example.com/panels/panel_008.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p8/1080/1350',
              dialogueText: 'Luna : Atlas, tu me recois ?',
              videoDurationMs: 7000,
            ),
            VisiobookPanel(
              id: 'panel_009',
              order: 1,
              videoUrl: 'https://storage.example.com/panels/panel_009.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p9/1080/1350',
              dialogueText: 'Atlas : Fort et clair !',
              videoDurationMs: 6000,
            ),
            VisiobookPanel(
              id: 'panel_010',
              order: 2,
              videoUrl: 'https://storage.example.com/panels/panel_010.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p10/1080/1350',
              narratorText: 'La transmission se coupa brusquement.',
              videoDurationMs: 8000,
            ),
            VisiobookPanel(
              id: 'panel_011',
              order: 3,
              videoUrl: 'https://storage.example.com/panels/panel_011.mp4',
              thumbnailUrl: 'https://picsum.photos/seed/p11/1080/1350',
              narratorText:
                  "Il comprit que l'univers etait rempli de merveilles qui attendaient d'etre decouvertes.",
              dialogueText: "Atlas : L'aventure ne fait que commencer.",
              videoDurationMs: 12000,
            ),
          ],
        ),
      ],
    );
  }

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
          return 'VisioBook non trouve';
        case 403:
          return 'Acces refuse';
        default:
          return message;
      }
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Pas de connexion internet';
    }

    return 'Erreur reseau';
  }
}
