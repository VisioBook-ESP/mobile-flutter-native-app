import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'generation';
  static const _channelName = 'Génération';

  bool _initialized = false;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Ne pas demander les permissions au init — on les demandera au premier login
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const macosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
    );

    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {}
  }

  Future<void> requestPermission() async {
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      await macos?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  Future<void> showGenerationComplete(String projectTitle) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: 0,
        title: 'Votre VisioBook est prêt !',
        body: 'La génération de $projectTitle est terminée.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  Future<void> showGenerationFailed(String projectTitle) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: 1,
        title: 'Échec de la génération',
        body: 'La génération de $projectTitle a échoué.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }
}
