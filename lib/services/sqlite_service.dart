import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteService {
  static final SQLiteService instance = SQLiteService._();
  SQLiteService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    await initDB();
    return _db!;
  }

  /// 🔥 COPY DB TỪ ASSETS
  Future<void> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'truyen.db');

    final exists = await databaseExists(path);

    if (!exists) {
      final data = await rootBundle.load('assets/database/truyen.db');

      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
    }

    _db = await openDatabase(path);
  }

  /// 🔥 LẤY DANH SÁCH TRUYỆN (JOIN 2 BẢNG)
  Future<List<Map<String, dynamic>>> getStories() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        truyen.ten_truyen,
        truyen.tac_gia,
        truyen.the_loai,
        anh_truyen.duong_dan_anh
      FROM truyen
      LEFT JOIN anh_truyen 
      ON truyen.ten_truyen = anh_truyen.ten_truyen
    ''');

    return result;
  }

  /// 🔥 LẤY CHƯƠNG THEO TRUYỆN
  Future<List<Map<String, dynamic>>> getChapters(String tenTruyen) async {
    final db = await database;

    return await db.query(
      "chuong",
      where: "ten_truyen = ?",
      whereArgs: [tenTruyen],
    );
  }
}