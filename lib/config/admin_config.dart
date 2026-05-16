class AdminConfig {
  // Private constructor để không thể khởi tạo class này
  AdminConfig._();
  
  /// 🔥 DANH SÁCH ADMIN TỔNG (SUPER ADMIN)
  /// Chỉ những email này mới có quyền:
  /// - Cấp quyền admin cho tài khoản khác
  /// - Xóa admin
  /// - Quản lý hệ thống admin
  static const List<String> superAdminEmails = [
    'admin@gmail.com',        // Admin chính
    'zingme369@gmail.com',    // Admin phụ 1
    'huyphongg305@gmail.com', // Admin phụ 2
  ];

  /// Kiểm tra email có phải super admin không
  static bool isSuperAdmin(String email) {
    return superAdminEmails.contains(email.toLowerCase().trim());
  }

  /// Kiểm tra email có phải admin không (bao gồm cả super admin và admin được cấp quyền)
  /// Để kiểm tra admin được cấp quyền, cần dùng AdminManagementService.isAdmin()
  static bool isAdminEmail(String email) {
    return superAdminEmails.contains(email.toLowerCase().trim());
  }

  /// Lấy danh sách email super admin dưới dạng string (để hiển thị)
  static String getSuperAdminEmailsString() {
    return superAdminEmails.join(', ');
  }

  /// Số lượng super admin trong hệ thống
  static int get superAdminCount => superAdminEmails.length;
}

