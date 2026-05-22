import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/groq_service.dart';
import '../../services/chat_history_service.dart';
import '../../models/story_model.dart';
import '../../widgets/story_result_card.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_styles.dart';
import 'chat_history_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _apiError = false;
  String _errorMessage = '';
  final GroqService _groqService = GroqService();

  late AnimationController _typingAnimController;
  late AnimationController _sendBtnController;
  late Animation<double> _sendBtnScale;

  // Quick suggestion chips
  final List<String> _suggestions = [
    '📚 Truyện tiên hiệp hay',
    '💕 Ngôn tình miễn phí',
    '🔥 Truyện hot nhất',
    '⚔️ Kiếm hiệp đặc sắc',
    '🎮 Truyện võng du',
    '🌸 Đam mỹ hiện đại',
  ];

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _sendBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _sendBtnScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _sendBtnController, curve: Curves.easeInOut),
    );

    _messageController.addListener(() => setState(() {}));
    _initializeGroq();
  }

  Future<void> _initializeGroq() async {
    try {
      await _groqService.initialize();
      if (!mounted) return;

      setState(() {
        // Luôn bắt đầu với tin nhắn chào mừng mới
        _messages.add(ChatMessage(
          text: 'Xin chào! Tôi là trợ lý AI của Comic Manga. Tôi có thể giúp bạn tìm truyện, gợi ý truyện hay, hoặc trả lời các câu hỏi về ứng dụng. Bạn cần giúp gì?',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      // Scroll xuống cuối sau khi load
      Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = true;
        _errorMessage = 'Lỗi khởi tạo AI. Vui lòng kiểm tra API key trong:\nlib/config/groq_config.dart';
        _messages.add(ChatMessage(
          text: 'Xin chào! Hiện tại AI đang gặp sự cố. Vui lòng kiểm tra cấu hình API key.\n\nBạn vẫn có thể sử dụng chế độ fallback với các câu hỏi cơ bản.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  /// Lưu lịch sử sau mỗi tin nhắn
  Future<void> _saveHistory() async {
    final toSave = _messages.map((m) => ChatHistoryMessage(
          text: m.text,
          isUser: m.isUser,
          timestamp: m.timestamp,
          storiesData: m.stories
              ?.map((s) => s.toFirestore()..['image'] = s.image)
              .toList(),
        )).toList();
    await ChatHistoryService.save(toSave);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimController.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    _sendBtnController.forward().then((_) => _sendBtnController.reverse());

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      if (quickText == null) _messageController.clear();
      _isTyping = true;
      _apiError = false;
    });

    _scrollToBottom();

    try {
      final responseData = await _groqService.sendMessageWithStories(text);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: responseData['message'] as String,
          isUser: false,
          timestamp: DateTime.now(),
          stories: responseData['stories'] as List<Story>?,
        ));
        _isTyping = false;
      });
      _scrollToBottom();
      _saveHistory(); // ← lưu lịch sử
    } catch (e) {
      if (!mounted) return;
      final fallback = _generateFallbackResponse(text);
      setState(() {
        _messages.add(ChatMessage(
          text: fallback,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
        _apiError = true;
        _errorMessage = 'Đang sử dụng chế độ fallback: $e';
      });
      _scrollToBottom();
      _saveHistory(); // ← lưu lịch sử
    }
  }

  String _generateFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
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
          'Hệ thống sẽ tự động gợi ý truyện phù hợp!';
    }
    return 'Cảm ơn bạn đã nhắn tin! Bạn có thể hỏi tôi về:\n'
        '• Cách tìm và đọc truyện\n'
        '• Gợi ý truyện hay\n'
        '• Hướng dẫn sử dụng tính năng\n\n'
        'Hoặc gõ "giúp" để xem danh sách đầy đủ!';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF4F3FF),
      appBar: _buildAppBar(theme, isDark),
      body: Column(
        children: [
          if (_apiError) _buildErrorBanner(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(theme)
                : _buildMessageList(theme, isDark),
          ),
          if (_isTyping) _buildTypingBubble(isDark),
          _buildSuggestions(isDark),
          _buildInputBar(theme, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: theme.iconTheme.color, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar with gradient + pulse ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.purpleGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 22),
              ),
              // Online dot
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _isTyping ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
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
                  letterSpacing: -0.3,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isTyping ? 'Đang trả lời...' : 'Trực tuyến',
                  key: ValueKey(_isTyping),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isTyping ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: theme.iconTheme.color),
          onPressed: () => _showOptionsMenu(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              shape: BoxShape.circle,
              boxShadow: [AppStyles.purpleShadow],
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 52, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'Bắt đầu trò chuyện',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Hỏi tôi bất cứ điều gì về truyện!',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final showAvatar = !msg.isUser &&
            (index == 0 || _messages[index - 1].isUser);
        return _buildMessageItem(msg, theme, isDark, showAvatar);
      },
    );
  }

  Widget _buildMessageItem(
      ChatMessage message, ThemeData theme, bool isDark, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          if (!message.isUser) ...[
            if (showAvatar)
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: const BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 18),
              )
            else
              const SizedBox(width: 42),
          ],

          // Bubble + stories
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? AppColors.purpleGradient
                        : null,
                    color: message.isUser
                        ? null
                        : (isDark
                            ? AppColors.darkCard
                            : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft:
                          Radius.circular(message.isUser ? 18 : 4),
                      bottomRight:
                          Radius.circular(message.isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isUser
                            ? AppColors.primaryPurple.withOpacity(0.25)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : theme.textTheme.bodyLarge?.color,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                ),

                // Story cards
                if (message.stories != null &&
                    message.stories!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  // LayoutBuilder để card biết chính xác width tối đa
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: message.stories!.asMap().entries.map((entry) {
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

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color
                          ?.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User avatar
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded,
                  color: AppColors.primaryPurple, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              gradient: AppColors.purpleGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimController,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = (_typingAnimController.value - i * 0.2)
                        .clamp(0.0, 1.0);
                    final offset = (t < 0.5 ? t : 1.0 - t) * 2;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Transform.translate(
                        offset: Offset(0, -offset * 5),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple
                                .withOpacity(0.5 + offset * 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    // Only show when no messages or last message is from AI
    final showSuggestions = _messages.isEmpty ||
        (!_isTyping &&
            _messages.isNotEmpty &&
            !_messages.last.isUser);
    if (!showSuggestions) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(_suggestions[index]
                .replaceAll(RegExp(r'^[^\s]+ '), '')),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryPurple.withOpacity(0.2)
                    : AppColors.primaryPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                ),
              ),
              child: Text(
                _suggestions[index],
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, bool isDark) {
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : const Color(0xFFF4F3FF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? AppColors.primaryPurple.withOpacity(0.5)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodySmall?.color
                          ?.withOpacity(0.45),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(fontSize: 14.5),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            ScaleTransition(
              scale: _sendBtnScale,
              child: GestureDetector(
                onTap: hasText ? _sendMessage : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: hasText
                        ? AppColors.purpleGradient
                        : const LinearGradient(
                            colors: [Color(0xFFCCCCCC), Color(0xFFBBBBBB)]),
                    shape: BoxShape.circle,
                    boxShadow: hasText ? [AppStyles.purpleShadow] : [],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.orange[800], fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.history_rounded,
                    color: AppColors.primaryPurple, size: 20),
              ),
              title: const Text('Xem lịch sử chat'),
              onTap: () {
                Navigator.pop(context);
                _viewHistory();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 20),
              ),
              title: const Text('Xóa lịch sử chat'),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline_rounded,
                    color: AppColors.primaryPurple, size: 20),
              ),
              title: const Text('Về trợ lý AI'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _clearChat() {
    _groqService.clearChatHistory();
    ChatHistoryService.clear(); // ← xóa lịch sử đã lưu
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: 'Xin chào! Tôi là trợ lý AI của Comic Manga. Tôi có thể giúp bạn tìm truyện, gợi ý truyện hay, hoặc trả lời các câu hỏi về ứng dụng. Bạn cần giúp gì?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatHistoryScreen(),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: AppColors.purpleGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Về trợ lý AI'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Trợ lý AI của Comic Manga giúp bạn:\n\n'
            '• Tìm kiếm và gợi ý truyện\n'
            '• Hướng dẫn sử dụng tính năng\n'
            '• Giải đáp thắc mắc\n'
            '• Hỗ trợ 24/7\n\n'
            'Powered by Groq AI (Llama 3.3)\n'
            'Phiên bản: 1.0.0',
          ),
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
  final List<Story>? stories;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.stories,
  });
}
