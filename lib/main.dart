import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/auth/data/auth_service.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:visiobook_mobile/features/import/data/storage_service.dart';
import 'package:visiobook_mobile/features/import/presentation/providers/import_provider.dart';
import 'package:visiobook_mobile/features/project_detail/presentation/providers/project_detail_provider.dart';
import 'package:visiobook_mobile/core/services/sse_service.dart';
import 'package:visiobook_mobile/features/generation/data/generation_service.dart';
import 'package:visiobook_mobile/features/generation/data/ingestion_polling_service.dart';
import 'package:visiobook_mobile/features/generation/presentation/providers/generation_provider.dart';
import 'package:visiobook_mobile/features/export/data/export_service.dart';
import 'package:visiobook_mobile/features/export/presentation/providers/export_provider.dart';
import 'package:visiobook_mobile/features/profile/data/profile_service.dart';
import 'package:visiobook_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:visiobook_mobile/features/player/data/player_service.dart';
import 'package:visiobook_mobile/features/player/presentation/providers/player_provider.dart';
import 'package:visiobook_mobile/features/history/presentation/providers/texts_provider.dart';
import 'package:visiobook_mobile/features/payment/data/payment_service.dart';
import 'package:visiobook_mobile/features/payment/presentation/providers/payment_provider.dart';
import 'package:visiobook_mobile/features/projects/data/project_service.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';

import 'package:visiobook_mobile/core/services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.instance.init();

  // Style de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const VisioBookApp());
}

class VisioBookApp extends StatelessWidget {
  const VisioBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Services
    final storage = SecureStorageService();
    final apiClient = ApiClient(storage: storage);
    final authService = AuthService(apiClient: apiClient, storage: storage);
    final projectService = ProjectService(apiClient: apiClient);
    final storageService = StorageService(apiClient: apiClient);

    // Router
    final appRouter = AppRouter(storage: storage);

    final projectProvider = ProjectProvider(projectService: projectService);

    return MultiProvider(
      providers: [
        Provider<SecureStorageService>.value(value: storage),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider.value(value: projectProvider),
        ChangeNotifierProvider(
          create: (_) => ImportProvider(storageService: storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => TextsProvider(
            storageService: storageService,
            ingestionPollingService: IngestionPollingService(
              apiClient: apiClient,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProjectDetailProvider(projectService: projectService),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = GenerationProvider(
              generationService: GenerationService(apiClient: apiClient),
              sseService: SseService(dio: apiClient.dio),
              ingestionPollingService: IngestionPollingService(
                apiClient: apiClient,
              ),
            );
            provider.onGenerationFinished = (projectId, success, error) {
              if (success) {
                NotificationService.instance.showGenerationComplete(projectId);
              } else {
                NotificationService.instance.showGenerationFailed(projectId);
              }
              // Refresh la liste des projets pour mettre a jour les status
              projectProvider.loadProjects();
            };
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(
            playerService: PlayerService(apiClient: apiClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ExportProvider(
            exportService: ExportService(apiClient: apiClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            profileService: ProfileService(apiClient: apiClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PaymentProvider(
            paymentService: PaymentService(apiClient: apiClient),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'VisioBook',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: appRouter.router,
      ),
    );
  }
}
