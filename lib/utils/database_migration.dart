import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';

/// 🔥 DATABASE MIGRATION HELPER
/// Thêm cột is_free và price vào bảng truyen
class DatabaseMigration {
  static Future<void> addPriceColumns() async {
    try {
      final db = await DatabaseService.instance.database;
      
      // Check if columns already exist
      final tableInfo = await db.rawQuery('PRAGMA table_info(truyen)');
      final columnNames = tableInfo.map((col) => col['name'] as String).toList();
      
      // Add is_free column if not exists
      if (!columnNames.contains('is_free')) {
        await db.execute('ALTER TABLE truyen ADD COLUMN is_free INTEGER DEFAULT 1');
        print('✅ Added column: is_free');
      } else {
        print('ℹ️ Column is_free already exists');
      }
      
      // Add price column if not exists
      if (!columnNames.contains('price')) {
        await db.execute('ALTER TABLE truyen ADD COLUMN price REAL DEFAULT 0.0');
        print('✅ Added column: price');
      } else {
        print('ℹ️ Column price already exists');
      }
      
      print('✅ Database migration completed successfully!');
    } catch (e) {
      print('❌ Database migration error: $e');
      rethrow;
    }
  }
  
  /// 🔥 RUN ALL MIGRATIONS
  static Future<void> runMigrations() async {
    print('🔄 Running database migrations...');
    await addPriceColumns();
    print('✅ All migrations completed!');
  }
}
