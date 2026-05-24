import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ CACHE để tránh query lại
  List<Story>? _cachedStories;
  final Map<String, List<Map<String, dynamic>>> _cachedChapters = {};
  DateTime? _lastStoriesLoad;
  
  // Cache timeout: 5 phút
  static const _cacheTimeout = Duration(minutes: 5);

  DatabaseService._init();

  /// ================= SQLITE DATABASE =================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "truyen.db");

    final exists = await databaseExists(path);

    if (!exists) {
      // Copy database từ assets sang app directory (writable)
      await Directory(dirname(path)).create(recursive: true);

      ByteData data = await rootBundle.load("database/truyen.db");
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
      debugPrint('✅ Copied database from assets to: $path');
    }

    // Mở database với writable mode
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        debugPrint('📝 Database created with version $version');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('📝 Database upgraded from $oldVersion to $newVersion');
      },
    );

    // 🔥 Tự động thêm cột nếu thiếu (chạy mỗi lần khởi động, an toàn)
    await _ensureColumns(db);

    debugPrint('✅ Database initialized at: $path');
    return db;
  }

  /// 🔥 Đảm bảo cột is_free và price tồn tại (chạy mỗi lần, idempotent)
  Future<void> _ensureColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(truyen)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      if (!columnNames.contains('is_free')) {
        // SQLite chỉ cho phép ADD COLUMN với DEFAULT, không được NOT NULL
        await db.execute(
          'ALTER TABLE truyen ADD COLUMN is_free INTEGER DEFAULT 1',
        );
        await db.execute(
          'UPDATE truyen SET is_free = 1 WHERE is_free IS NULL',
        );
        print('✅ Added column: is_free');
      }

      if (!columnNames.contains('price')) {
        await db.execute(
          'ALTER TABLE truyen ADD COLUMN price REAL DEFAULT 0.0',
        );
        await db.execute(
          'UPDATE truyen SET price = 0.0 WHERE price IS NULL',
        );
        print('✅ Added column: price');
      }
    } catch (e) {
      print('❌ _ensureColumns error: $e');
    }
  }

  // =========================================================
  // ======================= STORIES ==========================
  // =========================================================

  /// 🔥 GET STORIES FROM SQLITE + FIRESTORE (Combined)
  /// 🔥 Pricing (isFree, price) ALWAYS from Firestore if exists
  /// 🔥 Story data from both SQLite and Firestore
  /// 🔥 KHÔNG TRÙNG LẶP: Mỗi truyện chỉ xuất hiện 1 lần
  Future<List<Story>> getStories() async {
    debugPrint('🔄 Loading stories...');
    
    // ✅ Check cache first
    if (_cachedStories != null && _lastStoriesLoad != null) {
      final now = DateTime.now();
      if (now.difference(_lastStoriesLoad!) < _cacheTimeout) {
        debugPrint('✅ Stories from cache: ${_cachedStories!.length}');
        return _cachedStories!;
      }
    }

    // 🔥 ĐỌC TỪ SQLITE (dữ liệu crawl cũ)
    final sqliteStories = await _getStoriesFromSQLite();
    debugPrint('📦 SQLite stories: ${sqliteStories.length}');

    // 🔥 ĐỌC TỪ FIRESTORE (truyện admin upload mới)
    final firestoreStories = await _getStoriesFromFirestore();
    debugPrint('🔥 Firestore stories: ${firestoreStories.length}');

    // 🔥 MERGE PRICING: For SQLite stories, override pricing from Firestore if exists
    // Also returns list of Firestore story titles to avoid duplicates
    final mergeResult = await _mergePricingFromFirestore(sqliteStories, firestoreStories);
    final mergedSqliteStories = mergeResult['sqliteStories'] as List<Story>;
    final firestoreOnlyStories = mergeResult['firestoreOnlyStories'] as List<Story>;
    
    debugPrint('💰 Merged pricing for ${mergedSqliteStories.length} SQLite stories');
    debugPrint('🆕 Firestore-only stories: ${firestoreOnlyStories.length}');

    // 🔥 KẾT HỢP: SQLite stories (with Firestore pricing) + Firestore-only stories
    final allStories = _dedupeStoriesByKey([
      ...mergedSqliteStories,
      ...firestoreOnlyStories,
    ]);
    debugPrint('✅ Total unique stories: ${allStories.length}');

    // ✅ Cache result
    _cachedStories = allStories;
    _lastStoriesLoad = DateTime.now();

    return _cachedStories!;
  }

  /// 🔥 MERGE STORIES: Firestore override toàn bộ SQLite nếu cùng tên
  /// - Truyện có trong Firestore → dùng data Firestore (mới nhất)
  /// - Truyện chỉ có trong SQLite → dùng data SQLite
  /// - Truyện chỉ có trong Firestore → thêm vào danh sách
  /// - Không trùng lặp
  Future<Map<String, List<Story>>> _mergePricingFromFirestore(
    List<Story> sqliteStories,
    List<Story> firestoreStories,
  ) async {
    try {
      // Map Firestore stories theo key chuẩn hóa để lookup nhanh
      final firestoreMap = <String, Story>{};
      final firestoreOnlyStories = <Story>[];

      // Tập key của SQLite để phân biệt "có trong SQLite" hay không
      final sqliteTitleKeys = <String>{};
      for (var s in sqliteStories) {
        sqliteTitleKeys.add(storyKey(s.title));
      }

      for (var story in firestoreStories) {
        final key = storyKey(story.title);
        if (sqliteTitleKeys.contains(key)) {
          // Trùng với SQLite → Firestore override
          firestoreMap[key] = story;
          debugPrint('   🔄 Firestore overrides SQLite: ${story.title}');
        } else {
          // Chỉ có trong Firestore (truyện admin thêm mới)
          firestoreOnlyStories.add(story);
          debugPrint('   🆕 Firestore-only: ${story.title}');
        }
      }

      debugPrint('🔄 Firestore overrides ${firestoreMap.length} SQLite stories');
      debugPrint('🆕 Firestore-only stories: ${firestoreOnlyStories.length}');

      // Với mỗi truyện SQLite: nếu Firestore có → dùng Firestore, không thì giữ SQLite
      final mergedStories = <Story>[];
      for (var story in sqliteStories) {
        final key = storyKey(story.title);
        if (firestoreMap.containsKey(key)) {
          // Dùng toàn bộ data từ Firestore (đã được admin cập nhật)
          mergedStories.add(firestoreMap[key]!);
        } else {
          // Giữ nguyên data SQLite
          mergedStories.add(story);
        }
      }

      return {
        'sqliteStories': mergedStories,
        'firestoreOnlyStories': firestoreOnlyStories,
      };
    } catch (e) {
      debugPrint('❌ _mergePricingFromFirestore error: $e');
      return {
        'sqliteStories': sqliteStories,
        'firestoreOnlyStories': firestoreStories,
      };
    }
  }

  /// 🔥 Get stories from SQLite (dữ liệu crawl)
  /// 🔥 KHÔNG TRÙNG LẶP: Mỗi truyện chỉ xuất hiện 1 lần
  Future<List<Story>> _getStoriesFromSQLite() async {
    try {
      final db = await database;

      // 🔥 Đảm bảo cột tồn tại trước khi query
      await _ensureColumns(db);

      final result = await db.rawQuery('''
        SELECT 
          t.ten_truyen,
          t.tac_gia,
          t.the_loai,
          t.mo_ta,
          t.trang_thai,
          t.so_chuong,
          COALESCE(t.is_free, 1) AS is_free,
          COALESCE(t.price, 0.0) AS price,
          (SELECT a.duong_dan_anh 
           FROM anh_truyen a 
           WHERE a.ten_truyen = t.ten_truyen 
           AND a.the_loai = t.the_loai 
           LIMIT 1) AS duong_dan_anh
        FROM truyen t
        GROUP BY t.ten_truyen, t.the_loai
        ORDER BY t.ten_truyen
      ''');

      debugPrint('📦 SQLite query returned ${result.length} stories');
      
      // Remove duplicates by title (case-insensitive)
      final uniqueStories = <String, Story>{};
      for (var row in result) {
        final story = Story.fromMap(row);
        final titleKey = storyKey(story.title);
        
        // Only add if not already exists
        if (!uniqueStories.containsKey(titleKey)) {
          uniqueStories[titleKey] = story;
        } else {
          debugPrint('⚠️  Skipping duplicate story: ${story.title}');
        }
      }

      debugPrint('✅ Unique SQLite stories: ${uniqueStories.length}');
      return uniqueStories.values.toList();
    } catch (e) {
      print('❌ _getStoriesFromSQLite error: $e');
      return [];
    }
  }

  /// 🔥 Get stories from Firestore (truyện admin upload)
  /// 🔥 KHÔNG TRÙNG LẶP: Mỗi truyện chỉ xuất hiện 1 lần
  Future<List<Story>> _getStoriesFromFirestore() async {
    try {
      debugPrint('🔍 Fetching stories from Firestore...');
      
      // Thử orderBy createdAt trước
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('stories')
            .orderBy('createdAt', descending: true)
            .get();
        debugPrint('✅ Firestore query with orderBy succeeded');
      } catch (e) {
        // Nếu lỗi index, lấy không orderBy
        debugPrint('⚠️ orderBy createdAt failed, fetching without order: $e');
        snapshot = await _firestore.collection('stories').get();
      }

      debugPrint('📊 Firestore documents fetched: ${snapshot.docs.length}');

      // Use map to ensure uniqueness by title (case-insensitive)
      final uniqueStories = <String, Story>{};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final story = Story.fromFirestore(data);
          
          if (story.title.isEmpty) {
            debugPrint('⚠️  Skipping story with empty title: ${doc.id}');
            continue;
          }
          
          final titleKey = storyKey(story.title);
          
          // Only add if not already exists (keep the first one, which is newest due to orderBy)
          if (!uniqueStories.containsKey(titleKey)) {
            uniqueStories[titleKey] = story;
            debugPrint('📄 Added Firestore story: ${story.title}');
          } else {
            debugPrint('⚠️  Skipping duplicate Firestore story: ${story.title}');
          }
        } catch (e) {
          debugPrint('❌ Error processing story doc ${doc.id}: $e');
        }
      }

      debugPrint('✅ Unique Firestore stories: ${uniqueStories.length}');
      return uniqueStories.values.toList();
    } catch (e, stackTrace) {
      debugPrint('❌ _getStoriesFromFirestore error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Clear cache manually if needed
  void clearCache() {
    debugPrint('🗑️ Clearing all cache...');
    _cachedStories = null;
    _cachedChapters.clear();
    _lastStoriesLoad = null;
  }

  /// Clear chapter cache for a specific story
  void clearChapterCache(String storyTitle) {
    debugPrint('🗑️ Clearing chapter cache for: $storyTitle');
    _cachedChapters.remove(storyTitle);
  }

  Future<Story?> getStoryByTitle(String title) async {
    try {
      final lookupKey = storyKey(title);
      final stories = await getStories();

      for (final story in stories) {
        if (storyKey(story.title) == lookupKey) {
          return story;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ getStoryByTitle error: $e');
      return null;
    }
  }

  /// 🔥 UPDATE STORY IN SQLITE
  /// Dùng khi admin muốn sửa trực tiếp dữ liệu gốc SQLite
  /// Lưu ý: Firestore vẫn là nguồn override — sau khi sửa SQLite,
  /// nếu muốn app thấy thay đổi thì cần updateStory() lên Firestore
  Future<bool> updateStoryInSQLite({
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
      final db = await database;

      debugPrint('🔄 Updating story in SQLite: $oldTitle → $newTitle');

      await db.transaction((txn) async {
        final updateData = <String, dynamic>{
          'ten_truyen': newTitle,
          'tac_gia': author,
          'the_loai': category,
          'trang_thai': status,
          'so_chuong': totalChapters,
          'mo_ta': description,
          'is_free': (isFree ?? true) ? 1 : 0,
          'price': price ?? 0.0,
        };

        final existingRows = await txn.query(
          'truyen',
          columns: ['rowid'],
          where: 'ten_truyen = ?',
          whereArgs: [oldTitle],
          limit: 1,
        );

        if (existingRows.isNotEmpty) {
          await txn.update(
            'truyen',
            updateData,
            where: 'ten_truyen = ?',
            whereArgs: [oldTitle],
          );
          debugPrint('✅ Updated existing SQLite story: $oldTitle');
        } else {
          await txn.insert('truyen', {
            ...updateData,
            'link': '',
          });
          debugPrint('✅ Inserted Firestore story into SQLite: $newTitle');
        }

        final imageValue = imagePath?.trim() ?? '';
        final imageRows = await txn.query(
          'anh_truyen',
          columns: ['rowid'],
          where: 'ten_truyen = ?',
          whereArgs: [oldTitle],
          limit: 1,
        );

        if (imageRows.isNotEmpty) {
          final imageUpdate = <String, dynamic>{
            'ten_truyen': newTitle,
            'the_loai': category,
          };
          if (imageValue.isNotEmpty) {
            imageUpdate['duong_dan_anh'] = imageValue;
          }

          await txn.update(
            'anh_truyen',
            imageUpdate,
            where: 'ten_truyen = ?',
            whereArgs: [oldTitle],
          );
        } else if (imageValue.isNotEmpty) {
          await txn.insert('anh_truyen', {
            'ten_truyen': newTitle,
            'the_loai': category,
            'duong_dan_anh': imageValue,
          });
        }

        if (oldTitle != newTitle) {
          await txn.update(
            'chuong',
            {'ten_truyen': newTitle},
            where: 'ten_truyen = ?',
            whereArgs: [oldTitle],
          );
        }
      });

      clearCache();
      return true;
    } catch (e) {
      debugPrint('❌ updateStoryInSQLite error: $e');
      return false;
    }
  }

  /// 🔥 Force refresh stories (clear cache and reload)
  Future<List<Story>> refreshStories() async {
    debugPrint('🔄 Force refreshing stories...');
    clearCache();
    return await getStories();
  }

  /// 🔥 SEARCH STORIES (Combined SQLite + Firestore)
  /// 🔥 KHÔNG TRÙNG LẶP: Mỗi truyện chỉ xuất hiện 1 lần
  /// 🔥 Pricing từ Firestore nếu có
  Future<List<Story>> searchStories(String keyword) async {
    debugPrint('🔍 Searching stories with keyword: "$keyword"');
    
    // 🔥 TÌM KIẾM TRONG SQLITE
    final sqliteResults = await _searchStoriesFromSQLite(keyword);
    debugPrint('📦 SQLite search results: ${sqliteResults.length}');

    // 🔥 TÌM KIẾM TRONG FIRESTORE
    final firestoreResults = await _searchStoriesFromFirestore(keyword);
    debugPrint('🔥 Firestore search results: ${firestoreResults.length}');

    // 🔥 MERGE: Remove duplicates and apply Firestore pricing
    final mergeResult = await _mergePricingFromFirestore(sqliteResults, firestoreResults);
    final mergedSqliteResults = mergeResult['sqliteStories'] as List<Story>;
    final firestoreOnlyResults = mergeResult['firestoreOnlyStories'] as List<Story>;
    
    final allResults = _dedupeStoriesByKey([
      ...mergedSqliteResults,
      ...firestoreOnlyResults,
    ]);
    debugPrint('✅ Total unique search results: ${allResults.length}');
    
    return allResults;
  }

  /// 🔥 Search stories from SQLite
  /// 🔥 KHÔNG TRÙNG LẶP: Mỗi truyện chỉ xuất hiện 1 lần
  Future<List<Story>> _searchStoriesFromSQLite(String keyword) async {
    try {
      final db = await database;

      // 🔥 Đảm bảo cột tồn tại trước khi query
      await _ensureColumns(db);

      final result = await db.rawQuery('''
        SELECT 
          t.ten_truyen,
          t.tac_gia,
          t.the_loai,
          t.mo_ta,
          t.trang_thai,
          t.so_chuong,
          COALESCE(t.is_free, 1) AS is_free,
          COALESCE(t.price, 0.0) AS price,
          (SELECT a.duong_dan_anh 
           FROM anh_truyen a 
           WHERE a.ten_truyen = t.ten_truyen 
           AND a.the_loai = t.the_loai 
           LIMIT 1) AS duong_dan_anh
        FROM truyen t
        WHERE t.ten_truyen LIKE ?
        GROUP BY t.ten_truyen, t.the_loai
      ''', ['%$keyword%']);

      // Remove duplicates by title (case-insensitive)
      final uniqueStories = <String, Story>{};
      for (var row in result) {
        final story = Story.fromMap(row);
        final titleKey = storyKey(story.title);
        
        if (!uniqueStories.containsKey(titleKey)) {
          uniqueStories[titleKey] = story;
        }
      }

      return uniqueStories.values.toList();
    } catch (e) {
      print('❌ _searchStoriesFromSQLite error: $e');
      return [];
    }
  }

  /// 🔥 Search stories from Firestore
  /// 🔥 KHÔNG TRÙNG LẶP: Mỗi truyện chỉ xuất hiện 1 lần
  Future<List<Story>> _searchStoriesFromFirestore(String keyword) async {
    try {
      final snapshot = await _firestore.collection('stories').get();

      // Use map to ensure uniqueness by title (case-insensitive)
      final uniqueStories = <String, Story>{};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final title = data['title']?.toString() ?? '';
          
          if (title.isEmpty) continue;
          
          // Check if title matches keyword
          if (title.toLowerCase().contains(keyword.toLowerCase())) {
            final story = Story.fromFirestore(data);
            final titleKey = storyKey(story.title);
            
            // Only add if not already exists
            if (!uniqueStories.containsKey(titleKey)) {
              uniqueStories[titleKey] = story;
            }
          }
        } catch (e) {
          debugPrint('❌ Error processing Firestore doc: $e');
        }
      }

      return uniqueStories.values.toList();
    } catch (e) {
      print('❌ _searchStoriesFromFirestore error: $e');
      return [];
    }
  }

  /// 🔥 GET CHAPTERS (Try Firestore first, then SQLite)
  Future<List<Map<String, dynamic>>> getChapters(String tenTruyen) async {
    // ✅ Check cache first
    if (_cachedChapters.containsKey(tenTruyen)) {
      return _cachedChapters[tenTruyen]!;
    }

    // 🔥 THỬ ĐỌC TỪ FIRESTORE TRƯỚC (truyện admin upload)
    final firestoreChapters = await _getChaptersFromFirestore(tenTruyen);
    if (firestoreChapters.isNotEmpty) {
      _cachedChapters[tenTruyen] = firestoreChapters;
      return firestoreChapters;
    }

    // 🔥 NẾU KHÔNG CÓ, ĐỌC TỪ SQLITE (truyện crawl cũ)
    final sqliteChapters = await _getChaptersFromSQLite(tenTruyen);
    _cachedChapters[tenTruyen] = sqliteChapters;
    return sqliteChapters;
  }

  /// 🔥 Get chapters from Firestore (truyện admin upload)
  Future<List<Map<String, dynamic>>> _getChaptersFromFirestore(String tenTruyen) async {
    try {
      final storyId = _normalizeId(tenTruyen);
      final snapshot = await _firestore
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .orderBy('chapterNumber')
          .get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore format to legacy format for compatibility
        return {
          'ten_chuong': data['chapterName'] ?? '',
          'noi_dung': data['content'] ?? '',
          'link': data['link'] ?? '',
          'chapterNumber': data['chapterNumber'] ?? 0,
          'firestoreDocId': doc.id, // 🔥 Lưu doc ID để admin có thể edit/delete
          'isFirestore': true,      // 🔥 Đánh dấu nguồn dữ liệu
        };
      }).toList();
    } catch (e) {
      print('❌ _getChaptersFromFirestore error: $e');
      return [];
    }
  }

  /// 🔥 Get chapters from SQLite (truyện crawl cũ)
  Future<List<Map<String, dynamic>>> _getChaptersFromSQLite(String tenTruyen) async {
    try {
      final db = await database;

      final result = await db.query(
        "chuong",
        where: "ten_truyen = ?",
        whereArgs: [tenTruyen],
      );

      /// 🔥 COPY RA LIST MỚI (QUAN TRỌNG)
      final List<Map<String, dynamic>> chapters = List.from(result);

      /// 🔥 SORT
      chapters.sort((a, b) {
        int getNumber(String text) {
          final regex = RegExp(r'\d+');
          final match = regex.firstMatch(text);
          return match != null ? int.parse(match.group(0)!) : 0;
        }

        final aNum = getNumber(a['ten_chuong']?.toString() ?? '');
        final bNum = getNumber(b['ten_chuong']?.toString() ?? '');

        return aNum.compareTo(bNum);
      });

      return chapters;
    } catch (e) {
      print('❌ _getChaptersFromSQLite error: $e');
      return [];
    }
  }

  /// 🔥 NORMALIZE ID (for Firestore document IDs)
  /// Handles Vietnamese characters properly
  String storyKey(String text) => _normalizeId(text);

  List<Story> _dedupeStoriesByKey(List<Story> stories) {
    final uniqueStories = <String, Story>{};

    for (final story in stories) {
      final key = storyKey(story.title);
      if (!uniqueStories.containsKey(key)) {
        uniqueStories[key] = story;
      }
    }

    return uniqueStories.values.toList();
  }

  String _normalizeId(String text) {
    // Map Vietnamese characters to ASCII equivalents
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
    
    // Replace Vietnamese characters
    vietnameseMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
    
    // Remove special characters and replace spaces with underscores
    normalized = normalized
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    
    return normalized;
  }

  /// 🔥 GET CHAPTER CONTENT (Support both Firestore and SQLite)
  /// @param link: Chapter link
  /// @param storyTitle: Optional story title for faster Firestore lookup
  Future<String> getChapterContent(String link, {String? storyTitle}) async {
    try {
      // 1. Try to find chapter in cache first
      if (storyTitle != null && _cachedChapters.containsKey(storyTitle)) {
        final chapter = _cachedChapters[storyTitle]!.firstWhere(
          (ch) => ch['link'] == link,
          orElse: () => {},
        );
        if (chapter.isNotEmpty) {
          final content = chapter['noi_dung']?.toString() ?? "";
          if (content.isNotEmpty) {
            debugPrint('✅ Chapter content from cache: $link');
            return content;
          }
        }
      }

      // 2. Try SQLite
      final db = await database;
      final result = await db.query(
        "chuong",
        where: "link = ?",
        whereArgs: [link],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final content = result.first['noi_dung']?.toString() ?? "";
        if (content.isNotEmpty) {
          debugPrint('✅ Chapter content from SQLite: $link');
          return content;
        }
      }

      // 3. Try Firestore (if storyTitle provided)
      if (storyTitle != null) {
        debugPrint('🔍 Searching Firestore for chapter: $link in story: $storyTitle');
        
        final storyId = _normalizeId(storyTitle);
        final chaptersSnapshot = await _firestore
            .collection('stories')
            .doc(storyId)
            .collection('chapters')
            .where('link', isEqualTo: link)
            .limit(1)
            .get();
        
        if (chaptersSnapshot.docs.isNotEmpty) {
          final chapterData = chaptersSnapshot.docs.first.data();
          final content = chapterData['content']?.toString() ?? "";
          debugPrint('✅ Chapter content from Firestore: $link');
          return content;
        }
      }

      debugPrint('⚠️ Chapter content not found: $link');
      return "";
    } catch (e) {
      debugPrint('❌ getChapterContent error: $e');
      return "";
    }
  }

  // =========================================================
  // ======================= 🔔 NOTIFICATION ==================
  // =========================================================

  Future<List<Map<String, dynamic>>> getLatestChapters() async {
    final db = await database;

    final result = await db.query(
      "chuong",
      orderBy: "rowid DESC",
      limit: 20,
    );

    return result;
  }

  // =========================================================
  // ======================= ❤️ WISHLIST ======================
  // =========================================================

  Future<void> toggleWishlist({
    required String userId,
    required String storyId,
  }) async {
    try {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(storyId);

      final doc = await ref.get();

      if (doc.exists) {
        await ref.delete();
      } else {
        await ref.set({
          'storyId': storyId,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print("Wishlist error: $e");
    }
  }

  Future<bool> isFavorite(String userId, String storyId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(storyId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// 🔥 GET WISHLIST - Lắng nghe trực tiếp subcollection (realtime)
  Stream<List<String>> getWishlist(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots()
        .asyncMap((subSnapshot) async {
      // Subcollection có dữ liệu → dùng subcollection (NEW FORMAT)
      if (subSnapshot.docs.isNotEmpty) {
        // Lấy storyId từ field 'storyId' nếu có, fallback về doc.id
        final ids = subSnapshot.docs.map((e) {
          final data = e.data();
          return (data['storyId'] as String?) ?? e.id;
        }).toList();
        print('✅ Wishlist from subcollection: ${ids.length} items');
        return ids;
      }

      // Fallback: đọc array trong user document (OLD FORMAT)
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data['wishlist'] is List) {
            final ids = List<String>.from(data['wishlist']);
            print('✅ Wishlist from array fallback: ${ids.length} items');
            return ids;
          }
        }
      } catch (e) {
        print('❌ Wishlist fallback error: $e');
      }

      print('⚠️ No wishlist data found for user: $userId');
      return <String>[];
    });
  }

  // =========================================================
  // ======================= 🔔 FOLLOWING =====================
  // =========================================================

  Future<void> toggleFollowing({
    required String userId,
    required String storyId,
    required String storyImage,
  }) async {
    try {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(storyId);

      final doc = await ref.get();

      if (doc.exists) {
        await ref.delete();
      } else {
        await ref.set({
          'storyId': storyId,
          'storyImage': storyImage,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print("Following error: $e");
    }
  }

  Future<bool> isFollowing(String userId, String storyId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(storyId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getFollowing(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) {
          final data = e.data();
          return {
            'storyId': data['storyId'] ?? '',
            'storyImage': data['storyImage'] ?? '',
            'createdAt': data['createdAt'],
          };
        }).toList());
  }

  // =========================================================
  // ======================= 📖 READING =======================
  // =========================================================

  Future<void> saveReadingProgress({
    required String userId,
    required String storyId,
    required int chapter,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('reading_progress')
          .doc(storyId)
          .set({
        'storyId': storyId,
        'chapter': chapter,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print("Reading error: $e");
    }
  }

  /// 🔥 GET READING LIST - Lắng nghe trực tiếp subcollection (realtime)
  Stream<Map<String, int>> getReadingList(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reading_progress')
        .snapshots()
        .asyncMap((subSnapshot) async {
      final Map<String, int> readingMap = {};

      // Subcollection có dữ liệu → dùng subcollection (NEW FORMAT)
      if (subSnapshot.docs.isNotEmpty) {
        for (var doc in subSnapshot.docs) {
          final data = doc.data();
          // Key là storyId từ field hoặc doc.id
          final storyId = (data['storyId'] as String?) ?? doc.id;
          readingMap[storyId] = (data['chapter'] as int?) ?? 1;
        }
        print('✅ Reading from subcollection: ${readingMap.length} items');
        return readingMap;
      }

      // Fallback: đọc map trong user document (OLD FORMAT)
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data['readingProgress'] is Map) {
            final reading = data['readingProgress'] as Map;
            reading.forEach((key, value) {
              if (value is int) readingMap[key.toString()] = value;
            });
            print('✅ Reading from map fallback: ${readingMap.length} items');
          }
        }
      } catch (e) {
        print('❌ Reading fallback error: $e');
      }

      if (readingMap.isEmpty) {
        print('⚠️ No reading progress found for user: $userId');
      }

      return readingMap;
    });
  }
  /// ======================= ⭐ RATING =======================

Future<void> rateStory({
  required String storyId,
  required String userId,
  required int rating,
}) async {
  // Dùng title gốc làm document ID (nhất quán với dữ liệu cũ)
  await _firestore
      .collection('stories')
      .doc(storyId)
      .collection('ratings')
      .doc(userId)
      .set({'rating': rating});
}

Stream<double> getAverageRating(String storyId) {
  return _firestore
      .collection('stories')
      .doc(storyId)
      .collection('ratings')
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return 0.0;

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc['rating'] as num?)?.toDouble() ?? 0;
    }
    return total / snapshot.docs.length;
  });
}

/// ======================= 💬 COMMENT =======================

Future<void> addComment({
  required String storyId,
  required String userId,
  required String content,
  required String userName, 
  required String avatar,
}) async {
  try {
    final data = {
      'storyId': storyId,
      'userId': userId,
      'userName': userName,
      'avatar': avatar,
      'content': content,
      'createdAt': Timestamp.now(),
    };

    print("🔥 SAVE COMMENT: storyId=$storyId, userId=$userId");

    // STORY
    await _firestore
        .collection('stories')
        .doc(storyId)
        .collection('comments')
        .add(data);

    print("✅ Saved to stories");

    // USER
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('comments')
        .add(data);

    print("✅ Saved to users");
  } catch (e) {
    print("❌ addComment error: $e");
  }
}

Stream<List<Map<String, dynamic>>> getComments(String storyId) {
  return _firestore
      .collection('stories')
      .doc(storyId)
      .collection('comments')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((e) => e.data()).toList());
}
/// ⭐ COUNT RATING
Future<Map<int, int>> getRatingStats(String storyId) async {
  try {
    final snapshot = await _firestore
        .collection('stories')
        .doc(storyId)
        .collection('ratings')
        .get();

    Map<int, int> stats = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var doc in snapshot.docs) {
      int rating = doc['rating'] ?? 0;
      if (stats.containsKey(rating)) {
        stats[rating] = stats[rating]! + 1;
      }
    }
    print('📊 Rating stats for "$storyId": $stats');
    return stats;
  } catch (e) {
    print('❌ getRatingStats error: $e');
    return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  }
}

/// ================== GET USER RATING ==================
Future<int?> getUserRating({
  required String storyId,
  required String userId,
}) async {
  try {
    final doc = await _firestore
        .collection('stories')
        .doc(storyId)
        .collection('ratings')
        .doc(userId)
        .get();

    if (!doc.exists) return null;
    return doc.data()?['rating'];
  } catch (e) {
    print("❌ getUserRating error: $e");
    return null;
  }
}
/// ================== PURCHASE ==================

Future<void> addPurchasedStory({
  required String userId,
  required String storyTitle,
  required String storyImage,
  required double price,
}) async {
  try {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('purchased')
        .doc(storyTitle)
        .set({
      'title': storyTitle,
      'image': storyImage,
      'price': price,
      'time': DateTime.now().toString(),
      'lastChapter': 1,
    });
    
    print('✅ Story purchased: $storyTitle');
  } catch (e) {
    print('❌ addPurchasedStory error: $e');
    rethrow;
  }
}

Future<void> buyStory({
  required String userId,
  required Story story,
}) async {
  await _firestore
      .collection('users')
      .doc(userId)
      .collection('purchased')
      .doc(story.title)
      .set({
    'title': story.title,
    'image': story.image,
    'time': DateTime.now().toString(),
    'lastChapter': 1,
  });
}

/// 🔥 GET PURCHASED STORIES WITH FULL DETAILS (Support both formats)
Future<List<Map<String, dynamic>>> getPurchasedStories(String userId) async {
  try {
    List<String> purchasedIds = [];

    // 1. Try subcollection first (NEW FORMAT)
    final subSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('purchased')
        .get();

    if (subSnapshot.docs.isNotEmpty) {
      print('✅ Purchased from subcollection: ${subSnapshot.docs.length} items');
      
      // 2. Lấy tất cả stories (SQLite + Firestore)
      final allStories = await getStories();

      // 3. Map purchased với story details
      final List<Map<String, dynamic>> result = [];

      for (var doc in subSnapshot.docs) {
        final purchaseData = doc.data();
        final docId = doc.id; // Document ID (có thể là normalized)

        // 🔥 Tìm story bằng cả title gốc và normalized title
        Story? matchedStory;
        
        // Try exact match first
        matchedStory = allStories.firstWhere(
          (s) => s.title == docId,
          orElse: () => Story(title: ''),
        );
        
        // If not found, try normalized match
        if (matchedStory.title.isEmpty) {
          final normalizedDocId = _normalizeId(docId);
          matchedStory = allStories.firstWhere(
            (s) => _normalizeId(s.title) == normalizedDocId,
            orElse: () => Story(title: docId),
          );
        }

        if (matchedStory.title.isNotEmpty) {
          result.add({
            'title': matchedStory.title,
            'image': matchedStory.image,
            'author': matchedStory.author,
            'category': matchedStory.category,
            'lastChapter': purchaseData['lastChapter'] ?? 1,
            'purchaseDate': purchaseData['purchaseDate'],
            'price': purchaseData['price'] ?? 0,
          });
        }
      }

      return result;
    }

    // 2. Fallback to array in user document (OLD FORMAT)
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data.containsKey('purchased')) {
        final purchased = data['purchased'];
        if (purchased is List) {
          purchasedIds = List<String>.from(purchased);
          print('✅ Purchased from array: ${purchasedIds.length} items');
          
          // Get all stories
          final allStories = await getStories();
          
          // Map to full details
          final List<Map<String, dynamic>> result = [];
          for (var storyTitle in purchasedIds) {
            final story = allStories.firstWhere(
              (s) => s.title == storyTitle || _normalizeId(s.title) == _normalizeId(storyTitle),
              orElse: () => Story(title: storyTitle),
            );
            
            if (story.title.isNotEmpty) {
              result.add({
                'title': story.title,
                'image': story.image,
                'author': story.author,
                'category': story.category,
                'lastChapter': 1,
                'purchaseDate': null,
                'price': 0,
              });
            }
          }
          
          return result;
        }
      }
    }

    return [];
  } catch (e) {
    print('❌ getPurchasedStories error: $e');
    return [];
  }
}

/// 🔥 GET PURCHASED STREAM - Lắng nghe realtime subcollection purchased
Stream<List<Map<String, dynamic>>> getPurchasedStream(String userId) {
  return _firestore
      .collection('users')
      .doc(userId)
      .collection('purchased')
      .snapshots()
      .asyncMap((snapshot) async {
    if (snapshot.docs.isEmpty) return <Map<String, dynamic>>[];

    final allStories = await getStories();
    final List<Map<String, dynamic>> result = [];

    for (var doc in snapshot.docs) {
      final purchaseData = doc.data();
      final docId = doc.id;

      // Tìm story khớp với title gốc hoặc normalized
      Story? matchedStory;
      matchedStory = allStories.firstWhere(
        (s) => s.title == docId,
        orElse: () => Story(title: ''),
      );
      if (matchedStory.title.isEmpty) {
        final normalizedDocId = _normalizeId(docId);
        matchedStory = allStories.firstWhere(
          (s) => _normalizeId(s.title) == normalizedDocId,
          orElse: () => Story(title: docId),
        );
      }

      if (matchedStory.title.isNotEmpty) {
        result.add({
          'title': matchedStory.title,
          'image': matchedStory.image.isNotEmpty ? matchedStory.image : (purchaseData['image'] ?? ''),
          'author': matchedStory.author,
          'category': matchedStory.category,
          'lastChapter': purchaseData['lastChapter'] ?? 1,
          'purchaseDate': purchaseData['purchaseDate'] ?? purchaseData['time'],
          'price': purchaseData['price'] ?? 0,
        });
      }
    }

    print('🛒 Purchased stream: ${result.length} items');
    return result;
  });
}

Future<void> updatePurchasedChapter({
  required String userId,
  required String storyId,
  required int chapter,
}) async {
  try {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('purchased')
        .doc(storyId)
        .update({'lastChapter': chapter});
  } catch (e) {
    print('❌ updatePurchasedChapter error: $e');
  }
}
/// ================== 💬 GET USER COMMENTS (FIX CHUẨN) ==================

Stream<List<Map<String, dynamic>>> getUserComments(String userId) {
  return _firestore
      .collection('users')
      .doc(userId)
      .collection('comments')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((e) => e.data()).toList());
}
}
