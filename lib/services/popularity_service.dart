import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';

class PopularityService {
  static final PopularityService instance = PopularityService._init();
  PopularityService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache để tránh tính toán lại
  Map<String, Map<String, dynamic>> _ratingCache = {};
  DateTime? _lastCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// 🔥 GET POPULAR STORIES - OPTIMIZED VERSION
  /// Chỉ dựa trên đánh giá cao (nhanh hơn, đơn giản hơn)
  /// Tính toán song song để tăng tốc
  Future<List<Story>> getPopularStories(List<Story> allStories, {int limit = 10}) async {
    try {
      // Tính điểm cho tất cả truyện SONG SONG
      final futures = allStories.map((story) async {
        final ratingInfo = await _getRatingInfo(story.title);
        final avgRating = ratingInfo['average'] as double;
        final ratingCount = ratingInfo['count'] as int;

        // Score = avgRating * 20 + ratingCount * 0.5
        final score = (avgRating * 20) + (ratingCount * 0.5);

        return {
          'story': story,
          'score': score,
          'avgRating': avgRating,
          'ratingCount': ratingCount,
        };
      }).toList();

      // Chờ tất cả futures hoàn thành song song
      final storyScores = await Future.wait(futures);

      // Sắp xếp theo điểm giảm dần
      storyScores.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // Lấy top stories
      final topStories = storyScores
          .take(limit)
          .map((item) => item['story'] as Story)
          .toList();

      return topStories;
    } catch (e) {
      print('❌ getPopularStories error: $e');
      // Fallback: return first stories
      return allStories.take(limit).toList();
    }
  }

  /// ⭐ GET RATING INFO - OPTIMIZED WITH CACHE
  /// Lấy điểm trung bình và số lượng đánh giá
  Future<Map<String, dynamic>> _getRatingInfo(String storyTitle) async {
    try {
      // Kiểm tra cache
      if (_isCacheValid() && _ratingCache.containsKey(storyTitle)) {
        return _ratingCache[storyTitle]!;
      }

      // Sanitize story title để tránh lỗi document path
      final sanitizedTitle = _sanitizeDocumentId(storyTitle);

      final ratingsSnapshot = await _firestore
          .collection('stories')
          .doc(sanitizedTitle)
          .collection('ratings')
          .get();

      Map<String, dynamic> result;
      
      if (ratingsSnapshot.docs.isEmpty) {
        result = {'average': 0.0, 'count': 0};
      } else {
        int totalRating = 0;
        int count = ratingsSnapshot.docs.length;

        for (var doc in ratingsSnapshot.docs) {
          totalRating += (doc.data()['rating'] as int? ?? 0);
        }

        final average = count > 0 ? totalRating / count : 0.0;

        result = {
          'average': average,
          'count': count,
        };
      }

      // Lưu vào cache
      _ratingCache[storyTitle] = result;
      _lastCacheTime ??= DateTime.now();

      return result;
    } catch (e) {
      print('❌ _getRatingInfo error for "$storyTitle": $e');
      return {'average': 0.0, 'count': 0};
    }
  }

  /// 🔍 CHECK IF CACHE IS VALID
  bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheDuration;
  }

  /// 🗑️ CLEAR CACHE
  void clearCache() {
    _ratingCache.clear();
    _lastCacheTime = null;
  }

  /// 🔧 SANITIZE DOCUMENT ID
  /// Xóa ký tự đặc biệt và khoảng trắng thừa
  String _sanitizeDocumentId(String id) {
    // Trim khoảng trắng đầu cuối
    String sanitized = id.trim();
    
    // Thay thế nhiều khoảng trắng liên tiếp bằng 1 khoảng trắng
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    return sanitized;
  }

  /// 🔥 GET STORY STATS (for display)
  Future<Map<String, dynamic>> getStoryStats(String storyTitle) async {
    try {
      final ratingInfo = await _getRatingInfo(storyTitle);

      return {
        'avgRating': ratingInfo['average'],
        'ratingCount': ratingInfo['count'],
      };
    } catch (e) {
      print('❌ getStoryStats error: $e');
      return {
        'avgRating': 0.0,
        'ratingCount': 0,
      };
    }
  }
}
