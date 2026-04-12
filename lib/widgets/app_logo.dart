import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// 🔹 Logo Image
        Image.asset(
          "assets/images/app_icon.png",
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 10),

        /// 🔹 App name (optional)
        Text(
          "Comic Manga",
          style: TextStyle(
            fontSize: size * 0.15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}