import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/catalog_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

const _splashBlack = Color(0xFF050505);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class UrbanServiceApp extends StatelessWidget {
  const UrbanServiceApp({super.key, required this.apiService});

  final ApiService apiService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => CatalogProvider(apiService)),
        ChangeNotifierProvider(create: (_) => BookingProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'Urban Service',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light().copyWith(
          scaffoldBackgroundColor: _splashBlack,
        ),
        builder: (context, child) {
          return ColoredBox(
            color: _splashBlack,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
