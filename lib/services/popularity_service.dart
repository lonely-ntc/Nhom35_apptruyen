import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';

class PopularityService {
  static final PopularityService instance = PopularityService._init();
  PopularityService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache
  List<Story>? _cachedPopular;
  DateTime? _lastCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  bool _isCacheValid() {
    if (_lastCacheTime == null || _cachedPopular == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheDuration;
  }

  void clearCache() {
    _cachedPopular = null;
    _lastCacheTime = null;
  }

  /// 🔥 Lấy truyện phổ biến dựa trên rating từ Firebase
  ///
  /// Chiến lược:
  /// 1. Dùng collectionGroup('ratings') để lấy TẤT CẢ ratings 1 lần
  /// 2. Gom theo storyId (= story.title — document ID của ratings parent)
  /// 3. Match với allStories bằng title gốc
  Future<List<Story>> getPopularStories(
    List<Story> allStories, {
    int limit = 5,
  }) async {
    if (_isCacheValid()) {
      print('📦 Using cached popular stories');
      return _cachedPopular!;
    }

    try {
      print('📊 Loading popular stories via collectionGroup...');

      // Bước 1: Lấy tất cả ratings 1 lần duy nhất
      QuerySnapshot allRatings;
      try {
        allRatings = await _firestore
            .collectionGroup('ratings')
            .get()
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        print('⚠️ collectionGroup failed ($e), falling back to per-story query');
        return await _getPopularStoriesFallback(allStories, limit: limit);
      }

      print('📊 Total rating docs: ${allRatings.docs.length}');

      if (allRatings.docs.isEmpty) {
        print('⚠️ No ratings found in Firebase');
        return [];
      }

      // Bước 2: Gom ratings theo storyId
      // Path: stories/{storyId}/ratings/{userId}
      // storyId = story.title (title gốc, có thể là tiếng Việt)
      final Map<String, List<double>> ratingsByStory = {};

      for (var doc in allRatings.docs) {
        final segments = doc.reference.path.split('/');
        // Đảm bảo đúng cấu trúc: stories / storyId / ratings / userId
        if (segments.length == 4 &&
            segments[0] == 'stories' &&
            segments[2] == 'ratings') {
          final storyId = segments[1];
          final rating = (doc.data() as Map<String, dynamic>)['rating'];
          final ratingValue = (rating as num?)?.toDouble() ?? 0;
          if (ratingValue > 0) {
            ratingsByStory.putIfAbsent(storyId, () => []).add(ratingValue);
          }
        }
      }

      print('📚 Unique stories with ratings: ${ratingsByStory.length}');
      ratingsByStory.forEach((id, ratings) {
        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        print('  ⭐ "$id": avg=${avg.toStringAsFixed(2)}, count=${ratings.length}');
      });

      if (ratingsByStory.isEmpty) {
        print('⚠️ No valid ratings found');
        return [];
      }

      // Bước 3: Match với allStories
      // storyId trong Firestore = story.title (title gốc)
      final List<Map<String, dynamic>> scored = [];

      // Tạo lookup map để tìm nhanh
      final storyByTitle = <String, Story>{};
      for (var s in allStories) {
        storyByTitle[s.title] = s;
      }

      ratingsByStory.forEach((storyId, ratings) {
        Story? story = storyByTitle[storyId];

        if (story != null) {
          final count = ratings.length;
          final avg = ratings.reduce((a, b) => a + b) / count;
          scored.add({'story': story, 'avg': avg, 'count': count});
          print('  ✅ Matched: "${story.title}" avg=$avg count=$count');
        } else {
          print('  ❌ No match for storyId: "$storyId"');
        }
      });

      print('✅ Matched ${scored.length}/${ratingsByStory.length} stories');

      if (scored.isEmpty) {
        print('⚠️ No stories matched. Check if story titles match Firestore document IDs');
        print('   Firestore IDs: ${ratingsByStory.keys.take(5).toList()}');
        print('   Local titles (first 5): ${allStories.take(5).map((s) => s.title).toList()}');
        return [];
      }

      // Bước 4: Sắp xếp avg cao → thấp
      scored.sort((a, b) {
        final avgCmp = (b['avg'] as double).compareTo(a['avg'] as double);
        if (avgCmp != 0) return avgCmp;
        return (b['count'] as int).compareTo(a['count'] as int);
      });

      print('🏆 Top ${scored.length > limit ? limit : scored.length} popular stories:');
      for (var i = 0; i < scored.length && i < limit; i++) {
        final item = scored[i];
        print(
          '  ${i + 1}. ${(item['story'] as Story).title} '
          '- avg: ${(item['avg'] as double).toStringAsFixed(2)}, '
          'count: ${item['count']}',
        );
      }

      final result = scored.take(limit).map((e) => e['story'] as Story).toList();
      _cachedPopular = result;
      _lastCacheTime = DateTime.now();
      return result;
    } on TimeoutException {
      print('⏱️ Timeout getting popular stories');
      return [];
    } catch (e) {
      print('❌ getPopularStories error: $e');
      return [];
    }
  }

  /// 🔄 Fallback: query từng story một (dùng khi collectionGroup không có index)
  Future<List<Story>> _getPopularStoriesFallback(
    List<Story> allStories, {
    int limit = 5,
  }) async {
    print('🔄 Using fallback: querying each story individually...');
    final List<Map<String, dynamic>> scored = [];

    // Chỉ query 20 story đầu để tránh quá chậm
    final storiesToCheck = allStories.take(50).toList();

    final futures = storiesToCheck.map((story) async {
      try {
        final snapshot = await _firestore
            .collection('stories')
            .doc(story.title)
            .collection('ratings')
            .get()
            .timeout(const Duration(seconds: 3));

        if (snapshot.docs.isEmpty) return null;

        double total = 0;
        for (var doc in snapshot.docs) {
          total += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
        }
        final count = snapshot.docs.length;
        return {'story': story, 'avg': total / count, 'count': count};
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(futures);
    for (var r in results) {
      if (r != null) scored.add(r);
    }

    scored.sort((a, b) {
      final avgCmp = (b['avg'] as double).compareTo(a['avg'] as double);
      if (avgCmp != 0) return avgCmp;
      return (b['count'] as int).compareTo(a['count'] as int);
    });

    final result = scored.take(limit).map((e) => e['story'] as Story).toList();
    _cachedPopular = result;
    _lastCacheTime = DateTime.now();
    return result;
  }

  /// ⭐ Lấy thống kê rating của 1 truyện
  Future<Map<String, dynamic>> getStoryStats(String storyTitle) async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .doc(storyTitle)
          .collection('ratings')
          .get();

      if (snapshot.docs.isEmpty) {
        return {'avgRating': 0.0, 'ratingCount': 0};
      }

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
      }
      final count = snapshot.docs.length;
      return {'avgRating': total / count, 'ratingCount': count};
    } catch (e) {
      print('❌ getStoryStats error: $e');
      return {'avgRating': 0.0, 'ratingCount': 0};
    }
  }

  /// 🔥 Stream rating realtime cho 1 truyện
  Stream<Map<String, dynamic>> streamStoryRating(String storyTitle) {
    return _firestore
        .collection('stories')
        .doc(storyTitle)
        .collection('ratings')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return {'avgRating': 0.0, 'ratingCount': 0};
      }
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
      }
      final count = snapshot.docs.length;
      return {'avgRating': total / count, 'ratingCount': count};
    });
  }
}
