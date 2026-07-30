import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

const _splashBlack = Color(0xFF050505);
final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint("Handling a background message: ${message.messageId}");
  } catch (e) {
    debugPrint("Background FCM error: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX: Previously this whole block (Firebase.initializeApp +
  // messaging.requestPermission + messaging.getToken) was awaited
  // BEFORE runApp() was called. requestPermission() shows a native
  // Android "Allow notifications?" system dialog, which blocks the
  // main isolate until the user responds. Since runApp() hadn't run
  // yet, there was nothing on screen to even show — the app appeared
  // completely frozen/black, and if the user didn't respond fast
  // enough Android would treat it as an ANR (the "Davey! duration=
  // 4681ms" / "Wrote stack traces to tombstoned" you saw in logcat).
  //
  // Fix: initialize Firebase core synchronously (cheap, no dialogs),
  // call runApp() immediately so the UI (splash screen) shows right
  // away, and do the permission request + token fetch afterwards in
  // the background without blocking startup.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: _splashBlack,
      systemNavigationBarColor: _splashBlack,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final apiService = ApiService();
  runApp(UrbanServiceApp(apiService: apiService));

  // Do the notification-permission dialog + token fetch AFTER the UI
  // is already up and running, so it no longer blocks first frame.
  _setupFcmPermissionsAndToken(apiService);
}

Future<void> _setupFcmPermissionsAndToken(ApiService apiService) async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    debugPrint("=================================================");
    debugPrint("FCM USER TOKEN: $token");
    debugPrint("=================================================");

    if (token != null && token.isNotEmpty) {
      await apiService.init();
      await apiService.updateFcmToken(token);
    }

    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM TOKEN REFRESHED: $newToken");
      await apiService.updateFcmToken(newToken);
    });
  } catch (e) {
    debugPrint("FCM permission/token setup failed: $e");
  }
}

class UrbanServiceApp extends StatefulWidget {
  const UrbanServiceApp({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<UrbanServiceApp> createState() => _UrbanServiceAppState();
}

class _UrbanServiceAppState extends State<UrbanServiceApp> {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
    _setupFCM();
  }

  Future<void> _initLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(settings: initSettings);

      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint("Local Notification init error: $e");
    }
  }

  void _showHeadsUpBanner(String title, String body) {
    try {
      _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint("Show heads up banner error: $e");
    }
  }

  void _setupFCM() {
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final title = notification?.title ?? message.data['title'] ?? 'Notification';
        final body = notification?.body ?? message.data['body'] ?? 'New update received';

        _showHeadsUpBanner(title, body);

        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '🔔 $title: $body',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.secondary,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    } catch (e) {
      debugPrint("FCM setup listener error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: widget.apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(widget.apiService)),
        ChangeNotifierProvider(create: (_) => CatalogProvider(widget.apiService)),
        ChangeNotifierProvider(create: (_) => BookingProvider(widget.apiService)),
        ChangeNotifierProvider(create: (_) => LanguageProvider()..init()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            title: 'Urban Service',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: _messengerKey,
            theme: AppTheme.light().copyWith(
              scaffoldBackgroundColor: _splashBlack,
            ),
            locale: languageProvider.locale,
            builder: (context, child) {
              return ColoredBox(
                color: _splashBlack,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}