import '../models/story_model.dart';
import 'database_service.dart';

class RecommendationService {
  static final RecommendationService instance = RecommendationService._();
  RecommendationService._();

  final DatabaseService _db = DatabaseService.instance;

  /// 🔥 GET RECOMMENDED STORIES
  Future<List<Story>> getRecommendedStories(List<String> favoriteCategories) async {
    try {
      // Lấy tất cả truyện
      final allStories = await _db.getStories();
      
      // Filter theo thể loại yêu thích
      final recommended = allStories.where((story) {
        // Check nếu thể loại của truyện match với favorite
        for (final favCat in favoriteCategories) {
          if (story.category.toLowerCase().contains(favCat.toLowerCase())) {
            return true;
          }
        }
        return false;
      }).toList();
      
      // Shuffle để random
      recommended.shuffle();
      
      // Lấy top 20
      return recommended.take(20).toList();
    } catch (e) {
      print('❌ getRecommendedStories error: $e');
      return [];
    }
  }

  /// 🔥 GET STORIES BY CATEGORY
  Future<List<Story>> getStoriesByCategory(String category) async {
    try {
      final allStories = await _db.getStories();
      
      return allStories.where((story) {
        return story.category.toLowerCase().contains(category.toLowerCase());
      }).toList();
    } catch (e) {
      print('❌ getStoriesByCategory error: $e');
      return [];
    }
  }

  /// 🔥 GET TRENDING STORIES (most purchased/viewed)
  Future<List<Story>> getTrendingStories() async {
    try {
      final allStories = await _db.getStories();
      
      // TODO: Sort by purchase count or view count
      // For now, just return random
      allStories.shuffle();
      
      return allStories.take(10).toList();
    } catch (e) {
      print('❌ getTrendingStories error: $e');
      return [];
    }
  }
}
