import 'package:flutter/material.dart';
import 'category_detail_screen.dart';

class ExploreCategoryScreen extends StatelessWidget {
  const ExploreCategoryScreen({super.key});

  /// 🔥 CATEGORY CHUẨN (theo data của bạn)
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Thể loại"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),

                /// 🔥 gradient cho đẹp (thay vì ảnh fake)
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade300,
                    Colors.deepPurple.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),

              child: Stack(
                children: [
                  /// ICON
                  const Positioned(
                    right: 10,
                    top: 10,
                    child: Icon(
                      Icons.menu_book,
                      color: Colors.white24,
                      size: 40,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}