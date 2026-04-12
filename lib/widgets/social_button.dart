import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.network(
          "https://cdn-icons-png.flaticon.com/512/vv2991/2991148.png",
          height: 20,
        ),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }
}