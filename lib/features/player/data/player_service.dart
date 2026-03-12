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

  /// Fetch VisioBook scenes for a project
  Future<PlayerResult<VisioBookData>> getVisioBook(String projectId) async {
    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      return PlayerResult(
        success: true,
        data: _generateMockVisioBook(projectId),
      );
    }

    try {
      final response = await _apiClient.getVisioBook(projectId);
      final data = VisioBookData.fromJson(
        response.data as Map<String, dynamic>,
      );
      return PlayerResult(success: true, data: data);
    } on DioException catch (e) {
      return PlayerResult(success: false, error: _handleError(e));
    } catch (e) {
      return PlayerResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  VisioBookData _generateMockVisioBook(String projectId) {
    // Generate 8 mock scenes simulating a story about space exploration
    final scenes = <VisioBookScene>[
      const VisioBookScene(
        id: 'scene_1',
        order: 0,
        imageUrl: 'https://picsum.photos/seed/vb1/800/600',
        subtitleText:
            'Il etait une fois, dans une galaxie lointaine, un explorateur nomme Atlas.',
        audioDuration: Duration(seconds: 4),
      ),
      const VisioBookScene(
        id: 'scene_2',
        order: 1,
        imageUrl: 'https://picsum.photos/seed/vb2/800/600',
        subtitleText:
            'Atlas revait de decouvrir de nouveaux mondes au-dela des etoiles.',
        audioDuration: Duration(seconds: 4),
      ),
      const VisioBookScene(
        id: 'scene_3',
        order: 2,
        imageUrl: 'https://picsum.photos/seed/vb3/800/600',
        subtitleText:
            'Un jour, il trouva une carte ancienne menant a une planete inconnue.',
        audioDuration: Duration(seconds: 4),
      ),
      const VisioBookScene(
        id: 'scene_4',
        order: 3,
        imageUrl: 'https://picsum.photos/seed/vb4/800/600',
        subtitleText:
            'Il prepara son vaisseau et quitta la Terre sans regarder en arriere.',
        audioDuration: Duration(seconds: 4),
      ),
      const VisioBookScene(
        id: 'scene_5',
        order: 4,
        imageUrl: 'https://picsum.photos/seed/vb5/800/600',
        subtitleText:
            'Apres des semaines de voyage, il arriva devant un monde magnifique.',
        audioDuration: Duration(seconds: 4),
      ),
      const VisioBookScene(
        id: 'scene_6',
        order: 5,
        imageUrl: 'https://picsum.photos/seed/vb6/800/600',
        subtitleText:
            "Des forets cristallines s'etendaient a perte de vue sous un ciel violet.",
        audioDuration: Duration(seconds: 5),
      ),
      const VisioBookScene(
        id: 'scene_7',
        order: 6,
        imageUrl: 'https://picsum.photos/seed/vb7/800/600',
        subtitleText:
            "Atlas rencontra des creatures bienveillantes qui l'accueillirent comme un ami.",
        audioDuration: Duration(seconds: 5),
      ),
      const VisioBookScene(
        id: 'scene_8',
        order: 7,
        imageUrl: 'https://picsum.photos/seed/vb8/800/600',
        subtitleText:
            "Il comprit que l'univers etait rempli de merveilles qui attendaient d'etre decouvertes.",
        audioDuration: Duration(seconds: 5),
      ),
    ];

    return VisioBookData(
      projectId: projectId,
      title: "L'Explorateur des Etoiles",
      scenes: scenes,
      createdAt: DateTime.now(),
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
          return 'VisioBook non trouvé';
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
