import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

const _splashBlack = Color(0xFF050505);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
us  try {
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

    final token = await messaging.getToken();
    debugPrint("=================================================");
    debugPrint("FCM USER TOKEN: $token");
    debugPrint("=================================================");
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
}

class UrbanServiceApp extends StatefulWidget {
  const UrbanServiceApp({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<UrbanServiceApp> createState() => _UrbanServiceAppState();
}

class _UrbanServiceAppState extends State<UrbanServiceApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() {
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                '🔔 ${notification.title}: ${notification.body}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.secondary,
              duration: const Duration(seconds: 5),
            ),
          );
        }
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
