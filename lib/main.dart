import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visiobook_mobile/core/theme/app_theme.dart';
import 'package:visiobook_mobile/core/routing/app_router.dart';
import 'package:visiobook_mobile/core/utils/secure_storage.dart';

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
    final storage = SecureStorageService();
    final appRouter = AppRouter(storage: storage);

    return MaterialApp.router(
      title: 'VisioBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter.router,
    );
  }
}
