import 'package:flutter/material.dart';
import '../../services/sqlite_service.dart';

class AdminStoryScreen extends StatefulWidget {
  const AdminStoryScreen({super.key});

  @override
  State<AdminStoryScreen> createState() => _AdminStoryScreenState();
}

class _AdminStoryScreenState extends State<AdminStoryScreen> {
  final db = SQLiteService.instance;

  List stories = [];

  @override
  void initState() {
    super.initState();
    loadStories();
  }

  Future<void> loadStories() async {
    stories = await db.getStories();
    setState(() {});
  }

  /// 🔥 LẤY THỂ LOẠI CHÍNH (cái đầu tiên)
  String getMainCategory(String input) {
    if (input.isEmpty) return "khac";
    return normalizeCategory(input.split(",").first.trim());
  }

  /// 🔥 CHUẨN HÓA TÊN FOLDER
  String normalizeCategory(String input) {
    String result = input.toLowerCase();

    result = result
        .replaceAll("đ", "d")
        .replaceAll("á", "a")
        .replaceAll("à", "a")
        .replaceAll("ả", "a")
        .replaceAll("ã", "a")
        .replaceAll("ạ", "a")
        .replaceAll("ă", "a")
        .replaceAll("â", "a")
        .replaceAll("é", "e")
        .replaceAll("è", "e")
        .replaceAll("ê", "e")
        .replaceAll("ó", "o")
        .replaceAll("ò", "o")
        .replaceAll("ô", "o")
        .replaceAll("ơ", "o")
        .replaceAll("ú", "u")
        .replaceAll("ù", "u")
        .replaceAll("ư", "u")
        .replaceAll("í", "i")
        .replaceAll("ì", "i")
        .replaceAll("ý", "y")
        .replaceAll("ỳ", "y")
        .replaceAll(" ", "_");

    return result;
  }

  /// 🔥 LẤY TÊN FILE ẢNH (LOẠI BỎ "images\\")
  String getImageName(String path) {
    if (path.isEmpty) return "";
    return path
        .replaceAll("images\\", "")
        .replaceAll("images/", "")
        .split("\\")
        .last
        .split("/")
        .last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý truyện"),
      ),
      body: stories.isEmpty
          ? const Center(child: Text("Chưa có truyện"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final e = stories[index];

                /// 🔥 FIX CATEGORY
                final folder = getMainCategory(e["the_loai"] ?? "");

                /// 🔥 FIX IMAGE NAME
                final imageName =
                    getImageName(e["duong_dan_anh"] ?? "");

                /// 🔥 FINAL PATH
                final imagePath =
                    "assets/database/images/$folder/$imageName";

                /// DEBUG
                // ignore: avoid_print
                print(imagePath);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 110,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /// 🔥 IMAGE
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                        child: Image.asset(
                          imagePath,
                          width: 85,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 85,
                              height: 110,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// TEXT
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e["ten_truyen"] ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${e["tac_gia"] ?? ""} - ${e["the_loai"] ?? ""}",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}