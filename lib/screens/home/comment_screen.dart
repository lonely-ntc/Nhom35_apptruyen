import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';

class CommentScreen extends StatefulWidget {
  final String storyId;

  const CommentScreen({super.key, required this.storyId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final db = DatabaseService.instance;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Bình luận"),
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: db.getComments(widget.storyId),
            builder: (_, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.comment,
                            size: 16, color: AppColors.primaryPurple),
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /// ===== LIST COMMENT =====
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: db.getComments(widget.storyId),
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text("Lỗi: ${snapshot.error}"),
                      ],
                    ),
                  );
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          "Chưa có bình luận",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Hãy là người đầu tiên bình luận!",
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, index) {
                    final comment = comments[index];
                    final isCurrentUser = user?.uid == comment['userId'];
                    return _buildCommentItem(
                        comment, theme, isDark, isCurrentUser);
                  },
                );
              },
            ),
          ),

          /// ===== INPUT COMMENT =====
          _buildInput(user, theme, isDark),
        ],
      ),
    );
  }

  /// ================= COMMENT ITEM =================
  Widget _buildCommentItem(
    Map<String, dynamic> comment,
    ThemeData theme,
    bool isDark,
    bool isCurrentUser,
  ) {
    final avatar = comment['avatar'] ?? "assets/avatars/avatar1.png";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// AVATAR
        CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage(avatar),
        ),
        const SizedBox(width: 12),

        /// CONTENT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// NAME + TIME
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment['userName'] ?? "Người dùng",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  if (isCurrentUser)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Bạn",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              /// COMMENT CONTENT
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? AppColors.primaryPurple.withOpacity(0.1)
                      : (isDark
                          ? Colors.grey[800]?.withOpacity(0.3)
                          : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrentUser
                      ? Border.all(
                          color: AppColors.primaryPurple.withOpacity(0.3))
                      : null,
                ),
                child: Text(
                  comment['content'] ?? "",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              /// TIME
              Text(
                _formatTime(comment['createdAt']),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ================= INPUT =================
  Widget _buildInput(User? user, ThemeData theme, bool isDark) {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 20, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              "Bạn cần đăng nhập để bình luận",
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            /// AVATAR
            FutureBuilder<String>(
              future: UserService.instance.getAvatar(),
              builder: (_, snapshot) {
                final avatar =
                    snapshot.data ?? "assets/avatars/avatar1.png";
                return CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage(avatar),
                );
              },
            ),
            const SizedBox(width: 12),

            /// INPUT FIELD
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]?.withOpacity(0.3)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? AppColors.primaryPurple.withOpacity(0.5)
                        : Colors.transparent,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: "Nhập bình luận...",
                    hintStyle:
                        TextStyle(color: theme.textTheme.bodySmall?.color),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(user),
                ),
              ),
            ),
            const SizedBox(width: 8),

            /// SEND BUTTON
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple,
                    AppColors.primaryPurple.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _isSending ? null : () => _sendComment(user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= SEND =================
  void _sendComment(User user) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      // 🔥 Get user data from Firestore (more reliable than Firebase Auth)
      final userProfile = await UserService.instance.getUserProfile(user.uid);
      final userName = userProfile?['displayName'] ?? user.displayName ?? "Người dùng";
      final avatar = userProfile?['avatar'] ?? await UserService.instance.getAvatar();

      await db.addComment(
        storyId: widget.storyId,
        userId: user.uid,
        content: text,
        userName: userName,
        avatar: avatar,
      );

      _controller.clear();
      _focusNode.unfocus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Đã gửi bình luận"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  /// ================= FORMAT TIME =================
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";

    final date = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) {
      return "Vừa xong";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} phút trước";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} giờ trước";
    } else if (diff.inDays < 7) {
      return "${diff.inDays} ngày trước";
    } else if (diff.inDays < 30) {
      return "${(diff.inDays / 7).floor()} tuần trước";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
