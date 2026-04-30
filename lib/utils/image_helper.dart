import 'dart:io';
import 'package:flutter/widgets.dart';

class ImageHelper {
  /// 🔥 MAIN FUNCTION
  static Future<String> getImageFromStory({
    required String title,
    required String category,
    required String pathFromDb,
  }) async {
    try {
      /// ✅ 1. link online
      if (pathFromDb.isNotEmpty && pathFromDb.startsWith("http")) {
        return pathFromDb;
      }

      /// 🔥 2. Check if it's a local file path (from documents directory)
      if (pathFromDb.isNotEmpty && pathFromDb.startsWith("file://")) {
        return pathFromDb;
      }

      /// 🔥 3. FIX PATH DB
      if (pathFromDb.isNotEmpty) {
        String fixedPath = pathFromDb;

        /// "\" → "/"
        fixedPath = fixedPath.replaceAll("\\", "/");

        /// normalize
        fixedPath = _normalizePath(fixedPath);

        /// 🔥 thử nhiều định dạng
        final candidates = _getImageCandidates(fixedPath);

        for (final path in candidates) {
          final fullPath = "database/$path";

          print("🔍 TRY: $fullPath");

          /// ⚠️ Flutter không check file tồn tại runtime,
          /// nên ta trả lần lượt → widget sẽ fallback nếu lỗi
          return fullPath;
        }
      }

      /// 🔥 4. fallback theo title
      final folder = _normalize(category.split(',').first);
      final file = _normalize(title);

      final candidates =
          _getImageCandidates("images/$folder/$file");

      return "database/${candidates.first}";
    } catch (e) {
      print("❌ ERROR IMAGE: $e");
      return fallbackImage();
    }
  }

  /// 🔥 DANH SÁCH ĐỊNH DẠNG
  static List<String> _getImageCandidates(String basePath) {
    final base = basePath.replaceAll(
      RegExp(r'\.(jpg|png|jpeg|webp)$'),
      '',
    );

    return [
      "$base.jpg",
      "$base.png",
      "$base.jpeg",
      "$base.webp",
    ];
  }

  /// 🔥 NORMALIZE PATH
  static String _normalizePath(String path) {
    return _removeVietnamese(path)
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\/\.]'), '')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// 🔥 NORMALIZE TEXT
  static String _normalize(String text) {
    return _removeVietnamese(text)
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// 🔥 REMOVE VIETNAMESE
  static String _removeVietnamese(String str) {
    const map = {
      'á':'a','à':'a','ả':'a','ã':'a','ạ':'a',
      'ă':'a','ắ':'a','ằ':'a','ẳ':'a','ẵ':'a','ặ':'a',
      'â':'a','ấ':'a','ầ':'a','ẩ':'a','ẫ':'a','ậ':'a',
      'đ':'d',
      'é':'e','è':'e','ẻ':'e','ẽ':'e','ẹ':'e',
      'ê':'e','ế':'e','ề':'e','ể':'e','ễ':'e','ệ':'e',
      'í':'i','ì':'i','ỉ':'i','ĩ':'i','ị':'i',
      'ó':'o','ò':'o','ỏ':'o','õ':'o','ọ':'o',
      'ô':'o','ố':'o','ồ':'o','ổ':'o','ỗ':'o','ộ':'o',
      'ơ':'o','ớ':'o','ờ':'o','ở':'o','ỡ':'o','ợ':'o',
      'ú':'u','ù':'u','ủ':'u','ũ':'u','ụ':'u',
      'ư':'u','ứ':'u','ừ':'u','ử':'u','ữ':'u','ự':'u',
      'ý':'y','ỳ':'y','ỷ':'y','ỹ':'y','ỵ':'y',
    };

    String result = str.toLowerCase();

    map.forEach((k, v) {
      result = result.replaceAll(k, v);
    });

    return result;
  }

  /// 🔥 check network
  static bool isNetwork(String path) {
    return path.startsWith("http");
  }

  /// 🔥 check local file
  static bool isLocalFile(String path) {
    return path.startsWith("file://");
  }

  /// 🔥 get ImageProvider based on path type
  static ImageProvider getImageProvider(String path) {
    if (isNetwork(path)) {
      return NetworkImage(path);
    } else if (isLocalFile(path)) {
      // Remove file:// prefix to get actual file path
      final filePath = path.replaceFirst('file://', '');
      return FileImage(File(filePath));
    } else {
      return AssetImage(path);
    }
  }

  /// 🔥 fallback
  static String fallbackImage() {
    return "assets/images/app_icon.png";
  }
}