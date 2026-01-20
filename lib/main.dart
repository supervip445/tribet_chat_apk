import 'package:dhamma_apk/navigation/navigation_key.dart';
import 'package:dhamma_apk/screens/splash_screen.dart';
import 'package:dhamma_apk/widgets/back_button_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';

import 'app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.remove();

  try {
    await Firebase.initializeApp();
    await FCMService().initialize();
    developer.log('✅ Firebase & FCM initialized');
  } catch (e) {
    developer.log('❌ Firebase error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Tri chat',
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        onGenerateRoute: AppRoutes.generateRoute,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD97706),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFEF3C7),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        builder: (context, child) {
          return BackButtonHandler(child: child ?? const SizedBox());
        },
      ),
    );
  }
}
