import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/user_service.dart';
import '../../services/language_service.dart';
import '../../utils/app_text.dart';

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

  String avatarPath = "assets/avatars/avatar1.png";

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final avatar = await UserService.instance.getAvatar();

    setState(() {
      avatarPath = avatar;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>().lang; // 🔥 LANG

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(AppText.get("profile", lang)), // 🔥 FIX
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
                  user?.displayName ?? "User",
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
                Text("${AppText.get("exp", lang)}: 45/100"), // 🔥 FIX
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
              children: [
                _StatBox("24", AppText.get("read", lang)), // 🔥 FIX
                _StatBox("5", AppText.get("purchased", lang)),
                _StatBox("12", AppText.get("wishlist", lang)),
              ],
            ),

            const SizedBox(height: 20),

            /// ===== MENU =====
            _menuItem(
              context,
              Icons.person,
              AppText.get("profile", lang),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PersonalInfoScreen(),
                  ),
                );

                if (result == true) {
                  await _loadAvatar();
                  setState(() {});
                }
              },
            ),

            _menuItem(
              context,
              Icons.favorite,
              AppText.get("following", lang),
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
              AppText.get("comment", lang),
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
              AppText.get("notification", lang),
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
              AppText.get("history", lang),
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
              AppText.get("change_password", lang),
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
              title: Text(
                AppText.get("logout", lang), // 🔥 FIX
                style: const TextStyle(color: Colors.red),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                _showLogoutDialog(context, lang);
              },
            )
          ],
        ),
      ),
    );
  }

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

  void _showLogoutDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppText.get("logout", lang)),
        content: Text(AppText.get("logout_confirm", lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppText.get("cancel", lang)),
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
            child: Text(AppText.get("logout", lang)),
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
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}