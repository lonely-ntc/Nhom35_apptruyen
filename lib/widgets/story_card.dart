import 'package:flutter/material.dart';

import '../models/story_model.dart';
import '../screens/home/story_detail_screen.dart';

class StoryCard extends StatelessWidget {
  final Story story;

  const StoryCard({super.key, required this.story});

  /// 🔥 build danh sách path ảnh (FIX CHUẨN)
  List<String> getImagePaths() {
    if (story.image.isEmpty) return [];

    /// ✅ FIX 1: chỉ replace "\" → "/"
    String path = story.image.replaceAll("\\", "/").trim();

    /// ❌ BỎ: không xóa extension nữa

    /// ✅ FIX 2: thêm prefix
    final fullPath = "assets/database/$path";

    return [fullPath];
  }

  /// 🔥 LOAD ẢNH
  Widget buildImage() {
    final paths = getImagePaths();

    if (paths.isEmpty) {
      return _placeholder();
    }

    return _buildImage(paths[0]);
  }

  /// 🔥 LOAD ẢNH + FIX TOÀN BỘ TRƯỜNG HỢP
  Widget _buildImage(String path) {
    return SizedBox.expand(
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          /// 🔥 FIX 1: đổi sang .jpg
          String fixedPath = path
              .replaceAll(".png", ".jpg")
              .replaceAll(".webp", ".jpg")
              .replaceAll(".jpeg", ".jpg");

          /// 🔥 FIX 2: đổi "_" → "-"
          fixedPath = fixedPath.replaceAll("_", "-");

          return Image.asset(
            fixedPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              /// 🔥 FIX 3: thử ngược "-" → "_"
              String altPath = path
                  .replaceAll("-", "_")
                  .replaceAll(".png", ".jpg")
                  .replaceAll(".webp", ".jpg")
                  .replaceAll(".jpeg", ".jpg");

              return Image.asset(
                altPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _placeholder();
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 📌 fallback
  Widget _placeholder() {
    return SizedBox.expand(
      child: Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.broken_image, size: 40),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryDetailScreen(story: story),
          ),
        );
      },
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: buildImage(),
                    ),

                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.85),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Text(
                        story.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "NEW",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),

                    if (story.totalChapters.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${story.totalChapters} chương",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Chap ${story.totalChapters}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}