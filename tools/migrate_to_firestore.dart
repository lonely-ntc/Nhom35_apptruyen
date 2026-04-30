import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/// Script để migrate dữ liệu từ SQLite sang Firestore
/// Chạy: dart tools/migrate_to_firestore.dart

Future<void> main() async {
  print('🚀 Starting migration from SQLite to Firestore...\n');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBss02_ZJSBzJAo-qSD6C0n-n4uNX8zDTU",
      authDomain: "manga-e245c.firebaseapp.com",
      projectId: "manga-e245c",
      storageBucket: "manga-e245c.firebasestorage.app",
      messagingSenderId: "455786635149",
      appId: "1:455786635149:web:YOUR_WEB_APP_ID",
    ),
  );

  // Initialize SQLite FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final firestore = FirebaseFirestore.instance;

  // Open SQLite database
  final dbPath = join('assets', 'database', 'truyen.db');
  
  if (!await File(dbPath).exists()) {
    print('❌ Database file not found: $dbPath');
    print('Please make sure the database file exists.');
    exit(1);
  }

  final db = await openDatabase(dbPath, readOnly: true);

  try {
    // Get all stories
    final stories = await db.rawQuery('''
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

    print('📚 Found ${stories.length} stories to migrate\n');

    int successCount = 0;
    int errorCount = 0;

    for (var i = 0; i < stories.length; i++) {
      final story = stories[i];
      final title = story['ten_truyen'] as String;
      final storyId = title.replaceAll(' ', '_').toLowerCase();

      try {
        print('[${ i + 1}/${stories.length}] Migrating: $title');

        // Upload story metadata
        await firestore.collection('stories').doc(storyId).set({
          'title': title,
          'author': story['tac_gia'] ?? 'Unknown',
          'category': story['the_loai'] ?? '',
          'status': story['trang_thai'] ?? '',
          'totalChapters': story['so_chuong']?.toString() ?? '',
          'description': story['mo_ta'] ?? '',
          'imageUrl': story['duong_dan_anh'] ?? '',
          'isFree': (story['is_free'] ?? 1) == 1,
          'price': (story['price'] ?? 0.0) as double,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Get chapters for this story
        final chapters = await db.query(
          'chuong',
          where: 'ten_truyen = ?',
          whereArgs: [title],
        );

        // Sort chapters
        final sortedChapters = List<Map<String, dynamic>>.from(chapters);
        sortedChapters.sort((a, b) {
          int getNumber(String text) {
            final regex = RegExp(r'\d+');
            final match = regex.firstMatch(text);
            return match != null ? int.parse(match.group(0)!) : 0;
          }

          final aNum = getNumber(a['ten_chuong']?.toString() ?? '');
          final bNum = getNumber(b['ten_chuong']?.toString() ?? '');
          return aNum.compareTo(bNum);
        });

        // Upload chapters
        for (var j = 0; j < sortedChapters.length; j++) {
          final chapter = sortedChapters[j];
          
          await firestore
              .collection('stories')
              .doc(storyId)
              .collection('chapters')
              .add({
            'chapterNumber': j + 1,
            'title': chapter['ten_chuong'] ?? '',
            'content': chapter['noi_dung'] ?? '',
            'link': chapter['link'] ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        print('   ✅ Uploaded ${sortedChapters.length} chapters');
        successCount++;

        // Delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));

      } catch (e) {
        print('   ❌ Error: $e');
        errorCount++;
      }
    }

    print('\n' + '=' * 50);
    print('🎉 Migration completed!');
    print('✅ Success: $successCount stories');
    if (errorCount > 0) {
      print('❌ Errors: $errorCount stories');
    }
    print('=' * 50);

  } catch (e) {
    print('❌ Fatal error: $e');
    exit(1);
  } finally {
    await db.close();
  }
}
