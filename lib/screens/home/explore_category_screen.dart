import 'package:flutter/material.dart';
import 'category_detail_screen.dart';

class ExploreCategoryScreen extends StatelessWidget {
  const ExploreCategoryScreen({super.key});

  static const List<String> categories = [
    "Tiên Hiệp",
    "Kiếm Hiệp",
    "Ngôn Tình",
    "Đam Mỹ",
    "Bách Hợp",
    "Quan Trường",
    "Võng Du",
    "Khoa Huyễn",
    "Hệ Thống",
    "Huyền Huyễn",
    "Dị Giới",
    "Dị Năng",
    "Quân Sự",
    "Lịch Sử",
    "Xuyên Không",
    "Xuyên Nhanh",
    "Trọng Sinh",
    "Trinh Thám",
    "Linh Dị",
    "Ngược",
    "Sắc",
    "Sủng",
    "Cung Đấu",
    "Nữ Cường",
    "Gia Đấu",
    "Đông Phương",
    "Đô Thị",
    "Điền Văn",
    "Mạt Thế",
    "Truyện Teen",
    "Nữ Phụ",
    "Light Novel",
    "Đoản Văn",
    "Hiện Đại",
    "Khác",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      /// 🔥 FIX nền theo theme
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          "Thể loại",
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),

      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 2.4,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CategoryDetailScreen(category: category),
                ),
              );
            },
            child: _buildItem(context, category),
          );
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, String category) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),

        /// 🔥 FIX gradient theo theme
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF5B4B8A),
                  const Color(0xFF3E2D6B),
                ]
              : [
                  const Color(0xFF9C7BFF),
                  const Color(0xFF6A5AE0),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
          )
        ],
      ),
      child: Stack(
        children: [
          /// ICON
          Positioned(
            right: 10,
            top: 10,
            child: Icon(
              Icons.menu_book,
              color: Colors.white.withOpacity(0.25),
              size: 34,
            ),
          ),

          /// TEXT
          Positioned(
            left: 12,
            bottom: 12,
            child: Text(
              category,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}