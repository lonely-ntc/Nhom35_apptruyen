import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/admin_config.dart';

/// Service quản lý danh sách admin và quyền hạn
/// 
/// 🔥 ADMIN ĐƯỢC LẤY TỪ COLLECTION 'users' VỚI FIELD 'isAdmin = true'
/// 
/// Cấu trúc Firestore:
/// users/{userId} {
///   email: string
///   displayName: string
///   isAdmin: bool              // 🔥 true = admin, false = user thường
///   coin_balance: number
///   ...
/// }
/// 
/// 🔥 SUPER ADMIN được định nghĩa trong AdminConfig.superAdminEmails
class AdminManagementService {
  static final AdminManagementService _instance = AdminManagementService._internal();
  factory AdminManagementService() => _instance;
  AdminManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 LẤY DANH SÁCH TẤT CẢ ADMIN
  /// Lấy từ collection 'users' với field 'isAdmin = true'
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'email': data['email'] ?? 'N/A',
          'displayName': data['displayName'] ?? data['username'] ?? 'Admin',
          'isAdmin': data['isAdmin'] ?? false,
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting all admins: $e');
      return [];
    }
  }

  /// 🔥 LẤY DANH SÁCH EMAIL ADMIN NHẬN THÔNG BÁO NẠP XU
  /// Lấy từ collection 'users' với field 'isAdmin = true'
  Future<List<String>> getAdminEmailsForTopupNotification() async {
    try {
      debugPrint('📋 Đang lấy danh sách admin từ collection users...');
      
      final snapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();
      
      final emails = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return data['email'] as String?;
          })
          .where((email) => email != null && email.isNotEmpty)
          .cast<String>()
          .toList();
      
      debugPrint('✅ Tìm thấy ${emails.length} admin');
      debugPrint('📧 Admin emails: $emails');
      
      if (emails.isEmpty) {
        debugPrint('⚠️ Không có admin nào, sử dụng fallback');
        return AdminConfig.superAdminEmails;
      }
      
      return emails;
    } catch (e) {
      debugPrint('❌ Error getting admin emails: $e');
      
      // 🔥 FALLBACK: Nếu không lấy được từ Firestore, dùng super admin từ AdminConfig
      debugPrint('⚠️ Sử dụng fallback: Super Admin từ AdminConfig');
      return AdminConfig.superAdminEmails;
    }
  }

  /// 🔥 KIỂM TRA EMAIL CÓ PHẢI ADMIN KHÔNG
  /// Kiểm tra trong collection 'users' với field 'isAdmin = true'
  Future<bool> isAdmin(String email) async {
    try {
      // Kiểm tra super admin từ AdminConfig
      if (AdminConfig.isSuperAdmin(email)) {
        return true;
      }
      
      // Kiểm tra admin trong collection 'users'
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking admin: $e');
      return false;
    }
  }

  /// 🔥 KIỂM TRA EMAIL CÓ PHẢI SUPER ADMIN KHÔNG (từ AdminConfig)
  Future<bool> isSuperAdmin(String email) async {
    return AdminConfig.isSuperAdmin(email);
  }

  /// 🔥 CẬP NHẬT QUYỀN ADMIN CHO USER
  /// Cập nhật field 'isAdmin' trong collection 'users'
  Future<bool> setAdminPermission({
    required String email,
    required bool isAdmin,
    required String updatedBy,
  }) async {
    try {
      // Kiểm tra người cập nhật có phải super admin không
      final isSuperAdminUser = await isSuperAdmin(updatedBy);
      if (!isSuperAdminUser) {
        debugPrint('❌ Only super admin can update admin permission');
        return false;
      }

      // Không thể thay đổi quyền của super admin
      if (AdminConfig.isSuperAdmin(email)) {
        debugPrint('❌ Cannot change super admin permission');
        return false;
      }

      // Tìm user theo email
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('❌ User not found: $email');
        return false;
      }

      // Cập nhật quyền admin
      await _firestore
          .collection('users')
          .doc(snapshot.docs.first.id)
          .update({'isAdmin': isAdmin});

      debugPrint('✅ Updated admin permission for $email: $isAdmin');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating admin permission: $e');
      return false;
    }
  }

  /// 🔥 STREAM DANH SÁCH ADMIN (Real-time)
  /// Lấy từ collection 'users' với field 'isAdmin = true'
  Stream<List<Map<String, dynamic>>> getAdminsStream() {
    return _firestore
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'email': data['email'] ?? 'N/A',
          'displayName': data['displayName'] ?? data['username'] ?? 'Admin',
          'isAdmin': data['isAdmin'] ?? false,
          'createdAt': data['createdAt'],
        };
      }).toList();
    });
  }
}
