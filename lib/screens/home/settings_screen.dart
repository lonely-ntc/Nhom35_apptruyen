import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool isNotification = true;
  String language = "Tiếng Việt";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Cài đặt"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// ===== LANGUAGE =====
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ngôn ngữ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  value: language,
                  isExpanded: true,
                  items: ["Tiếng Việt", "English"]
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      language = value!;
                    });
                  },
                )
              ],
            ),
          ),

          /// ===== DARK MODE =====
          _card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Chế độ tối"),
                Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      isDarkMode = value;
                    });
                  },
                )
              ],
            ),
          ),

          /// ===== NOTIFICATION =====
          _card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Thông báo"),
                Switch(
                  value: isNotification,
                  onChanged: (value) {
                    setState(() {
                      isNotification = value;
                    });
                  },
                )
              ],
            ),
          ),

          /// ===== OTHER =====
          _menu("Về chúng tôi"),
          _menu("Chính sách bảo mật"),
          _menu("Điều khoản dịch vụ"),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              "Phiên bản 1.0.0",
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }

  /// CARD
  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  /// MENU
  Widget _menu(String title) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {},
    );
  }
}