import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 THÊM
import '../../services/database_service.dart';

class CommentScreen extends StatefulWidget {
  final String storyId;

  const CommentScreen({super.key, required this.storyId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final db = DatabaseService.instance;
  final TextEditingController _controller = TextEditingController();

  /// ❌ XOÁ user_1
  /// final String userId = "user_1";

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // 🔥 FIX

    return Scaffold(
      appBar: AppBar(title: const Text("Bình luận")),

      body: Column(
        children: [
          /// ===== LIST COMMENT =====
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: db.getComments(widget.storyId),
              builder: (_, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return const Center(
                      child: Text("Chưa có bình luận"));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (_, index) {
                    final c = comments[index];
                    return _buildCommentItem(c);
                  },
                );
              },
            ),
          ),

          /// ===== INPUT COMMENT =====
          _buildInput(user),
        ],
      ),
    );
  }

  /// ================= ITEM =================
  Widget _buildCommentItem(Map<String, dynamic> c) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text(c['content'] ?? ""),
      subtitle: Text(_formatTime(c['createdAt'])),
    );
  }

  /// ================= INPUT =================
  Widget _buildInput(User? user) {
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("Bạn cần đăng nhập để bình luận"),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Nhập bình luận...",
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.deepPurple),
            onPressed: () => _sendComment(user),
          )
        ],
      ),
    );
  }

  /// ================= SEND =================
  void _sendComment(User user) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    print("🔥 USER ID: ${user.uid}");
    print("🔥 STORY ID: ${widget.storyId}");
    print("🔥 CONTENT: $text");

    try {
      await db.addComment(
        storyId: widget.storyId,
        userId: user.uid, // 🔥 FIX QUAN TRỌNG
        content: text,
      );

      print("✅ COMMENT SAVED");

      _controller.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã gửi bình luận")),
      );
    } catch (e) {
      print("❌ ERROR: $e");
    }
  }

  /// ================= FORMAT TIME =================
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";

    final date = (timestamp as Timestamp).toDate();
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