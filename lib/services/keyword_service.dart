import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/groq_config.dart';
import '../models/story_model.dart';
import 'database_service.dart';

/// 🔥 KeywordService - Tạo và quản lý keywords cho truyện bằng Groq AI
///
/// Service này sử dụng Groq AI để tự động tạo keywords từ thông tin truyện
/// và lưu trữ chúng trong Firestore để chatbot có thể tìm kiếm thông minh.
class KeywordService {
  static final KeywordService _instance = KeywordService._internal();
  factory KeywordService() => _instance;
  KeywordService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService.instance;

  /// 🔥 Tạo keywords từ thông tin truyện bằng Groq AI (bao gồm cả chapters)
  ///
  /// Sử dụng Groq AI để phân tích title, author, category, description
  /// và nội dung chapters để tạo ra danh sách keywords phù hợp cho tìm kiếm.
  ///
  /// Returns: List of keywords (lowercase, normalized)
  Future<List<String>> generateKeywords({
    required String title,
    required String author,
    required String category,
    required String description,
    String? storyId, // Giữ param để tương thích, nhưng dùng title để lấy chapters
  }) async {
    try {
      debugPrint('🤖 Generating keywords for: $title');

      // Lấy nội dung chapters bằng title gốc (SQLite dùng ten_truyen)
      String? chaptersContent;
      chaptersContent = await _getChaptersContent(title);

      // Tạo prompt cho Groq AI
      final prompt = _buildKeywordPrompt(
        title: title,
        author: author,
        category: category,
        description: description,
        chaptersContent: chaptersContent,
      );

      // Gọi Groq API
      final response = await _callGroqAPI(prompt);

      // Parse keywords từ response
      final keywords = _parseKeywordsFromResponse(response);

      // Thêm keywords cơ bản từ title, author, category
      final basicKeywords = _extractBasicKeywords(
        title: title,
        author: author,
        category: category,
      );

      // Kết hợp và loại bỏ trùng lặp
      final allKeywords = <String>{...keywords, ...basicKeywords}.toList();

      debugPrint('✅ Generated ${allKeywords.length} keywords: ${allKeywords.take(10).join(", ")}...');

      return allKeywords;
    } catch (e) {
      debugPrint('❌ generateKeywords error: $e');

      // Fallback: Tạo keywords cơ bản nếu Groq API lỗi
      return _extractBasicKeywords(
        title: title,
        author: author,
        category: category,
      );
    }
  }

  /// 🔥 Lưu keywords vào Firestore
  ///
  /// Path: stories/{storyId}/keywords (array field)
  Future<bool> saveKeywords({
    required String storyId,
    required List<String> keywords,
  }) async {
    try {
      debugPrint('💾 Saving ${keywords.length} keywords for: $storyId');

      await _firestore.collection('stories').doc(storyId).set({
        'keywords': keywords,
        'keywordsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Keywords saved successfully');
      return true;
    } catch (e) {
      debugPrint('❌ saveKeywords error: $e');
      return false;
    }
  }

  /// 🔥 Lấy keywords của một truyện
  Future<List<String>> getKeywords(String storyId) async {
    try {
      final doc = await _firestore.collection('stories').doc(storyId).get();

      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null || !data.containsKey('keywords')) return [];

      final keywords = data['keywords'];
      if (keywords is List) {
        return List<String>.from(keywords);
      }

      return [];
    } catch (e) {
      debugPrint('❌ getKeywords error: $e');
      return [];
    }
  }

  /// 🔥 Đồng bộ keywords cho tất cả truyện (chạy 1 lần hoặc định kỳ)
  Future<void> syncAllStories({
    Function(int current, int total)? onProgress,
  }) async {
    try {
      debugPrint('🔄 Starting keyword sync for all stories...');

      final allStories = await _dbService.getStories();
      debugPrint('📚 Found ${allStories.length} stories to process');

      int processed = 0;
      int success = 0;
      int failed = 0;

      for (var story in allStories) {
        processed++;

        try {
          final storyId = _normalizeId(story.title);

          final existingKeywords = await getKeywords(storyId);
          if (existingKeywords.isNotEmpty) {
            debugPrint('⏭️  Skipping "$storyId" (already has keywords)');
            success++;
            onProgress?.call(processed, allStories.length);
            continue;
          }

          final keywords = await generateKeywords(
            title: story.title,
            author: story.author,
            category: story.category,
            description: story.description,
            storyId: storyId,
          );

          final saved = await saveKeywords(
            storyId: storyId,
            keywords: keywords,
          );

          if (saved) {
            success++;
            debugPrint('✅ [$processed/${allStories.length}] Synced: $storyId');
          } else {
            failed++;
            debugPrint('❌ [$processed/${allStories.length}] Failed to save: $storyId');
          }

          onProgress?.call(processed, allStories.length);

          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          failed++;
          debugPrint('❌ Error processing story "${story.title}": $e');
        }
      }

      debugPrint('🎉 Keyword sync completed!');
      debugPrint('   Total: ${allStories.length}');
      debugPrint('   Success: $success');
      debugPrint('   Failed: $failed');
    } catch (e) {
      debugPrint('❌ syncAllStories error: $e');
      rethrow;
    }
  }

  /// 🔥 Đồng bộ keywords cho một truyện cụ thể
  Future<bool> syncStory(String storyTitle) async {
    try {
      debugPrint('🔄 Syncing keywords for: $storyTitle');

      final allStories = await _dbService.getStories();
      final story = allStories.firstWhere(
        (s) => s.title == storyTitle,
        orElse: () => Story(title: ''),
      );

      if (story.title.isEmpty) {
        debugPrint('❌ Story not found: $storyTitle');
        return false;
      }

      final storyId = _normalizeId(story.title);
      final keywords = await generateKeywords(
        title: story.title,
        author: story.author,
        category: story.category,
        description: story.description,
        storyId: storyId,
      );

      final saved = await saveKeywords(
        storyId: storyId,
        keywords: keywords,
      );

      if (saved) {
        debugPrint('✅ Keywords synced for: $storyTitle');
      }

      return saved;
    } catch (e) {
      debugPrint('❌ syncStory error: $e');
      return false;
    }
  }

  /// 🔥 Tự động tạo keywords khi thêm truyện mới
  Future<bool> autoGenerateKeywordsForNewStory(Story story) async {
    try {
      debugPrint('🆕 Auto-generating keywords for new story: ${story.title}');

      final storyId = _normalizeId(story.title);
      final keywords = await generateKeywords(
        title: story.title,
        author: story.author,
        category: story.category,
        description: story.description,
        storyId: storyId,
      );

      return await saveKeywords(
        storyId: storyId,
        keywords: keywords,
      );
    } catch (e) {
      debugPrint('❌ autoGenerateKeywordsForNewStory error: $e');
      return false;
    }
  }

  // ==================== PRIVATE HELPERS ====================

  /// Lấy nội dung chapters để phân tích
  Future<String?> _getChaptersContent(String storyTitle) async {
    try {
      debugPrint('📖 Getting chapters content for: $storyTitle');

      // Truyền title gốc (không normalize) để match với SQLite
      final chapters = await _dbService.getChapters(storyTitle);

      if (chapters.isEmpty) {
        debugPrint('⚠️  No chapters found for: $storyTitle');
        return null;
      }

      final selectedChapters = chapters.take(3).toList();

      final buffer = StringBuffer();
      for (var chapter in selectedChapters) {
        // Support cả SQLite format (noi_dung, ten_chuong) và Firestore format (content, chapterNumber)
        final content = (chapter['noi_dung'] ?? chapter['content'] ?? '') as String;
        final chapterName = (chapter['ten_chuong'] ?? chapter['chapterName'] ?? '') as String;
        final chapterNum = chapter['chapterNumber'] ?? '';
        final truncated = content.length > 1000
            ? content.substring(0, 1000)
            : content;

        buffer.writeln('Chương $chapterNum: $chapterName');
        buffer.writeln(truncated);
        buffer.writeln('---');
      }

      final chaptersContent = buffer.toString();
      debugPrint('✅ Got ${selectedChapters.length} chapters content (${chaptersContent.length} chars)');

      return chaptersContent;
    } catch (e) {
      debugPrint('❌ _getChaptersContent error: $e');
      return null;
    }
  }

  /// Build prompt cho Groq AI để tạo keywords
  String _buildKeywordPrompt({
    required String title,
    required String author,
    required String category,
    required String description,
    String? chaptersContent,
  }) {
    final buffer = StringBuffer();

    final shortDesc = description.length > 500
        ? '${description.substring(0, 500)}...'
        : description;

    buffer.writeln('''
Ban la mot chuyen gia phan tich truyen va tao tu khoa tim kiem.

Nhiem vu: Tao danh sach tu khoa (keywords) de nguoi dung co the tim kiem truyen nay.

Thong tin truyen:
- Ten truyen: $title
- Tac gia: $author
- The loai: $category
- Mo ta: $shortDesc
''');

    if (chaptersContent != null && chaptersContent.isNotEmpty) {
      buffer.writeln('''
Noi dung mot so chuong dau:
$chaptersContent

Hay phan tich noi dung chapters de tim them keywords ve:
- Tinh cach nhan vat chinh (ba dao, thong minh, lanh lung, hai huoc, etc.)
- Phong cach truyen (hai huoc, nghiem tuc, kich tinh, lang man, etc.)
- Yeu to dac biet (he thong, vang ngon tay, xuyen khong, trong sinh, etc.)
- Moi quan he (hau cung, don nu chinh, bromance, etc.)
- Boi canh (hien dai, co dai, tu tien, vong du, etc.)
''');
    }

    buffer.writeln('''
Yeu cau:
1. Tao 20-30 tu khoa lien quan den truyen
2. Bao gom: the loai, chu de, cam xuc, doi tuong nhan vat, boi canh, tinh cach nhan vat, phong cach truyen
3. Tu khoa phai viet thuong, khong dau
4. Moi tu khoa ngan gon (1-3 tu)
5. Tap trung vao keywords ma nguoi dung thuong tim kiem (vd: "main ba dao", "he thong", "xuyen khong", "hai huoc", etc.)
6. Tra ve CHI danh sach tu khoa, cach nhau boi dau phay

Vi du format tra ve:
tu tien, huyen huyen, tu luyen, thieu nien, hanh dong, phieu luu, kiem hiep, co dai, main ba dao, he thong, xuyen khong, trong sinh

Bay gio hay tao keywords cho truyen tren:
''');

    return buffer.toString();
  }

  /// Gọi Groq API để tạo keywords
  Future<String> _callGroqAPI(String prompt) async {
    if (!GroqConfig.isConfigured) {
      throw Exception('Groq API key not configured');
    }

    final response = await http.post(
      Uri.parse(GroqConfig.apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${GroqConfig.apiKey}',
      },
      body: jsonEncode({
        'model': GroqConfig.model,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final content = data['choices'][0]['message']['content'] as String;

    return content.trim();
  }

  /// Parse keywords từ response của Groq
  List<String> _parseKeywordsFromResponse(String response) {
    final String cleaned = response
        .replaceAll('\n', ' ')
        .replaceAll('  ', ' ')
        .trim();

    final keywords = cleaned
        .split(',')
        .map((k) => _normalizeText(k.trim()))
        .where((k) => k.isNotEmpty && k.length >= 2)
        .toList();

    return keywords;
  }

  /// Trích xuất keywords cơ bản từ title, author, category
  List<String> _extractBasicKeywords({
    required String title,
    required String author,
    required String category,
  }) {
    final keywords = <String>{};

    final titleWords = _normalizeText(title).split(' ');
    keywords.addAll(titleWords.where((w) => w.length >= 2));

    final authorWords = _normalizeText(author).split(' ');
    keywords.addAll(authorWords.where((w) => w.length >= 2));

    keywords.add(_normalizeText(category));

    final categoryKeywords = _getCategoryKeywords(category);
    keywords.addAll(categoryKeywords);

    return keywords.toList();
  }

  /// Lấy keywords liên quan đến thể loại
  List<String> _getCategoryKeywords(String category) {
    final normalized = _normalizeText(category);

    final categoryMap = <String, List<String>>{
      'tien hiep': ['tu tien', 'tu chan', 'huyen huyen', 'tu luyen', 'phi thien'],
      'kiem hiep': ['vo hiep', 'kiem', 'vo cong', 'giang ho', 'co dai'],
      'ngon tinh': ['tinh cam', 'lang man', 'hien dai', 'yeu duong'],
      'dam my': ['boys love', 'bl', 'tinh cam'],
      'bach hop': ['girls love', 'gl', 'tinh cam'],
      'quan truong': ['chinh tri', 'quyen luc', 'hien dai'],
      'huyen huyen': ['phep thuat', 'than thoai', 'huyen bi'],
      'khoa huyen': ['vien tuong', 'khoa hoc', 'tuong lai'],
      'vong du': ['game', 'ao', 'rpg', 'mmorpg'],
      'do thi': ['hien dai', 'thanh pho', 'doi thuong'],
      'lich su': ['co dai', 'trung quoc', 'lich su'],
      'trinh tham': ['bi an', 'giai ma', 'tham tu'],
      'xuyen khong': ['thoi gian', 'song song'],
      'trong sinh': ['tai sinh', 'hoi sinh', 'quay lai'],
    };

    return categoryMap[normalized] ?? [];
  }

  /// Normalize text (lowercase, remove accents, trim)
  String _normalizeText(String text) {
    const vietnameseMap = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
    };

    String normalized = text.trim().toLowerCase();

    vietnameseMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    return normalized;
  }

  /// Normalize ID (giống FirebaseService)
  String _normalizeId(String text) {
    String normalized = _normalizeText(text);

    normalized = normalized
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    return normalized;
  }
}
