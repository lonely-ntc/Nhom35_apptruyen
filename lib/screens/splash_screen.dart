import 'package:flutter/material.dart';
import 'dart:async';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  double _opacity = 0;

  @override
  void initState() {
    super.initState();

    /// 🔥 hiệu ứng fade in
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _opacity = 1;
      });
    });

    /// 🔄 chuyển màn sau 2.5s
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(seconds: 1),
          opacity: _opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// 🔹 Logo (ảnh bạn gửi)
              Image.asset(
                "assets/images/logoSplashScreen.gif",
                width: 180,
              ),

              const SizedBox(height: 30),

              /// 🔹 Loading
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}