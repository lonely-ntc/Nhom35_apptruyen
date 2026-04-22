import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider( // 🔥 QUAN TRỌNG
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => LanguageService()), // 🔥 THÊM
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final langService = Provider.of<LanguageService>(context); // 🔥 THÊM

    ///  BASE THEME
    final baseLight = themeService.lightTheme;
    final baseDark = themeService.darkTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      /// ===== LIGHT =====
      theme: baseLight.copyWith(
        textTheme: baseLight.textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),

      /// ===== DARK =====
      darkTheme: baseDark.copyWith(
        textTheme: baseDark.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),

      ///  THEME MODE
      themeMode:
          themeService.isDark ? ThemeMode.dark : ThemeMode.light,

      ///  FORCE REBUILD KHI ĐỔI NGÔN NGỮ
      locale: Locale(langService.lang),

      home: const SplashScreen(),
    );
  }
}