import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Thông báo",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: đánh dấu tất cả là đã đọc
            },
            child: const Text("Đọc tất cả"),
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
            return const Center(child: Text("Không có thông báo"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildItem(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final tenChuong = item['ten_chuong'] ?? '';
    final tenTruyen = item['ten_truyen'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        /// luôn highlight vì là chương mới
        border: Border.all(color: Colors.deepPurple, width: 1.5),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: Colors.deepPurple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book,
              color: Colors.deepPurple,
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Truyện: $tenTruyen",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Mới cập nhật",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          /// DOT (luôn hiện vì chưa đọc)
          const Icon(Icons.circle, size: 8, color: Colors.deepPurple),
        ],
      ),
    );
  }
}