import 'package:flutter/material.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Tài khoản"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                  backgroundImage: NetworkImage(
                    "https://i.pravatar.cc/150",
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "NGUYEN VAN A",
                  style: TextStyle(
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
            _menuItem(Icons.person, "Thông tin cá nhân"),
            _menuItem(Icons.store, "Cửa hàng"),
            _menuItem(Icons.favorite, "Truyện theo dõi"),
            _menuItem(Icons.menu_book, "Truyện đã đăng"),
            _menuItem(Icons.comment, "Bình luận"),
            _menuItem(Icons.notifications, "Thông báo"),
            _menuItem(Icons.history, "Lịch sử giao dịch"),
            _menuItem(Icons.lock, "Đổi mật khẩu"),

            const SizedBox(height: 10),

            /// LOGOUT
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Đăng xuất",
                style: TextStyle(color: Colors.red),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {},
            )
          ],
        ),
      ),
    );
  }

  /// MENU ITEM
  Widget _menuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {},
    );
  }
}

/// STAT BOX
class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}