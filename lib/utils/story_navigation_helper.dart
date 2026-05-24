import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../services/database_service.dart';
import '../screens/home/story_detail_screen.dart';

/// 🔥 Helper để navigate đến Story Detail với latest data
class StoryNavigationHelper {
  /// Navigate đến Story Detail Screen với latest story data
  /// Load từ database (merge SQLite + Firestore) trước khi navigate
  static Future<void> navigateToStoryDetail(
    BuildContext context,
    Story story,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 🔥 Load latest story data từ database
      DatabaseService.instance.clearCache();
      final allStories = await DatabaseService.instance.getStories();
      
      // Tìm story với title khớp
      final latestStory = allStories.firstWhere(
        (s) => s.title.toLowerCase().trim() == story.title.toLowerCase().trim(),
        orElse: () => story, // Fallback to original story if not found
      );

      if (!context.mounted) return;

      // Close loading
      Navigator.pop(context);

      // Navigate với latest story
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryDetailScreen(story: latestStory),
        ),
      );
    } catch (e) {
      debugPrint('❌ navigateToStoryDetail error: $e');
      
      if (!context.mounted) return;

      // Close loading
      Navigator.pop(context);

      // Navigate với original story nếu có lỗi
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryDetailScreen(story: story),
        ),
      );
    }
  }
}
