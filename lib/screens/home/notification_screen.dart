import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      /// 🔥 FIX nền theo theme
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        /// 🔥 FIX màu icon
        leading: BackButton(
          color: theme.textTheme.bodyLarge?.color,
        ),

        title: Text(
          "Thông báo",
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              "Đọc tất cả",
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          )
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseService.instance.getLatestChapters(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return Center(
              child: Text(
                "Không có thông báo",
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildItem(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);

    final tenChuong = item['ten_chuong'] ?? '';
    final tenTruyen = item['ten_truyen'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        /// 🔥 FIX nền card
        color: theme.cardColor,

        borderRadius: BorderRadius.circular(16),

        /// 🔥 FIX border dịu hơn
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.4),
          width: 1.2,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          /// ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(width: 12),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenChuong,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Truyện: $tenTruyen",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Mới cập nhật",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),

          /// DOT
          Icon(
            Icons.circle,
            size: 8,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}