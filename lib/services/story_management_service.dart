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

  /// 🔥 UPDATE STORY (NOW UPDATES FIRESTORE)
  Future<bool> updateStory({
    required String oldTitle,
    required String newTitle,
    required String author,
    required String category,
    required String status,
    required String totalChapters,
    required String description,
    String? imagePath,
    bool? isFree,
    double? price,
  }) async {
    try {
      final success = await _firebaseService.updateStory(
        oldTitle: oldTitle,
        newTitle: newTitle,
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
        // 🔥 Xóa cache
        DatabaseService.instance.clearCache();
        // 🔥 Thông báo cho các screen biết có truyện thay đổi
        StoryRefreshService.instance.notifyStoriesChanged();
        print('✅ Story updated in Firestore: $oldTitle → $newTitle');
      }

      return success;
    } catch (e) {
      print('❌ updateStory error: $e');
      return false;
    }
  }

  /// 🔥 GET STORY BY TITLE (NOW FROM FIRESTORE)
  Future<Story?> getStoryByTitle(String title) async {
    try {
      final storyData = await _firebaseService.getStoryByTitle(title);
      if (storyData != null) {
        return Story.fromFirestore(storyData);
      }
      return null;
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