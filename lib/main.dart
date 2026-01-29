import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:visiobook_mobile/core/network/api_client.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';
import 'package:visiobook_mobile/features/auth/data/auth_service.dart';
import 'package:visiobook_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:visiobook_mobile/features/projects/data/project_service.dart';
import 'package:visiobook_mobile/features/projects/presentation/providers/project_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

    // Router
    final appRouter = AppRouter(storage: storage);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProjectProvider(projectService: projectService),
        ),
      ],
      child: MaterialApp.router(
        title: 'VisioBook',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: appRouter.router,
      ),
    );
  }
}
