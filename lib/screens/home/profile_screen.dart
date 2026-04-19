import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/user_service.dart'; // 🔥 THÊM
import 'settings_screen.dart';
import 'wishlist_screen.dart';
import 'notification_screen.dart';
import 'transaction_history_screen.dart';
import 'my_comments_screen.dart';
import '../welcome_screen.dart';
import 'personal_info_screen.dart';
import 'change_password_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  /// 🔥 AVATAR
  String avatarPath = "assets/avatars/avatar1.png";

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  /// 🔥 LOAD AVATAR CHUẨN (dùng service)
  Future<void> _loadAvatar() async {
    final avatar = await UserService.instance.getAvatar();

    setState(() {
      avatarPath = avatar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      appBar: AppBar(
        title: const Text("Tài khoản"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// ===== AVATAR =====
            Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundImage: AssetImage(avatarPath),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.displayName ?? "Người dùng",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Bất Nhập Lưu Vô Giá",
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ===== PROGRESS =====
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Kinh nghiệm: 45/100"),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: 0.45,
                  color: Colors.orange,
                  backgroundColor: Colors.grey.shade300,
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ===== STATS =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _StatBox("24", "Đã đọc"),
                _StatBox("5", "Đã mua"),
                _StatBox("12", "Yêu thích"),
              ],
            ),

            const SizedBox(height: 20),

            /// ===== MENU =====
            _menuItem(
              context,
              Icons.person,
              "Thông tin cá nhân",
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PersonalInfoScreen(),
                  ),
                );

                /// 🔥 FIX: reload avatar khi quay lại
                if (result == true) {
                  await _loadAvatar();
                  setState(() {});
                }
              },
            ),

            _menuItem(
              context,
              Icons.favorite,
              "Truyện theo dõi",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WishlistScreen(),
                  ),
                );
              },
            ),

            _menuItem(
              context,
              Icons.comment,
              "Bình luận",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyCommentsScreen(),
                  ),
                );
              },
            ),

            _menuItem(
              context,
              Icons.notifications,
              "Thông báo",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ),
                );
              },
            ),

            _menuItem(
              context,
              Icons.history,
              "Lịch sử giao dịch",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const TransactionHistoryScreen(),
                  ),
                );
              },
            ),

              _menuItem(
                context,
                Icons.lock,
                "Đổi mật khẩu",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),

            const SizedBox(height: 10),

            /// ===== LOGOUT =====
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Đăng xuất",
                style: TextStyle(color: Colors.red),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                _showLogoutDialog(context);
              },
            )
          ],
        ),
      ),
    );
  }

  /// ===== MENU ITEM =====
  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseAuth.instance.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const WelcomeScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }
}

/// ===== STAT BOX =====
class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}