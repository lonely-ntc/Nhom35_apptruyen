import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../services/theme_service.dart';
import '../../services/language_service.dart';
import '../../utils/app_text.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isNotificationOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// LOAD
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      isNotificationOn = prefs.getBool("notification") ?? true;
    });
  }

  /// SAVE
  Future<void> _saveNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notification", value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// 🔥 WATCH LANGUAGE (QUAN TRỌNG)
    final langService = context.watch<LanguageService>();
    final lang = langService.lang;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.get("settings", lang)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// ===== LANGUAGE =====
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppText.get("language", lang),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButton<String>(
                  value: lang,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: "vi", child: Text("Tiếng Việt")),
                    DropdownMenuItem(
                        value: "en", child: Text("English")),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;

                    /// 🔥 FIX: đảm bảo update xong mới rebuild
                    await context
                        .read<LanguageService>()
                        .changeLanguage(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// ===== DARK MODE =====
          _buildCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppText.get("dark_mode", lang),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Switch(
                  value: context.watch<ThemeService>().isDark,
                  onChanged: (value) {
                    context.read<ThemeService>().toggleTheme(value);
                  },
                )
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// ===== NOTIFICATION =====
          _buildCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppText.get("notification", lang),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Switch(
                  value: isNotificationOn,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (value) {
                    setState(() {
                      isNotificationOn = value;
                    });
                    _saveNotification(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// ===== ABOUT =====
          _menuItem(
            AppText.get("about", lang),
            () {
              _showDialog(
                AppText.get("about", lang),
                lang == "vi"
                    ? "Ứng dụng đọc truyện do bạn phát triển"
                    : "A comic reading app developed by you",
              );
            },
          ),

          /// ===== PRIVACY =====
          _menuItem(
            AppText.get("privacy", lang),
            () {
              _showDialog(
                AppText.get("privacy", lang),
                lang == "vi"
                    ? "Dữ liệu người dùng được bảo vệ."
                    : "User data is protected.",
              );
            },
          ),

          /// ===== TERMS =====
          _menuItem(
            AppText.get("terms", lang),
            () {
              _showDialog(
                AppText.get("terms", lang),
                lang == "vi"
                    ? "Sử dụng app đồng nghĩa chấp nhận điều khoản."
                    : "Using the app means accepting the terms.",
              );
            },
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          )
        ],
      ),
    );
  }

  /// CARD
  Widget _buildCard({required Widget child}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  /// MENU ITEM
  Widget _menuItem(String title, VoidCallback onTap) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: theme.iconTheme.color,
          ),
          onTap: onTap,
        ),
        Divider(
          height: 1,
          color: theme.dividerColor,
        ),
      ],
    );
  }

  /// DIALOG
  void _showDialog(String title, String content) {
    final theme = Theme.of(context);
    final lang = context.read<LanguageService>().lang;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang == "vi" ? "Đóng" : "Close", // 🔥 FIX
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          )
        ],
      ),
    );
  }
}