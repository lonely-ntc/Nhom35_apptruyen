import 'package:flutter/material.dart';
import '../../services/chat_history_service.dart';
import '../../widgets/story_result_card.dart';
import '../../utils/app_colors.dart';

class ChatSessionDetailScreen extends StatelessWidget {
  final ChatSession session;

  const ChatSessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF4F3FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.iconTheme.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết cuộc trò chuyện',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              _formatDateTime(session.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: session.messages.length,
        itemBuilder: (context, index) {
          final msg = session.messages[index];
          final showAvatar = !msg.isUser &&
              (index == 0 || session.messages[index - 1].isUser);
          return _buildMessageItem(msg, theme, isDark, showAvatar);
        },
      ),
    );
  }

  Widget _buildMessageItem(
    ChatHistoryMessage message,
    ThemeData theme,
    bool isDark,
    bool showAvatar,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            if (showAvatar)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: const BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 16),
              )
            else
              const SizedBox(width: 40),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient:
                        message.isUser ? AppColors.purpleGradient : null,
                    color: message.isUser
                        ? null
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isUser
                            ? AppColors.primaryPurple.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
                if (message.stories != null && message.stories!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children:
                            message.stories!.asMap().entries.map((entry) {
                          return SizedBox(
                            width: constraints.maxWidth,
                            child: StoryResultCard(
                              story: entry.value,
                              index: entry.key,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded,
                  color: AppColors.primaryPurple, size: 18),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      return 'Hôm nay, ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua, ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}, ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
