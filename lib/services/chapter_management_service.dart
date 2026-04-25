import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class ChapterManagementService {
  static final ChapterManagementService instance = ChapterManagementService._();
  ChapterManagementService._();

  final DatabaseService _dbService = DatabaseService.instance;

  /// 🔥 ADD CHAPTER
  Future<bool> addChapter({
    required String storyTitle,
    required String chapterTitle,
    required String link,
    required String content,
  }) async {
    try {
      final db = await _dbService.database;

      await db.insert(
        'chuong',
        {
          'ten_truyen': storyTitle,
          'ten_chuong': chapterTitle,
          'link': link,
          'noi_dung': content,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update số chương trong bảng truyen
      await _updateChapterCount(storyTitle);

      print('✅ Chapter added: $chapterTitle');
      return true;
    } catch (e) {
      print('❌ addChapter error: $e');
      return false;
    }
  }

  /// 🔥 UPDATE CHAPTER
  Future<bool> updateChapter({
    required String oldLink,
    required String storyTitle,
    required String chapterTitle,
    required String newLink,
    required String content,
  }) async {
    try {
      final db = await _dbService.database;

      await db.update(
        'chuong',
        {
          'ten_truyen': storyTitle,
          'ten_chuong': chapterTitle,
          'link': newLink,
          'noi_dung': content,
        },
        where: 'link = ?',
        whereArgs: [oldLink],
      );

      print('✅ Chapter updated: $chapterTitle');
      return true;
    } catch (e) {
      print('❌ updateChapter error: $e');
      return false;
    }
  }

  /// 🔥 DELETE CHAPTER
  Future<bool> deleteChapter(String link, String storyTitle) async {
    try {
      final db = await _dbService.database;

      await db.delete(
        'chuong',
        where: 'link = ?',
        whereArgs: [link],
      );

      // Update số chương
      await _updateChapterCount(storyTitle);

      print('✅ Chapter deleted: $link');
      return true;
    } catch (e) {
      print('❌ deleteChapter error: $e');
      return false;
    }
  }

  /// 🔥 GET CHAPTER BY LINK
  Future<Map<String, dynamic>?> getChapterByLink(String link) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'chuong',
        where: 'link = ?',
        whereArgs: [link],
      );

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      print('❌ getChapterByLink error: $e');
      return null;
    }
  }

  /// 🔥 UPDATE CHAPTER COUNT
  Future<void> _updateChapterCount(String storyTitle) async {
    try {
      final db = await _dbService.database;

      // Đếm số chương
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM chuong
        WHERE ten_truyen = ?
      ''', [storyTitle]);

      final count = result.first['count'] as int;

      // Update vào bảng truyen
      await db.update(
        'truyen',
        {'so_chuong': count.toString()},
        where: 'ten_truyen = ?',
        whereArgs: [storyTitle],
      );

      print('✅ Chapter count updated: $storyTitle = $count');
    } catch (e) {
      print('❌ _updateChapterCount error: $e');
    }
  }

  /// 🔥 GET CHAPTERS BY STORY
  Future<List<Map<String, dynamic>>> getChaptersByStory(String storyTitle) async {
    try {
      return await _dbService.getChapters(storyTitle);
    } catch (e) {
      print('❌ getChaptersByStory error: $e');
      return [];
    }
  }

  /// 🔥 CHECK IF CHAPTER EXISTS
  Future<bool> chapterExists(String link) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'chuong',
        where: 'link = ?',
        whereArgs: [link],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
