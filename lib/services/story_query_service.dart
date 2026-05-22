import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story_model.dart';
import 'database_service.dart';
import 'keyword_service.dart';

/// 🔥 StoryQueryService - Truy vấn và lọc truyện dựa trên tiêu chí
///
/// Tối ưu hiệu năng:
/// - Batch tất cả Firestore reads song song (Future.wait)
/// - In-memory cache cho keywords, ratings, dates
/// - Giới hạn trước khi sort để tránh query thừa
class StoryQueryService {
  static final StoryQueryService _instance = StoryQueryService._internal();
  factory StoryQueryService() => _instance;
  StoryQueryService._internal();

  final DatabaseService _dbService = DatabaseService.instance;
  final KeywordService _keywordService = KeywordService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── In-memory cache ──────────────────────────────────────────────────────
  // keywords cache: storyId → List<String>
  final Map<String, List<String>> _keywordsCache = {};
  // ratings cache: storyId → double
  final Map<String, double> _ratingsCache = {};
  // dates cache: storyId → DateTime
  final Map<String, DateTime> _datesCache = {};

  static const Duration _cacheLifetime = Duration(minutes: 10);
  DateTime? _keywordsCacheTime;
  DateTime? _ratingsCacheTime;

  void clearCache() {
    _keywordsCache.clear();
    _ratingsCache.clear();
    _datesCache.clear();
    _keywordsCacheTime = null;
    _ratingsCacheTime = null;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<List<Story>> queryStories({
    List<String>? keywords,
    String? category,
    bool? isFree,
    String? status,
    String? sortBy,
    int limit = 10,
  }) async {
    try {
      debugPrint('🔍 Querying stories | kw=$keywords cat=$category free=$isFree sort=$sortBy limit=$limit');

      // 1. Lấy tất cả truyện (đã có cache trong DatabaseService)
      List<Story> stories = await _dbService.getStories();
      debugPrint('📚 Total stories: ${stories.length}');

      // 2. Lọc nhanh (không cần Firestore) trước để giảm tập dữ liệu
      if (category != null && category.isNotEmpty) {
        stories = _filterByCategory(stories, category);
        debugPrint('📂 After category filter: ${stories.length}');
      }
      if (isFree != null) {
        stories = _filterByPrice(stories, isFree);
        debugPrint('💰 After price filter: ${stories.length}');
      }
      if (status != null && status.isNotEmpty) {
        stories = _filterByStatus(stories, status);
        debugPrint('📊 After status filter: ${stories.length}');
      }

      // 3. Tìm kiếm theo keywords (batch Firestore)
      if (keywords != null && keywords.isNotEmpty) {
        stories = await _filterByKeywords(stories, keywords);
        debugPrint('🔎 After keyword filter: ${stories.length}');
      }

      // 4. Sắp xếp (batch Firestore nếu cần)
      if (sortBy != null && sortBy.isNotEmpty) {
        stories = await _sortStories(stories, sortBy);
        debugPrint('🔢 After sort by $sortBy');
      }

      // 5. Giới hạn kết quả
      if (stories.length > limit) {
        stories = stories.take(limit).toList();
      }

      debugPrint('✅ Query done: ${stories.length} stories');
      return stories;
    } catch (e) {
      debugPrint('❌ queryStories error: $e');
      return [];
    }
  }

  // ── Keyword filter ────────────────────────────────────────────────────────

  Future<List<Story>> _filterByKeywords(
    List<Story> stories,
    List<String> queryKeywords,
  ) async {
    final normalizedQuery = queryKeywords
        .map(_normalizeText)
        .where((k) => k.isNotEmpty)
        .toList();
    if (normalizedQuery.isEmpty) return stories;

    // Bước 1: Tính score nhanh chỉ dựa vào title/author/category (không cần Firestore)
    // → lọc sơ bộ để giảm số lượng cần fetch keywords từ Firestore
    final quickScores = <Story, double>{};
    for (final story in stories) {
      final s = _quickScore(story, normalizedQuery);
      quickScores[story] = s;
    }

    // Lấy top 50 theo quick score để fetch keywords (tránh fetch toàn bộ)
    final candidates = quickScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCandidates = candidates.take(50).map((e) => e.key).toList();

    // Bước 2: Batch fetch keywords cho top candidates song song
    final bool cacheExpired = _keywordsCacheTime == null ||
        DateTime.now().difference(_keywordsCacheTime!) > _cacheLifetime;

    if (cacheExpired) {
      _keywordsCache.clear();
      _keywordsCacheTime = DateTime.now();
    }

    final toFetch = topCandidates
        .where((s) => !_keywordsCache.containsKey(_normalizeId(s.title)))
        .toList();

    if (toFetch.isNotEmpty) {
      debugPrint('🌐 Batch fetching keywords for ${toFetch.length} stories...');
      // Parallel fetch — tất cả cùng lúc
      final futures = toFetch.map((story) async {
        final id = _normalizeId(story.title);
        final kws = await _keywordService.getKeywords(id);
        _keywordsCache[id] = kws;
      });
      await Future.wait(futures);
      debugPrint('✅ Keywords fetched');
    }

    // Bước 3: Tính full score với keywords từ cache
    final finalScores = <Story, double>{};
    for (final story in topCandidates) {
      final id = _normalizeId(story.title);
      final storyKws = _keywordsCache[id] ?? [];
      final kws = storyKws.isNotEmpty ? storyKws : _extractBasicKeywords(story);
      final score = _scoreWithKeywords(story, normalizedQuery, kws);
      if (score > 0) finalScores[story] = score;
    }

    // Với các story không nằm trong top candidates, dùng quick score
    for (final entry in candidates.skip(50)) {
      final s = entry.value;
      if (s > 0) finalScores[entry.key] = s;
    }

    final sorted = finalScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => e.key).toList();
  }

  /// Score nhanh chỉ dựa vào title/author/category (không cần Firestore)
  double _quickScore(Story story, List<String> queryKeywords) {
    double score = 0.0;
    final title = _normalizeText(story.title);
    final author = _normalizeText(story.author);
    final category = _normalizeText(story.category);
    final desc = _normalizeText(story.description);

    for (final kw in queryKeywords) {
      if (title.contains(kw)) score += 3.0;
      if (author.contains(kw)) score += 2.0;
      if (category.contains(kw)) score += 2.0;
      if (desc.contains(kw)) score += 0.5;
    }
    return score;
  }

  /// Score đầy đủ khi đã có keywords từ Firestore
  double _scoreWithKeywords(
      Story story, List<String> queryKeywords, List<String> storyKeywords) {
    double score = _quickScore(story, queryKeywords);

    for (final qk in queryKeywords) {
      for (final sk in storyKeywords) {
        if (sk.contains(qk) || qk.contains(sk)) {
          score += 1.0;
        }
      }
    }
    return score;
  }

  // ── Simple filters (no Firestore) ─────────────────────────────────────────

  List<Story> _filterByCategory(List<Story> stories, String category) {
    final normalized = _normalizeText(category);
    return stories.where((s) {
      final c = _normalizeText(s.category);
      return c.contains(normalized) || normalized.contains(c);
    }).toList();
  }

  List<Story> _filterByPrice(List<Story> stories, bool isFree) =>
      stories.where((s) => s.isFree == isFree).toList();

  List<Story> _filterByStatus(List<Story> stories, String status) {
    final normalized = _normalizeText(status);
    return stories.where((s) {
      final st = _normalizeText(s.status);
      return st.contains(normalized) || normalized.contains(st);
    }).toList();
  }

  // ── Sort ──────────────────────────────────────────────────────────────────

  Future<List<Story>> _sortStories(List<Story> stories, String sortBy) async {
    try {
      switch (sortBy) {
        case 'rating':
          return await _sortByRating(stories);
        case 'date':
          return await _sortByDate(stories);
        case 'price':
          return _sortByPrice(stories);
        default:
          return stories;
      }
    } catch (e) {
      debugPrint('❌ _sortStories error: $e');
      return stories;
    }
  }

  /// Batch fetch ratings song song
  Future<List<Story>> _sortByRating(List<Story> stories) async {
    final bool cacheExpired = _ratingsCacheTime == null ||
        DateTime.now().difference(_ratingsCacheTime!) > _cacheLifetime;
    if (cacheExpired) {
      _ratingsCache.clear();
      _ratingsCacheTime = DateTime.now();
    }

    final toFetch = stories
        .where((s) => !_ratingsCache.containsKey(_normalizeId(s.title)))
        .toList();

    if (toFetch.isNotEmpty) {
      debugPrint('🌐 Batch fetching ratings for ${toFetch.length} stories...');
      final futures = toFetch.map((story) async {
        final id = _normalizeId(story.title);
        _ratingsCache[id] = await _getAverageRating(id);
      });
      await Future.wait(futures);
    }

    final sorted = List<Story>.from(stories)
      ..sort((a, b) {
        final ra = _ratingsCache[_normalizeId(a.title)] ?? 0.0;
        final rb = _ratingsCache[_normalizeId(b.title)] ?? 0.0;
        return rb.compareTo(ra);
      });
    return sorted;
  }

  /// Batch fetch dates song song
  Future<List<Story>> _sortByDate(List<Story> stories) async {
    final toFetch = stories
        .where((s) => !_datesCache.containsKey(_normalizeId(s.title)))
        .toList();

    if (toFetch.isNotEmpty) {
      debugPrint('🌐 Batch fetching dates for ${toFetch.length} stories...');
      final futures = toFetch.map((story) async {
        final id = _normalizeId(story.title);
        _datesCache[id] = await _getCreatedDate(id);
      });
      await Future.wait(futures);
    }

    final sorted = List<Story>.from(stories)
      ..sort((a, b) {
        final da = _datesCache[_normalizeId(a.title)] ?? DateTime(2000);
        final db = _datesCache[_normalizeId(b.title)] ?? DateTime(2000);
        return db.compareTo(da);
      });
    return sorted;
  }

  List<Story> _sortByPrice(List<Story> stories) {
    return List<Story>.from(stories)..sort((a, b) => a.price.compareTo(b.price));
  }

  // ── Firestore helpers ─────────────────────────────────────────────────────

  Future<double> _getAverageRating(String storyId) async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .doc(storyId)
          .collection('ratings')
          .get();
      if (snapshot.docs.isEmpty) return 0.0;
      double total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
      }
      return total / snapshot.docs.length;
    } catch (_) {
      return 0.0;
    }
  }

  Future<DateTime> _getCreatedDate(String storyId) async {
    try {
      final doc =
          await _firestore.collection('stories').doc(storyId).get();
      if (!doc.exists) return DateTime(2000);
      final ts = doc.data()?['createdAt'] as Timestamp?;
      return ts?.toDate() ?? DateTime(2000);
    } catch (_) {
      return DateTime(2000);
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  List<String> _extractBasicKeywords(Story story) {
    final kws = <String>{};
    kws.addAll(_normalizeText(story.title).split(' ').where((w) => w.length >= 2));
    kws.addAll(_normalizeText(story.author).split(' ').where((w) => w.length >= 2));
    kws.add(_normalizeText(story.category));
    return kws.toList();
  }

  String _normalizeText(String text) {
    const map = {
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
    String s = text.trim().toLowerCase();
    map.forEach((k, v) => s = s.replaceAll(k, v));
    return s;
  }

  String _normalizeId(String text) {
    return _normalizeText(text)
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
