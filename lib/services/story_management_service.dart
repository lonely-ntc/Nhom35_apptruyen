import 'package:sqflite/sqflite.dart';
import '../models/story_model.dart';
import 'database_service.dart';

class StoryManagementService {
  static final StoryManagementService instance = StoryManagementService._();
  StoryManagementService._();

  final DatabaseService _dbService = DatabaseService.instance;

  /// 🔥 ADD STORY
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
      final db = await _dbService.database;

      // Insert vào bảng truyen
      await db.insert(
        'truyen',
        {
          'ten_truyen': title,
          'tac_gia': author,
          'the_loai': category,
          'trang_thai': status,
          'so_chuong': totalChapters,
          'mo_ta': description,
          'is_free': isFree ? 1 : 0,
          'price': price,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert vào bảng anh_truyen
      if (imagePath.isNotEmpty) {
        await db.insert(
          'anh_truyen',
          {
            'ten_truyen': title,
            'the_loai': category,
            'duong_dan_anh': imagePath,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('✅ Story added: $title');
      return true;
    } catch (e) {
      print('❌ addStory error: $e');
      return false;
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
    String? imagePath,
    bool? isFree,
    double? price,
  }) async {
    try {
      final db = await _dbService.database;

      // Prepare update data
      Map<String, dynamic> updateData = {
        'ten_truyen': newTitle,
        'tac_gia': author,
        'the_loai': category,
        'trang_thai': status,
        'so_chuong': totalChapters,
        'mo_ta': description,
      };

      // Luôn cập nhật is_free và price (không check null)
      updateData['is_free'] = (isFree ?? true) ? 1 : 0;
      updateData['price'] = price ?? 0.0;

      print('🔥 updateStory data: $updateData');

      // Update bảng truyen
      final rowsAffected = await db.update(
        'truyen',
        updateData,
        where: 'ten_truyen = ?',
        whereArgs: [oldTitle],
      );

      print('✅ Rows affected: $rowsAffected');

      // Update bảng anh_truyen nếu có ảnh mới
      if (imagePath != null && imagePath.isNotEmpty) {
        await db.update(
          'anh_truyen',
          {
            'ten_truyen': newTitle,
            'the_loai': category,
            'duong_dan_anh': imagePath,
          },
          where: 'ten_truyen = ?',
          whereArgs: [oldTitle],
        );
      }

      // Update bảng chuong nếu đổi tên truyện
      if (oldTitle != newTitle) {
        await db.update(
          'chuong',
          {'ten_truyen': newTitle},
          where: 'ten_truyen = ?',
          whereArgs: [oldTitle],
        );
      }

      print('✅ Story updated: $oldTitle → $newTitle | isFree=$isFree | price=$price');
      return true;
    } catch (e) {
      print('❌ updateStory error: $e');
      return false;
    }
  }

  /// 🔥 DELETE STORY
  Future<bool> deleteStory(String title) async {
    try {
      final db = await _dbService.database;

      // Delete từ bảng truyen
      await db.delete(
        'truyen',
        where: 'ten_truyen = ?',
        whereArgs: [title],
      );

      // Delete từ bảng anh_truyen
      await db.delete(
        'anh_truyen',
        where: 'ten_truyen = ?',
        whereArgs: [title],
      );

      // Delete từ bảng chuong
      await db.delete(
        'chuong',
        where: 'ten_truyen = ?',
        whereArgs: [title],
      );

      print('✅ Story deleted: $title');
      return true;
    } catch (e) {
      print('❌ deleteStory error: $e');
      return false;
    }
  }

  /// 🔥 CHECK IF STORY EXISTS
  Future<bool> storyExists(String title) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'truyen',
        where: 'ten_truyen = ?',
        whereArgs: [title],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 🔥 GET STORY BY TITLE
  Future<Story?> getStoryByTitle(String title) async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery('''
        SELECT 
          t.ten_truyen,
          t.tac_gia,
          t.the_loai,
          t.trang_thai,
          t.so_chuong,
          t.mo_ta,
          t.is_free,
          t.price,
          a.duong_dan_anh
        FROM truyen t
        LEFT JOIN anh_truyen a
        ON t.ten_truyen = a.ten_truyen
        WHERE t.ten_truyen = ?
      ''', [title]);

      if (result.isNotEmpty) {
        return Story.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('❌ getStoryByTitle error: $e');
      return null;
    }
  }
}