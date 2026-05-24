import 'package:flutter/foundation.dart';
import '../models/story_model.dart';
import 'firebase_service.dart';
import 'database_service.dart';
import 'story_refresh_service.dart';

class StoryManagementService {
  static final StoryManagementService instance = StoryManagementService._();
  StoryManagementService._();

  final FirebaseService _firebaseService = FirebaseService();

  /// 🔥 ADD STORY (NOW SAVES TO FIRESTORE)
  Future<bool> addStory({
    required String title,
    required String author,
    required String category,
    required String status,
    required String totalChapters,
    required String description,
    required String imagePath,
    bool isFree = true,
    double price = 0.0,
  }) async {
    try {
      final success = await _firebaseService.addStory(
        title: title,
        author: author,
        category: category,
        status: status,
        totalChapters: totalChapters,
        description: description,
        imageUrl: imagePath,
        isFree: isFree,
        price: price,
      );

      if (success) {
        // 🔥 Xóa cache để lần sau getStories() lấy dữ liệu mới
        DatabaseService.instance.clearCache();
        // 🔥 Thông báo cho các screen biết có truyện mới
        StoryRefreshService.instance.notifyStoriesChanged();
        print('✅ Story added to Firestore: $title');
      }

      return success;
    } catch (e) {
      print('❌ addStory error: $e');
      return false;
    }
  }

  /// 🔥 UPDATE STORY → luôn lưu lên Firestore
  /// - Nếu đã có trong Firestore → update
  /// - Nếu chưa có (truyện SQLite chưa được sync) → tạo mới trên Firestore
  /// - App và admin đều đọc Firestore version sau khi update
  Future<bool> updateStory({
    required String oldTitle,
    required String newTitle,
    required String author,
    required String category,
    required String status,
    required String totalChapters,
    required String description,
    String? imagePath,       // null = giữ nguyên ảnh cũ
    bool? isFree,
    double? price,
    String? existingImageUrl, // ảnh gốc từ story (dùng khi tạo mới trên Firestore)
  }) async {
    try {
      debugPrint('🔄 Saving story to Firestore: $oldTitle → $newTitle');
      final resolvedImagePath = imagePath ?? existingImageUrl ?? '';

      final existsInFirestore = await _firebaseService.storyExists(oldTitle);
      bool firestoreSuccess;

      if (existsInFirestore) {
        // Đã có trên Firestore → update, imageUrl null = giữ nguyên
        debugPrint('   Updating existing Firestore document...');
        firestoreSuccess = await _firebaseService.updateStory(
          oldTitle: oldTitle,
          newTitle: newTitle,
          author: author,
          category: category,
          status: status,
          totalChapters: totalChapters,
          description: description,
          imageUrl: imagePath, // null = không ghi đè imageUrl cũ
          isFree: isFree,
          price: price,
        );
      } else {
        // Chưa có trên Firestore (truyện SQLite) → tạo mới
        // Dùng ảnh mới nếu có, không thì dùng ảnh gốc từ SQLite
        debugPrint('   Creating new Firestore document (imageUrl: $resolvedImagePath)...');
        firestoreSuccess = await _firebaseService.addStory(
          title: newTitle,
          author: author,
          category: category,
          status: status,
          totalChapters: totalChapters,
          description: description,
          imageUrl: resolvedImagePath,
          isFree: isFree ?? true,
          price: price ?? 0.0,
        );
      }

      if (!firestoreSuccess) {
        debugPrint('❌ Failed to save story to Firestore');
        return false;
      }

      final sqliteSuccess = await DatabaseService.instance.updateStoryInSQLite(
        oldTitle: oldTitle,
        newTitle: newTitle,
        author: author,
        category: category,
        status: status,
        totalChapters: totalChapters,
        description: description,
        imagePath: resolvedImagePath,
        isFree: isFree,
        price: price,
      );

      if (sqliteSuccess) {
        debugPrint('✅ Story saved to Firestore: $newTitle');
        debugPrint('✅ Story synced to SQLite: $newTitle');
        DatabaseService.instance.clearCache();
        StoryRefreshService.instance.notifyStoriesChanged();
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        debugPrint('❌ Failed to sync story to SQLite');
      }

      return sqliteSuccess;
    } catch (e) {
      debugPrint('❌ updateStory error: $e');
      return false;
    }
  }

  /// 🔥 GET STORY BY TITLE (NOW FROM FIRESTORE)
  Future<Story?> getStoryByTitle(String title) async {
    try {
      return await DatabaseService.instance.getStoryByTitle(title);
    } catch (e) {
      print('❌ getStoryByTitle error: $e');
      return null;
    }
  }

  /// 🔥 DELETE STORY (NOW DELETES FROM FIRESTORE)
  Future<bool> deleteStory(String title) async {
    try {
      final success = await _firebaseService.deleteStory(title);

      if (success) {
        // 🔥 Xóa cache
        DatabaseService.instance.clearCache();
        // 🔥 Thông báo cho các screen biết có truyện bị xóa
        StoryRefreshService.instance.notifyStoriesChanged();
        print('✅ Story deleted from Firestore: $title');
      }

      return success;
    } catch (e) {
      print('❌ deleteStory error: $e');
      return false;
    }
  }

  /// 🔥 ADD CHAPTER (NOW SAVES TO FIRESTORE)
  Future<bool> addChapter({
    required String storyTitle,
    required String chapterName,
    required String content,
    required String link,
    required int chapterNumber,
  }) async {
    try {
      final success = await _firebaseService.addChapter(
        storyTitle: storyTitle,
        chapterName: chapterName,
        content: content,
        link: link,
        chapterNumber: chapterNumber,
      );

      if (success) {
        // 🔥 Xóa cache chapters
        DatabaseService.instance.clearCache();
        print('✅ Chapter added to Firestore: $chapterName');
      }

      return success;
    } catch (e) {
      print('❌ addChapter error: $e');
      return false;
    }
  }
}
