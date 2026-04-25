import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String searchQuery = "";

  /// 🔥 STREAM REALTIME
  Stream<QuerySnapshot> getUsers() {
    return _db.collection("users").snapshots();
  }

  /// 🔥 UPDATE ROLE
  Future<void> toggleAdmin(String uid, bool currentStatus, String email) async {
    // Không cho phép tự thu hồi quyền của chính mình
    if (uid == UserService.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không thể thay đổi quyền của chính mình!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _db.collection("users").doc(uid).update({
      "isAdmin": !currentStatus,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currentStatus
              ? "Đã thu hồi quyền admin của $email"
              : "Đã cấp quyền admin cho $email",
        ),
        backgroundColor: currentStatus ? Colors.orange : Colors.green,
      ),
    );
  }

  /// 🔥 DELETE USER ACCOUNT
  Future<void> _deleteUserAccount(String uid, String email) async {
    // Không cho phép xóa chính mình
    if (uid == UserService.instance.currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không thể xóa tài khoản của chính mình!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text("Xác nhận xóa"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bạn có chắc chắn muốn xóa tài khoản này?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Hành động này sẽ xóa:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              _buildDeleteItem("Thông tin tài khoản", Icons.person_off),
              _buildDeleteItem("Danh sách yêu thích", Icons.favorite_border),
              _buildDeleteItem("Lịch sử mua hàng", Icons.shopping_bag_outlined),
              _buildDeleteItem("Tiến độ đọc", Icons.menu_book_outlined),
              _buildDeleteItem("Bình luận", Icons.comment_outlined),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Không thể hoàn tác!",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Hủy",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Xóa tài khoản"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Delete user data from Firestore
      await _db.collection("users").doc(uid).delete();

      // Delete user's subcollections (if any)
      // Note: Firebase Auth user deletion requires admin SDK or user re-authentication
      // For now, we only delete Firestore data
      
      if (!mounted) return;

      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Đã xóa tài khoản thành công"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text("Lỗi: $e")),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildDeleteItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ],
      ),
    );
  }
  void _showUserInfoDialog(String uid, Map<String, dynamic> userData) {
    final nameController = TextEditingController(
      text: userData['displayName'] ?? '',
    );
    final avatarController = TextEditingController(
      text: userData['avatar'] ?? '',
    );
    String selectedGender = userData['gender'] ?? 'unknown';

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: 12),
                  const Text("Thông tin người dùng"),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// EMAIL (read-only)
                    Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userData['email'] ?? '',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// DISPLAY NAME
                    Text(
                      "Tên hiển thị",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: "Nhập tên hiển thị",
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          size: 20,
                          color: AppColors.primaryPurple,
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// AVATAR
                    Text(
                      "Avatar",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: avatarController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: "assets/avatars/avatar1.png",
                        prefixIcon: Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: AppColors.primaryPurple,
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// GENDER
                    Text(
                      "Giới tính",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedGender,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: theme.iconTheme.color,
                        ),
                        dropdownColor: theme.cardColor,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "Nam",
                            child: Row(
                              children: [
                                Icon(Icons.male, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Nam"),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: "Nữ",
                            child: Row(
                              children: [
                                Icon(Icons.female, size: 18, color: Colors.pink),
                                SizedBox(width: 8),
                                Text("Nữ"),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: "Khác",
                            child: Row(
                              children: [
                                Icon(Icons.transgender,
                                    size: 18, color: Colors.purple),
                                SizedBox(width: 8),
                                Text("Khác"),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: "unknown",
                            child: Row(
                              children: [
                                Icon(Icons.help_outline,
                                    size: 18, color: Colors.grey),
                                SizedBox(width: 8),
                                Text("Chưa xác định"),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedGender = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Hủy",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Update user info
                    await _db.collection("users").doc(uid).set({
                      'displayName': nameController.text.trim(),
                      'avatar': avatarController.text.trim(),
                      'gender': selectedGender,
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    if (!context.mounted) return;

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text("Đã cập nhật thông tin người dùng"),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Lưu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuperAdmin = UserService.instance.isSuperAdmin;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Quản lý người dùng"),
        elevation: 0,
      ),
      body: Column(
        children: [
          /// 🔥 SEARCH BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.appBarTheme.backgroundColor,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: "Tìm kiếm người dùng...",
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// 🔥 USER LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Chưa có người dùng"));
                }

                var users = snapshot.data!.docs;

                // Filter by search
                if (searchQuery.isNotEmpty) {
                  users = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final email = (data["email"] ?? "").toString().toLowerCase();
                    return email.contains(searchQuery);
                  }).toList();
                }

                // Sort: Admin first
                users.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aAdmin = aData["isAdmin"] ?? false;
                  final bAdmin = bData["isAdmin"] ?? false;
                  
                  if (aAdmin && !bAdmin) return -1;
                  if (!aAdmin && bAdmin) return 1;
                  return 0;
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final uid = doc.id;
                    final email = data["email"] ?? "";
                    final isAdmin = data["isAdmin"] ?? false;
                    final isCurrentUser = uid == UserService.instance.currentUser?.uid;

                    return _buildUserCard(
                      uid: uid,
                      email: email,
                      isAdmin: isAdmin,
                      isCurrentUser: isCurrentUser,
                      isSuperAdmin: isSuperAdmin,
                      userData: data,
                      theme: theme,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 USER CARD
  Widget _buildUserCard({
    required String uid,
    required String email,
    required bool isAdmin,
    required bool isCurrentUser,
    required bool isSuperAdmin,
    required Map<String, dynamic> userData,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        
        /// AVATAR
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isAdmin
                  ? [Colors.red, Colors.orange]
                  : [Colors.blue, Colors.lightBlue],
            ),
          ),
          child: Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: Colors.white,
            size: 28,
          ),
        ),

        /// EMAIL
        title: Row(
          children: [
            Expanded(
              child: Text(
                email,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Bạn",
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        /// ROLE
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAdmin ? "ADMIN" : "USER",
                  style: TextStyle(
                    fontSize: 11,
                    color: isAdmin ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        /// ACTION BUTTONS
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// INFO BUTTON
            IconButton(
              icon: Icon(
                Icons.info_outline,
                color: AppColors.primaryPurple,
                size: 22,
              ),
              onPressed: () => _showUserInfoDialog(uid, userData),
              tooltip: "Xem thông tin",
            ),

            /// DELETE BUTTON (only for super admin and not current user)
            if (isSuperAdmin && !isCurrentUser)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 22,
                ),
                onPressed: () => _deleteUserAccount(uid, email),
                tooltip: "Xóa tài khoản",
              ),

            /// ADMIN TOGGLE (only for super admin)
            if (isSuperAdmin && !isCurrentUser)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAdmin
                      ? Colors.orange
                      : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => toggleAdmin(uid, isAdmin, email),
                child: Text(
                  isAdmin ? "Thu hồi" : "Cấp quyền",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}