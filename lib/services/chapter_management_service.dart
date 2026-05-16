import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'firebase_service.dart';
import 'story_refresh_service.dart';

class ChapterManagementService {
  static final ChapterManagementService instance = ChapterManagementService._();
  ChapterManagementService._();

  final DatabaseService _dbService = DatabaseService.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // ─── ADD ──────────────────────────────────────────────────────────────────

  /// 🔥 Thêm chapter — lưu lên Firestore (truyện admin) hoặc SQLite (truyện crawl)
  Future<bool> addChapter({
    required String storyTitle,
    required String chapterTitle,
    required String link,
    required String content,
    bool saveToFirestore = true,
  }) async {
    try {
      if (saveToFirestore) {
        // Đếm số chương hiện có để tạo chapterNumber
        final existing = await _dbService.getChapters(storyTitle);
        final chapterNumber = existing.length + 1;

        final success = await _firebaseService.addChapter(
          storyTitle: storyTitle,
          chapterName: chapterTitle,
          content: content,
          link: link,
          chapterNumber: chapterNumber,
        );

        if (success) {
          // Cập nhật totalChapters trên document story
          await _firebaseService.updateChapterCount(
            storyTitle: storyTitle,
            count: chapterNumber,
          );
          _dbService.clearChapterCache(storyTitle);
          StoryRefreshService.instance.notifyChaptersChanged(storyTitle);
          debugPrint('✅ Chapter added to Firestore: $chapterTitle (#$chapterNumber)');
        }
        return success;
      }

      // Fallback: SQLite (truyện crawl cũ)
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
      await _updateSQLiteChapterCount(storyTitle);
      _dbService.clearChapterCache(storyTitle);
      StoryRefreshService.instance.notifyChaptersChanged(storyTitle);
      debugPrint('✅ Chapter added to SQLite: $chapterTitle');
      return true;
    } catch (e) {
      debugPrint('❌ addChapter error: $e');
      return false;
    }
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  /// 🔥 Cập nhật chapter — Firestore (có chapterDocId) hoặc SQLite (có oldLink)
  Future<bool> updateChapter({
    required String storyTitle,
    required String chapterTitle,
    required String content,
    String? chapterDocId, // Firestore document ID
    String? oldLink,      // SQLite legacy
    String? newLink,      // SQLite legacy
  }) async {
    try {
      if (chapterDocId != null) {
        // 🔥 Firestore path
        final success = await _firebaseService.updateChapter(
          storyTitle: storyTitle,
          chapterDocId: chapterDocId,
          chapterName: chapterTitle,
          content: content,
        );
        if (success) {
          _dbService.clearChapterCache(storyTitle);
          StoryRefreshService.instance.notifyChaptersChanged(storyTitle);
          debugPrint('✅ Chapter updated in Firestore: $chapterTitle');
        }
        return success;
      }

      // Fallback: SQLite
      final db = await _dbService.database;
      await db.update(
        'chuong',
        {
          'ten_truyen': storyTitle,
          'ten_chuong': chapterTitle,
          'link': newLink ?? oldLink,
          'noi_dung': content,
        },
        where: 'link = ?',
        whereArgs: [oldLink],
      );
      _dbService.clearChapterCache(storyTitle);
      StoryRefreshService.instance.notifyChaptersChanged(storyTitle);
      debugPrint('✅ Chapter updated in SQLite: $chapterTitle');
      return true;
    } catch (e) {
      debugPrint('❌ updateChapter error: $e');
      return false;
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  /// 🔥 Xóa chapter — Firestore (có chapterDocId) hoặc SQLite (có link)
  Future<bool> deleteChapter(
    String linkOrDocId,
    String storyTitle, {
    bool isFirestore = false,
  }) async {
    try {
      if (isFirestore) {
        final success = await _firebaseService.deleteChapter(
          storyTitle: storyTitle,
          chapterDocId: linkOrDocId,
        );
        if (success) {
          // Cập nhật lại totalChapters
          final remaining = await _dbService.getChapters(storyTitle);
          await _firebaseService.updateChapterCount(
            storyTitle: storyTitle,
            count: remaining.length,
          );
          _dbService.clearChapterCache(storyTitle);
          StoryRefreshService.instance.notifyChaptersChanged(storyTitle);
          debugPrint('✅ Chapter deleted from Firestore: $linkOrDocId');
        }
        return success;
      }

      // Fallback: SQLite
      final db = await _dbService.database;
      await db.delete(
        'chuong',
        where: 'link = ?',
        whereArgs: [linkOrDocId],
      );
      await _updateSQLiteChapterCount(storyTitle);
      _dbService.clearChapterCache(storyTitle);
      StoryRefreshService.instance.notifyChaptersChanged(storyTitle);
      debugPrint('✅ Chapter deleted from SQLite: $linkOrDocId');
      return true;
    } catch (e) {
      debugPrint('❌ deleteChapter error: $e');
      return false;
    }
  }

  // ─── READ ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getChaptersByStory(String storyTitle) async {
    try {
      return await _dbService.getChapters(storyTitle);
    } catch (e) {
      debugPrint('❌ getChaptersByStory error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getChapterByLink(String link) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'chuong',
        where: 'link = ?',
        whereArgs: [link],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('❌ getChapterByLink error: $e');
      return null;
    }
  }

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

  // ─── PRIVATE ──────────────────────────────────────────────────────────────

  Future<void> _updateSQLiteChapterCount(String storyTitle) async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chuong WHERE ten_truyen = ?',
        [storyTitle],
      );
      final count = result.first['count'] as int;
      await db.update(
        'truyen',
        {'so_chuong': count.toString()},
        where: 'ten_truyen = ?',
        whereArgs: [storyTitle],
      );
      debugPrint('✅ SQLite chapter count updated: $storyTitle = $count');
    } catch (e) {
      debugPrint('❌ _updateSQLiteChapterCount error: $e');
    }
  }
}
