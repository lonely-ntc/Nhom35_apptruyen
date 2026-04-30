import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../services/theme_service.dart';
import '../../services/language_service.dart';
import '../../utils/app_text.dart';
import '../../utils/app_colors.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    /// 🔥 WATCH LANGUAGE (QUAN TRỌNG)
    final langService = context.watch<LanguageService>();
    final lang = langService.lang;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.iconTheme.color,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(AppText.get("settings", lang)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ===== HEADER =====
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple,
                  AppColors.primaryPurple.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tùy chỉnh",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Cài đặt ứng dụng của bạn",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// ===== SECTION: APPEARANCE =====
          _buildSectionTitle("Giao diện", Icons.palette_outlined, theme),
          const SizedBox(height: 12),

          /// LANGUAGE
          _buildModernCard(
            theme: theme,
            isDark: isDark,
            icon: Icons.language,
            iconColor: Colors.blue,
            title: AppText.get("language", lang),
            subtitle: lang == "vi" ? "Tiếng Việt" : "English",
            trailing: DropdownButton<String>(
              value: lang,
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: theme.iconTheme.color,
              ),
              items: const [
                DropdownMenuItem(value: "vi", child: Text("Tiếng Việt")),
                DropdownMenuItem(value: "en", child: Text("English")),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await context.read<LanguageService>().changeLanguage(value);
              },
            ),
          ),

          const SizedBox(height: 12),

          /// DARK MODE
          _buildModernCard(
            theme: theme,
            isDark: isDark,
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            iconColor: isDark ? Colors.indigo : Colors.amber,
            title: AppText.get("dark_mode", lang),
            subtitle: isDark ? "Đang bật" : "Đang tắt",
            trailing: Switch(
              value: context.watch<ThemeService>().isDark,
              activeColor: AppColors.primaryPurple,
              onChanged: (value) {
                context.read<ThemeService>().toggleTheme(value);
              },
            ),
          ),

          const SizedBox(height: 24),

          /// ===== SECTION: NOTIFICATIONS =====
          _buildSectionTitle("Thông báo", Icons.notifications_outlined, theme),
          const SizedBox(height: 12),

          /// NOTIFICATION
          _buildModernCard(
            theme: theme,
            isDark: isDark,
            icon: Icons.notifications_active,
            iconColor: Colors.orange,
            title: AppText.get("notification", lang),
            subtitle: isNotificationOn ? "Đang bật" : "Đang tắt",
            trailing: Switch(
              value: isNotificationOn,
              activeColor: AppColors.primaryPurple,
              onChanged: (value) {
                setState(() {
                  isNotificationOn = value;
                });
                _saveNotification(value);
              },
            ),
          ),

          const SizedBox(height: 40),

          /// ===== VERSION =====
          Center(
            child: _buildCard(
              child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: theme.iconTheme.color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "COMIC MANGA",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Version 1.0.0",
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// ===== SECTION TITLE =====
  Widget _buildSectionTitle(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryPurple,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  /// ===== MODERN CARD =====
  Widget _buildModernCard({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          /// ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),

          /// TRAILING
          trailing,
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
}