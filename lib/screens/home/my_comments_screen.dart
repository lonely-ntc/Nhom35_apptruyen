import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';
import 'comment_screen.dart';

class MyCommentsScreen extends StatelessWidget {
  const MyCommentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text("Bạn chưa đăng nhập"),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Bình luận của tôi"),
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.getUserComments(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text("Lỗi: ${snapshot.error}"),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.comment_outlined,
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
                    "Hãy đọc truyện và để lại bình luận nhé!",
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          final comments = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final comment = comments[index];
              return _buildCommentCard(context, comment, theme, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildCommentCard(
    BuildContext context,
    Map<String, dynamic> comment,
    ThemeData theme,
    bool isDark,
  ) {
    return FutureBuilder<String>(
      future: UserService.instance.getAvatar(),
      builder: (context, avatarSnapshot) {
        final avatar = avatarSnapshot.data ?? "assets/avatars/avatar1.png";

        return GestureDetector(
          onTap: () => _navigateToStory(context, comment),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER: Avatar + Name + Time
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(avatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['userName'] ?? 'Người dùng',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            comment['createdAt'] != null
                                ? _formatTime(comment['createdAt'])
                                : 'Không rõ thời gian',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// COMMENT CONTENT
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]?.withOpacity(0.3)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    comment['content'] ?? 'Không có nội dung',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// STORY INFO
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryPurple.withOpacity(0.1),
                        AppColors.primaryPurple.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryPurple.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          comment['storyId'] ?? 'Không rõ truyện',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPurple,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.primaryPurple,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Navigate to comment screen of the story
  void _navigateToStory(
    BuildContext context,
    Map<String, dynamic> comment,
  ) {
    final storyTitle = comment['storyId'] as String?;
    if (storyTitle == null || storyTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin truyện'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to comment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentScreen(storyId: storyTitle),
      ),
    );
  }

  String _formatTime(Timestamp time) {
    final date = time.toDate();
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
