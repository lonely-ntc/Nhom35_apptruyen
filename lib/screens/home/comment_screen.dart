import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/user_service.dart';

class CommentScreen extends StatefulWidget {
  final String storyId;

  const CommentScreen({super.key, required this.storyId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final db = DatabaseService.instance;
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
    final avatar =
        c['avatar'] ?? "assets/avatars/avatar1.png"; // 🔥 FIX

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(avatar),
      ),
      title: Text(c['content'] ?? ""),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c['userName'] ?? "Người dùng"),
          Text(
            _formatTime(c['createdAt']),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
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

    try {
      /// 🔥 LẤY AVATAR
      final avatar = await UserService.instance.getAvatar();

      await db.addComment(
        storyId: widget.storyId,
        userId: user.uid,
        content: text,
        userName: user.displayName ?? "Người dùng",
        avatar: avatar, // 🔥 FIX QUAN TRỌNG
      );

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