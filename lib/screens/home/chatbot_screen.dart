import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_styles.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text: 'Xin chào! Tôi là trợ lý AI của Comic Manga. Tôi có thể giúp bạn tìm truyện, gợi ý truyện hay, hoặc trả lời các câu hỏi về ứng dụng. Bạn cần giúp gì?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      final response = _generateResponse(text);
      
      setState(() {
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });

      _scrollToBottom();
    });
  }

  String _generateResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // Simple keyword-based responses
    if (lowerMessage.contains('tìm') || lowerMessage.contains('truyện')) {
      return 'Bạn có thể tìm truyện bằng cách:\n\n'
          '1. Nhấn vào biểu tượng tìm kiếm ở góc trên\n'
          '2. Vào mục "Khám phá" để xem tất cả truyện\n'
          '3. Chọn thể loại yêu thích ở trang chủ\n\n'
          'Bạn muốn tìm thể loại nào?';
    }

    if (lowerMessage.contains('gợi ý') || lowerMessage.contains('đề xuất')) {
      return 'Để nhận gợi ý truyện phù hợp:\n\n'
          '1. Vào "Tài khoản" → "Cài đặt"\n'
          '2. Chọn "Sở thích của bạn"\n'
          '3. Chọn các thể loại yêu thích\n\n'
          'Hệ thống sẽ tự động gợi ý truyện phù hợp với sở thích của bạn!';
    }

    if (lowerMessage.contains('mua') || lowerMessage.contains('thanh toán')) {
      return 'Để mua truyện:\n\n'
          '1. Mở trang chi tiết truyện\n'
          '2. Nhấn nút "Mua truyện"\n'
          '3. Xác nhận thanh toán\n\n'
          'Sau khi mua, truyện sẽ xuất hiện trong mục "Đã mua" của bạn.';
    }

    if (lowerMessage.contains('yêu thích') || lowerMessage.contains('theo dõi')) {
      return 'Để thêm truyện vào yêu thích:\n\n'
          '1. Mở trang chi tiết truyện\n'
          '2. Nhấn vào biểu tượng trái tim\n\n'
          'Xem danh sách yêu thích tại mục "Yêu thích" ở thanh điều hướng dưới.';
    }

    if (lowerMessage.contains('đọc') || lowerMessage.contains('chương')) {
      return 'Khi đọc truyện, bạn có thể:\n\n'
          '• Chuyển chế độ tối/sáng\n'
          '• Điều chỉnh cỡ chữ\n'
          '• Chuyển chương nhanh\n'
          '• Xem danh sách chương\n'
          '• Viết bình luận\n\n'
          'Nhấn vào màn hình để hiện/ẩn thanh điều khiển.';
    }

    if (lowerMessage.contains('bình luận') || lowerMessage.contains('comment')) {
      return 'Để bình luận:\n\n'
          '1. Mở trang chi tiết truyện\n'
          '2. Nhấn vào biểu tượng bình luận\n'
          '3. Viết nội dung và gửi\n\n'
          'Xem tất cả bình luận của bạn tại "Tài khoản" → "Bình luận của tôi".';
    }

    if (lowerMessage.contains('tài khoản') || lowerMessage.contains('thông tin')) {
      return 'Quản lý tài khoản:\n\n'
          '• Cập nhật thông tin cá nhân\n'
          '• Đổi mật khẩu\n'
          '• Xem lịch sử đọc\n'
          '• Xem truyện đã mua\n'
          '• Quản lý bình luận\n\n'
          'Vào mục "Tài khoản" ở thanh điều hướng để truy cập.';
    }

    if (lowerMessage.contains('thể loại') || lowerMessage.contains('category')) {
      return 'Các thể loại phổ biến:\n\n'
          '• Tiên Hiệp - Kiếm Hiệp\n'
          '• Ngôn Tình - Đam Mỹ\n'
          '• Bách Hợp - Quan Trường\n'
          '• Huyền Huyễn - Khoa Huyễn\n'
          '• Võng Du - Đô Thị\n\n'
          'Nhấn "Xem tất cả" ở mục Thể loại để khám phá thêm!';
    }

    if (lowerMessage.contains('giúp') || lowerMessage.contains('help')) {
      return 'Tôi có thể giúp bạn:\n\n'
          '✓ Tìm và gợi ý truyện\n'
          '✓ Hướng dẫn sử dụng tính năng\n'
          '✓ Giải đáp thắc mắc\n'
          '✓ Hỗ trợ mua truyện\n'
          '✓ Quản lý tài khoản\n\n'
          'Hãy hỏi tôi bất cứ điều gì!';
    }

    // Default response
    return 'Cảm ơn bạn đã nhắn tin! Tôi đang học hỏi để hiểu câu hỏi của bạn tốt hơn.\n\n'
        'Bạn có thể hỏi tôi về:\n'
        '• Cách tìm và đọc truyện\n'
        '• Gợi ý truyện hay\n'
        '• Hướng dẫn sử dụng tính năng\n'
        '• Quản lý tài khoản\n\n'
        'Hoặc gõ "giúp" để xem danh sách đầy đủ!';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                boxShadow: [AppStyles.purpleShadow],
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trợ lý AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isTyping ? 'Đang trả lời...' : 'Trực tuyến',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isTyping 
                        ? AppColors.primaryPurple 
                        : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index], theme, isDark);
                    },
                  ),
          ),
          if (_isTyping) _buildTypingIndicator(theme, isDark),
          _buildInputSection(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              shape: BoxShape.circle,
              boxShadow: [AppStyles.purpleShadow],
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bắt đầu trò chuyện',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hỏi tôi bất cứ điều gì về truyện!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? AppColors.purpleGradient
                        : null,
                    color: message.isUser
                        ? null
                        : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primaryPurple,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = (value - delay).clamp(0.0, 1.0);
        final opacity = (animValue * 2).clamp(0.3, 1.0);
        
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isTyping) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildInputSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                shape: BoxShape.circle,
                boxShadow: [AppStyles.purpleShadow],
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Xóa lịch sử chat'),
                onTap: () {
                  Navigator.pop(context);
                  _clearChat();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Về trợ lý AI'),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          text: 'Xin chào! Tôi là trợ lý AI của Comic Manga. Tôi có thể giúp bạn tìm truyện, gợi ý truyện hay, hoặc trả lời các câu hỏi về ứng dụng. Bạn cần giúp gì?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Về trợ lý AI'),
        content: const Text(
          'Trợ lý AI của Comic Manga giúp bạn:\n\n'
          '• Tìm kiếm và gợi ý truyện\n'
          '• Hướng dẫn sử dụng tính năng\n'
          '• Giải đáp thắc mắc\n'
          '• Hỗ trợ 24/7\n\n'
          'Phiên bản: 1.0.0',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
