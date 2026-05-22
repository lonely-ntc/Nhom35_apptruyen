import 'package:cloud_firestore/cloud_firestore.dart';
import 'keyword_service.dart';
import '../models/story_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final KeywordService _keywordService = KeywordService();

  // ================= USER =================

  Future<void> createUser({
    required String uid,
    required String email,
    required bool isAdmin,
  }) async {
    await _db.collection("users").doc(uid).set({
      "email": email,
      "isAdmin": isAdmin,
      "wishlist": [],
      "purchased": [],
      "readingProgress": {},
      "coin_balance": 0,
    });
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _db.collection("users").doc(uid).get();
  }

  Future<void> updateUserAdmin(String uid, bool isAdmin) async {
    await _db.collection("users").doc(uid).update({
      "isAdmin": isAdmin,
    });
  }

  Future<List<QueryDocumentSnapshot>> getAllUsers() async {
    final snapshot = await _db.collection("users").get();
    return snapshot.docs;
  }

  // ================= STORIES =================

  /// 🔥 ADD STORY TO FIRESTORE
  Future<bool> addStory({
    required String title,
    required String author,
    required String category,
    required String status,
    required String totalChapters,
    required String description,
    required String imageUrl,
    bool isFree = true,
    double price = 0.0,
  }) async {
    try {
      // Tạo document ID từ title (normalize)
      final storyId = _normalizeId(title);

      await _db.collection('stories').doc(storyId).set({
        'title': title,
        'author': author,
        'category': category,
        'status': status,
        'totalChapters': totalChapters,
        'description': description,
        'imageUrl': imageUrl,
        'isFree': isFree,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 🔥 TỰ ĐỘNG TẠO KEYWORDS cho truyện mới
      print('🤖 Auto-generating keywords for new story: $title');
      final story = Story(
        title: title,
        author: author,
        category: category,
        status: status,
        totalChapters: totalChapters,
        description: description,
        image: imageUrl,
        isFree: isFree,
        price: price,
      );
      
      // Tạo keywords trong background (không chặn việc thêm truyện)
      _keywordService.autoGenerateKeywordsForNewStory(story).then((success) {
        if (success) {
          print('✅ Keywords generated successfully for: $title');
        } else {
          print('⚠️  Failed to generate keywords for: $title');
        }
      }).catchError((e) {
        print('❌ Error generating keywords: $e');
      });

      return true;
    } catch (e) {
      print('❌ addStory error: $e');
      return false;
    }
  }

  /// 🔥 ADD CHAPTER TO STORY
  Future<bool> addChapter({
    required String storyTitle,
    required String chapterName,
    required String content,
    required String link,
    required int chapterNumber,
  }) async {
    try {
      final storyId = _normalizeId(storyTitle);

      await _db
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .add({
        'chapterName': chapterName,
        'content': content,
        'link': link,
        'chapterNumber': chapterNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('❌ addChapter error: $e');
      return false;
    }
  }

  /// 🔥 GET ALL STORIES FROM FIRESTORE
  Future<List<Map<String, dynamic>>> getAllStories() async {
    try {
      final snapshot = await _db
          .collection('stories')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ getAllStories error: $e');
      return [];
    }
  }

  /// 🔥 GET STORY BY TITLE
  Future<Map<String, dynamic>?> getStoryByTitle(String title) async {
    try {
      final storyId = _normalizeId(title);
      final doc = await _db.collection('stories').doc(storyId).get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('❌ getStoryByTitle error: $e');
      return null;
    }
  }

  /// 🔥 UPDATE CHAPTER IN FIRESTORE
  Future<bool> updateChapter({
    required String storyTitle,
    required String chapterDocId,
    required String chapterName,
    required String content,
  }) async {
    try {
      final storyId = _normalizeId(storyTitle);
      await _db
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .doc(chapterDocId)
          .update({
        'chapterName': chapterName,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ updateChapter error: $e');
      return false;
    }
  }

  /// 🔥 DELETE CHAPTER FROM FIRESTORE
  Future<bool> deleteChapter({
    required String storyTitle,
    required String chapterDocId,
  }) async {
    try {
      final storyId = _normalizeId(storyTitle);
      await _db
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .doc(chapterDocId)
          .delete();
      return true;
    } catch (e) {
      print('❌ deleteChapter error: $e');
      return false;
    }
  }

  /// 🔥 UPDATE CHAPTER COUNT ON STORY DOCUMENT
  Future<void> updateChapterCount({
    required String storyTitle,
    required int count,
  }) async {
    try {
      final storyId = _normalizeId(storyTitle);
      await _db.collection('stories').doc(storyId).update({
        'totalChapters': count.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ updateChapterCount error: $e');
    }
  }

  /// 🔥 GET CHAPTERS FOR STORY
  Future<List<Map<String, dynamic>>> getChapters(String storyTitle) async {
    try {
      final storyId = _normalizeId(storyTitle);
      final snapshot = await _db
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .orderBy('chapterNumber')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ getChapters error: $e');
      return [];
    }
  }

  /// 🔥 UPDATE STORY
  Future<bool> updateStory({
    required String oldTitle,
    required String newTitle,
    required String author,
    required String category,
    required String status,
    required String totalChapters,
    required String description,
    String? imageUrl,
    bool? isFree,
    double? price,
  }) async {
    try {
      final oldStoryId = _normalizeId(oldTitle);
      final newStoryId = _normalizeId(newTitle);

      Map<String, dynamic> updateData = {
        'title': newTitle,
        'author': author,
        'category': category,
        'status': status,
        'totalChapters': totalChapters,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (isFree != null) updateData['isFree'] = isFree;
      if (price != null) updateData['price'] = price;

      // Nếu title thay đổi, cần tạo document mới và xóa cũ
      if (oldStoryId != newStoryId) {
        // Get old document
        final oldDoc = await _db.collection('stories').doc(oldStoryId).get();
        if (!oldDoc.exists) return false;

        final oldData = oldDoc.data()!;
        oldData.addAll(updateData);

        // Create new document
        await _db.collection('stories').doc(newStoryId).set(oldData);

        // Copy chapters
        final chapters = await _db
            .collection('stories')
            .doc(oldStoryId)
            .collection('chapters')
            .get();

        for (var chapter in chapters.docs) {
          await _db
              .collection('stories')
              .doc(newStoryId)
              .collection('chapters')
              .doc(chapter.id)
              .set(chapter.data());
        }

        // Delete old document and chapters
        await _db.collection('stories').doc(oldStoryId).delete();
      } else {
        // Just update
        await _db.collection('stories').doc(oldStoryId).update(updateData);
      }

      return true;
    } catch (e) {
      print('❌ updateStory error: $e');
      return false;
    }
  }

  /// 🔥 DELETE STORY
  Future<bool> deleteStory(String title) async {
    try {
      final storyId = _normalizeId(title);

      // Delete all chapters first
      final chapters = await _db
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .get();

      for (var chapter in chapters.docs) {
        await chapter.reference.delete();
      }

      // Delete story
      await _db.collection('stories').doc(storyId).delete();

      return true;
    } catch (e) {
      print('❌ deleteStory error: $e');
      return false;
    }
  }

  /// 🔥 SEARCH STORIES
  Future<List<Map<String, dynamic>>> searchStories(String keyword) async {
    try {
      final snapshot = await _db.collection('stories').get();

      // Firestore không hỗ trợ LIKE search, phải filter ở client
      final results = snapshot.docs.where((doc) {
        final title = doc.data()['title']?.toString().toLowerCase() ?? '';
        return title.contains(keyword.toLowerCase());
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return results;
    } catch (e) {
      print('❌ searchStories error: $e');
      return [];
    }
  }

  /// 🔥 NORMALIZE ID (tạo document ID từ title)
  /// Handles Vietnamese characters properly
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
}