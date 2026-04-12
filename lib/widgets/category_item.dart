import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback? onTap; // 🔥 thêm

  const CategoryItem({
    super.key,
    required this.title,
    required this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap, // 🔥 xử lý click
        child: Stack(
          children: [

            /// IMAGE
            Positioned.fill(
              child: Image.asset(
                image,
                fit: BoxFit.cover,
              ),
            ),

            /// DARK OVERLAY
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),

            /// TEXT
            Positioned(
              left: 12,
              bottom: 12,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}