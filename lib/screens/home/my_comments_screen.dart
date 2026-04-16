import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 THÊM
import '../../services/database_service.dart';

class MyCommentsScreen extends StatelessWidget {
  const MyCommentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final user = FirebaseAuth.instance.currentUser; // 🔥 FIX

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
        stream: db.getUserComments(user.uid), // 🔥 FIX QUAN TRỌNG
        builder: (context, snapshot) {
          /// 🔥 DEBUG
          print("==== SNAPSHOT ====");
          print("hasData: ${snapshot.hasData}");
          print("data: ${snapshot.data}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ KHÔNG CÓ DATA
          if (!snapshot.hasData) {
            return const Center(
              child: Text("Không load được dữ liệu"),
            );
          }

          final comments = snapshot.data!;

          /// ❌ DATA RỖNG
          if (comments.isEmpty) {
            return const Center(
              child: Text("Chưa có bình luận"),
            );
          }

          /// ✅ CÓ DATA
          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final c = comments[index];

              /// 🔥 DEBUG TỪNG COMMENT
              print("🔥 COMMENT ITEM: $c");

              return _buildItem(c);
            },
          );
        },
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> c) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(
          c['content'] ?? 'Không có nội dung',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            /// 🔥 STORY ID
            Text("📖 ${c['storyId'] ?? 'unknown'}"),

            const SizedBox(height: 2),

            /// 🔥 TIME
            Text(
              c['createdAt'] != null
                  ? _formatTime(c['createdAt'])
                  : 'Không có thời gian',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
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