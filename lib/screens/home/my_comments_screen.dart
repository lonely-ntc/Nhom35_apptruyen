import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/user_service.dart'; // 🔥 THÊM

class MyCommentsScreen extends StatelessWidget {
  const MyCommentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Bạn chưa đăng nhập")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bình luận của tôi"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.getUserComments(user.uid),
        builder: (context, snapshot) {
          /// DEBUG
          print("==== SNAPSHOT ====");
          print("hasData: ${snapshot.hasData}");
          print("data: ${snapshot.data}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("Không load được dữ liệu"),
            );
          }

          final comments = snapshot.data!;

          if (comments.isEmpty) {
            return const Center(
              child: Text("Chưa có bình luận"),
            );
          }

          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final c = comments[index];

              print("🔥 COMMENT ITEM: $c");

              return _buildItem(c);
            },
          );
        },
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> c) {
    return FutureBuilder<String>(
      future: UserService.instance.getAvatar(), // 🔥 FIX CHUẨN
      builder: (context, snapshot) {
        final avatar =
            snapshot.data ?? "assets/avatars/avatar1.png";

        return Card(
          margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(avatar),
            ),
            title: Text(
              c['content'] ?? 'Không có nội dung',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                /// USER NAME
                Text(
                  c['userName'] ?? 'Người dùng',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 2),

                /// STORY
                Text("📖 ${c['storyId'] ?? 'unknown'}"),

                const SizedBox(height: 2),

                /// TIME
                Text(
                  c['createdAt'] != null
                      ? _formatTime(c['createdAt'])
                      : 'Không có thời gian',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(Timestamp time) {
    final date = time.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} phút trước";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} giờ trước";
    } else {
      return "${diff.inDays} ngày trước";
    }
  }
}