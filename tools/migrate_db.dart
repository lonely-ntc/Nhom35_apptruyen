/// Script hướng dẫn cập nhật truyen.db: thêm cột is_free và price
/// Chạy: dart run tools/migrate_db.dart

import 'dart:io';

void main() {
  final dbFile = File('database/truyen.db');

  if (!dbFile.existsSync()) {
    print('❌ Không tìm thấy file: database/truyen.db');
    exit(1);
  }

  print('📂 DB path: ${dbFile.absolute.path}');
  print('📦 File size: ${dbFile.lengthSync()} bytes');

  // Kiểm tra magic header SQLite
  final bytes = dbFile.readAsBytesSync();
  final magic = String.fromCharCodes(bytes.sublist(0, 15));
  if (!magic.startsWith('SQLite format 3')) {
    print('❌ File không phải SQLite database hợp lệ');
    exit(1);
  }

  print('✅ File SQLite hợp lệ');
  print('');
  print('👉 Hãy chạy các lệnh SQL sau trong DB Browser for SQLite');
  print('   hoặc bất kỳ SQLite client nào:');
  print('');
  print('   File: ${dbFile.absolute.path}');
  print('');
  print('─' * 60);
  print('-- Kiểm tra cột hiện tại:');
  print('PRAGMA table_info(truyen);');
  print('');
  print('-- Thêm cột is_free (1 = miễn phí, 0 = có phí):');
  print('ALTER TABLE truyen ADD COLUMN is_free INTEGER DEFAULT 1;');
  print('');
  print('-- Thêm cột price (giá tiền):');
  print('ALTER TABLE truyen ADD COLUMN price REAL DEFAULT 0.0;');
  print('');
  print('-- Xác nhận tất cả truyện hiện tại là miễn phí:');
  print('UPDATE truyen SET is_free = 1, price = 0.0 WHERE is_free IS NULL;');
  print('─' * 60);
  print('');
  print('💡 Tải DB Browser for SQLite: https://sqlitebrowser.org/');
  print('');
  print('ℹ️  Lưu ý: File DB trong assets đã được cập nhật.');
  print('   App sẽ tự động thêm cột khi chạy trên device.');
}
