import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      await Directory(dirname(path)).create(recursive: true);

      ByteData data =
          await rootBundle.load("assets/database/truyen.db");

      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
    }

    final db = await openDatabase(path);

    // 🔥 Tự động thêm cột nếu thiếu (chạy mỗi lần khởi động, an toàn)
    await _ensureColumns(db);

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

  Future<List<Story>> getStories() async {
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
        a.duong_dan_anh
      FROM truyen t
      LEFT JOIN anh_truyen a
      ON t.ten_truyen = a.ten_truyen
      AND t.the_loai = a.the_loai
      GROUP BY t.ten_truyen
      ORDER BY t.ten_truyen
    ''');

    return result.map((e) => Story.fromMap(e)).toList();
  }

  Future<List<Story>> searchStories(String keyword) async {
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
        a.duong_dan_anh
      FROM truyen t
      LEFT JOIN anh_truyen a
      ON t.ten_truyen = a.ten_truyen
      AND t.the_loai = a.the_loai
      WHERE t.ten_truyen LIKE ?
      GROUP BY t.ten_truyen
    ''', ['%$keyword%']);

    return result.map((e) => Story.fromMap(e)).toList();
  }

  /// 🔥 FIX CHUẨN THỨ TỰ CHƯƠNG
Future<List<Map<String, dynamic>>> getChapters(String tenTruyen) async {
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
}

  Future<String> getChapterContent(String link) async {
    final db = await database;

    final result = await db.query(
      "chuong",
      where: "link = ?",
      whereArgs: [link],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['noi_dung']?.toString() ?? "";
    }

    return "";
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

  Stream<List<String>> getWishlist(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.id).toList());
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

  Stream<Map<String, int>> getReadingList(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reading_progress')
        .snapshots()
        .map((snapshot) {
      final map = <String, int>{};
      for (var doc in snapshot.docs) {
        map[doc.id] = doc['chapter'] ?? 1;
      }
      return map;
    });
  }
  /// ======================= ⭐ RATING =======================

Future<void> rateStory({
  required String storyId,
  required String userId,
  required int rating,
}) async {
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
    if (snapshot.docs.isEmpty) return 0;

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc['rating'] ?? 0);
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

    print("🔥 SAVE COMMENT:");
    print("userId: $userId");
    print("storyId: $storyId");

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
      .map((snapshot) =>
          snapshot.docs.map((e) => e.data()).toList());
}
/// ⭐ COUNT RATING
Future<Map<int, int>> getRatingStats(String storyId) async {
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

  return stats;
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

    final data = doc.data();
    return data?['rating'];
  } catch (e) {
    print("getUserRating error: $e");
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

Future<List<Map<String, dynamic>>> getPurchasedStories(String userId) async {
  final snapshot = await _firestore
      .collection('users')
      .doc(userId)
      .collection('purchased')
      .get();

  return snapshot.docs.map((e) => e.data()).toList();
}

Future<void> updatePurchasedChapter({
  required String userId,
  required String storyId,
  required int chapter,
}) async {
  await _firestore
      .collection('users')
      .doc(userId)
      .collection('purchased')
      .doc(storyId)
      .update({'lastChapter': chapter});
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