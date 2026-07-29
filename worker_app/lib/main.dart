import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/catalog_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

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
  
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
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
    debugPrint("FCM WORKER TOKEN: $token");
    debugPrint("=================================================");

    final apiService = ApiService();
    if (token != null && token.isNotEmpty) {
      await apiService.init();
      await apiService.updateFcmToken(token);
    }

    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM WORKER TOKEN REFRESHED: $newToken");
      await apiService.updateFcmToken(newToken);
    });

    runApp(UrbanServiceApp(apiService: apiService));
  } catch (e) {
    debugPrint("Firebase init failed: $e");
    final apiService = ApiService();
    runApp(UrbanServiceApp(apiService: apiService));
  }
}

class UrbanServiceApp extends StatefulWidget {
  const UrbanServiceApp({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<UrbanServiceApp> createState() => _UrbanServiceAppState();
}

class _UrbanServiceAppState extends State<UrbanServiceApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
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
        final body = notification?.body ?? message.data['body'] ?? 'New job update';

        _showHeadsUpBanner(title, body);

        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '🔔 $title: $body',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.olive,
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
      ],
      child: MaterialApp(
        title: 'Urban Service',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _messengerKey,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
