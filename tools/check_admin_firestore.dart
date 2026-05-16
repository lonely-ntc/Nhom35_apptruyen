/// 🔍 Script kiểm tra admin trong Firestore
/// 
/// Chạy: dart run tools/check_admin_firestore.dart
/// 
/// Script này sẽ:
/// 1. Kết nối Firestore
/// 2. Kiểm tra collection 'users' với field 'isAdmin = true'
/// 3. Hiển thị danh sách admin

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('========================================');
  print('🔍 KIỂM TRA ADMIN TRONG FIRESTORE');
  print('========================================\n');

  try {
    // Khởi tạo Firebase
    print('🔥 Đang kết nối Firebase...');
    await Firebase.initializeApp();
    print('✅ Kết nối Firebase thành công!\n');

    final firestore = FirebaseFirestore.instance;

    // Lấy tất cả user có isAdmin = true
    print('📋 Đang lấy danh sách admin từ collection "users"...');
    final snapshot = await firestore
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .get();
    
    if (snapshot.docs.isEmpty) {
      print('⚠️ KHÔNG CÓ ADMIN NÀO TRONG FIRESTORE!\n');
      print('💡 Giải pháp:');
      print('   1. Vào Firebase Console → Collection "users"');
      print('   2. Tìm user cần làm admin');
      print('   3. Sửa field "isAdmin" = true\n');
      return;
    }

    print('✅ Tìm thấy ${snapshot.docs.length} admin\n');
    print('========================================');
    print('📋 DANH SÁCH ADMIN:');
    print('========================================\n');

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final email = data['email'] ?? 'N/A';
      final displayName = data['displayName'] ?? data['username'] ?? 'N/A';
      final isAdmin = data['isAdmin'] ?? false;
      
      print('📧 Email: $email');
      print('   👤 Tên: $displayName');
      print('   🔐 Admin: ${isAdmin ? "✅ CÓ" : "❌ KHÔNG"}');
      print('   📅 Tạo lúc: ${data['createdAt']}');
      print('');
    }

    print('========================================');
    print('📊 TỔNG KẾT:');
    print('========================================');
    print('   Tổng admin: ${snapshot.docs.length}');
    print('');
    print('✅ Tất cả admin này sẽ nhận email khi có nạp xu\n');

  } catch (e, stackTrace) {
    print('❌ LỖI: $e');
    print('Stack trace: $stackTrace\n');
    
    print('💡 HƯỚNG DẪN FIX:');
    print('   1. Kiểm tra Firebase đã được cấu hình chưa');
    print('   2. Kiểm tra file google-services.json (Android) hoặc GoogleService-Info.plist (iOS)');
    print('   3. Kiểm tra Firestore Rules có cho phép đọc collection "users" không\n');
  }

  print('========================================');
  print('✅ HOÀN TẤT KIỂM TRA');
  print('========================================');
}
