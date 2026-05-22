import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/groq_config.dart';
import '../models/story_model.dart';
import 'story_query_service.dart';

class GroqService {
  static final GroqService _instance = GroqService._internal();
  factory GroqService() => _instance;
  GroqService._internal();
  
  bool _isInitialized = false;
  final List<Map<String, String>> _chatHistory = [];
  final StoryQueryService _storyQueryService = StoryQueryService();
  
  // System prompt cho chatbot
  static const String _systemPrompt = '''
Bạn là trợ lý AI của ứng dụng Comic Manga - một ứng dụng đọc truyện tranh và tiểu thuyết trực tuyến.

VỀ ỨNG DỤNG:
- Ứng dụng có các tính năng: đọc truyện, tìm kiếm, gợi ý, mua truyện, quản lý tài khoản
- Có các thể loại: Tiên Hiệp, Kiếm Hiệp, Ngôn Tình, Đam Mỹ, Bách Hợp, Quan Trường, Huyền Huyễn, Khoa Huyễn, Võng Du, Đô Thị, Lịch Sử, Trinh Thám, Xuyên Không, Trọng Sinh
- Người dùng có thể: đọc truyện miễn phí, mua truyện premium, thêm vào yêu thích, bình luận, đánh giá

PHONG CÁCH TRẢ LỜI:
- Trả lời tự nhiên, thân thiện như một người bạn đang tư vấn truyện
- KHÔNG dùng từ kỹ thuật như "keywords", "query", "database"
- Khi giới thiệu truyện, dùng các cụm từ tự nhiên như:
  • "Đây là những truyện mình tìm được cho bạn..."
  • "Mình có vài gợi ý hay ho đây..."
  • "Bạn thử xem mấy truyện này nhé..."
  • "Đây là các truyện phù hợp với sở thích của bạn..."
  • "Mình nghĩ bạn sẽ thích những truyện này..."
- Tạo cảm giác cá nhân hóa, như đang tư vấn riêng cho từng người

KHẢ NĂNG TÌM KIẾM TRUYỆN THÔNG MINH:
- Bạn có thể tìm kiếm và gợi ý truyện từ cơ sở dữ liệu
- Khi người dùng hỏi về truyện (tìm truyện, gợi ý truyện, truyện hay, etc.), hãy phân tích yêu cầu và trả về format đặc biệt:

[STORY_QUERY]
keywords: từ khóa tìm kiếm (cách nhau bởi dấu phẩy, viết thường không dấu)
category: thể loại (nếu có)
isFree: true/false (nếu người dùng yêu cầu miễn phí hoặc trả phí)
status: trạng thái (nếu có: đang ra, hoàn thành)
sortBy: rating/date/price (nếu người dùng yêu cầu sắp xếp)
limit: số lượng kết quả (mặc định 10)
[/STORY_QUERY]

VÍ DỤ PHÂN TÍCH YÊU CẦU:
- "Tìm truyện tiên hiệp hay" → keywords: tu tien, tu luyen, huyen huyen | category: Tiên Hiệp | sortBy: rating
- "Truyện ngôn tình miễn phí" → keywords: tinh cam, lang man | category: Ngôn Tình | isFree: true
- "Truyện mới nhất" → sortBy: date
- "Truyện tu tiên có yếu tố xuyên không" → keywords: tu tien, xuyen khong | category: Tiên Hiệp
- "Truyện của tác giả Ngã Ăn Tây Hồng Thị" → keywords: nga an tay hong thi
- "Top 5 truyện kiếm hiệp hay nhất" → keywords: kiem hiep, vo hiep | category: Kiếm Hiệp | sortBy: rating | limit: 5
- "Truyện đam mỹ hiện đại" → keywords: hien dai, boys love | category: Đam Mỹ
- "Truyện võng du có yếu tố game" → keywords: game, rpg, ao | category: Võng Du

HƯỚNG DẪN TẠO KEYWORDS:
1. Phân tích ý định người dùng và trích xuất các từ khóa chính
2. Chuyển đổi sang tiếng Việt không dấu, viết thường
3. Bao gồm: thể loại, chủ đề, cảm xúc, bối cảnh, nhân vật
4. Sử dụng từ đồng nghĩa và từ liên quan (vd: "tu tiên" → "tu tien, tu luyen, huyen huyen")
5. Nếu người dùng nhắc tên tác giả, thêm tên tác giả vào keywords

HƯỚNG DẪN TRẢ LỜI:
1. Luôn trả lời bằng tiếng Việt, thân thiện và nhiệt tình
2. Tập trung vào các chủ đề liên quan đến truyện tranh, tiểu thuyết và ứng dụng
3. Nếu người dùng hỏi về tính năng, hãy giải thích rõ ràng và đưa ra hướng dẫn cụ thể
4. Nếu người dùng muốn gợi ý truyện, phân tích yêu cầu và trả về [STORY_QUERY]
5. Nếu người dùng hỏi về kỹ thuật ngoài phạm vi, hãy nói bạn chỉ có thể giúp về truyện và ứng dụng
6. Giữ câu trả lời ngắn gọn, dễ hiểu, có thể sử dụng bullet points khi cần
7. Luôn kết thúc bằng câu hỏi mở để tiếp tục cuộc trò chuyện

VÍ DỤ CÂU TRẢ LỜI:
- "Bạn muốn tìm thể loại truyện nào? Tôi có thể gợi ý cho bạn!"
- "Để mua truyện, bạn vào trang chi tiết truyện và nhấn nút 'Mua truyện' nhé!"
- "Bạn thích thể loại nào? Tôi sẽ gợi ý những truyện hay nhất trong thể loại đó."

HÃY BẮT ĐẦU TRÒ CHUYỆN!
''';

  /// Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Kiểm tra API key đã được cấu hình chưa
      if (!GroqConfig.isConfigured) {
        throw Exception(GroqConfig.configErrorMessage);
      }
      
      // Thêm system prompt vào lịch sử
      _chatHistory.add({
        'role': 'system',
        'content': _systemPrompt,
      });
      
      _isInitialized = true;
      // ignore: avoid_print
      print('✅ GroqService initialized successfully');
    } catch (e) {
      // ignore: avoid_print
      print('❌ GroqService initialization error: $e');
      rethrow;
    }
  }

  /// Gửi tin nhắn và nhận phản hồi từ Groq (kèm stories nếu có)
  Future<Map<String, dynamic>> sendMessageWithStories(String message) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Thêm tin nhắn user vào lịch sử
      _chatHistory.add({
        'role': 'user',
        'content': message,
      });
      
      // Gọi Groq API
      final response = await http.post(
        Uri.parse(GroqConfig.apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${GroqConfig.apiKey}',
        },
        body: json.encode({
          'model': GroqConfig.model,
          'messages': _chatHistory,
          'temperature': 0.7,
          'max_tokens': 1024,
          'top_p': 1,
          'stream': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final assistantMessage = data['choices'][0]['message']['content'] as String;
        
        // Thêm phản hồi vào lịch sử
        _chatHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
        });
        
        // 🔥 Kiểm tra xem có phải là story query không
        if (assistantMessage.contains('[STORY_QUERY]')) {
          final result = await _handleStoryQueryWithStories(assistantMessage);
          return result;
        }
        
        return {
          'message': assistantMessage,
          'stories': null,
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('Groq API error: $errorMessage');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Groq API error: $e');
      
      // Xóa tin nhắn user khỏi lịch sử nếu lỗi
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
      
      // Fallback responses nếu API lỗi
      if (e.toString().contains('API key') || e.toString().contains('Unauthorized')) {
        return {
          'message': 'Lỗi API key. Vui lòng kiểm tra API key trong file:\nlib/config/groq_config.dart\n\n'
              'Lấy API key MIỄN PHÍ tại:\nhttps://console.groq.com/keys',
          'stories': null,
        };
      } else if (e.toString().contains('rate_limit') || e.toString().contains('quota')) {
        return {
          'message': '⚠️ Đã hết quota API!\n\n'
              'Groq miễn phí có giới hạn:\n'
              '• 30 requests/phút\n'
              '• 14400 requests/ngày\n\n'
              'Giải pháp:\n'
              '1. Đợi 1 phút rồi thử lại\n'
              '2. Tạo API key mới tại:\n'
              '   https://console.groq.com/keys',
          'stories': null,
        };
      } else if (e.toString().contains('model') || e.toString().contains('not found')) {
        return {
          'message': 'Lỗi model. Vui lòng kiểm tra tên model trong:\nlib/config/groq_config.dart\n\n'
              'Models khả dụng:\n'
              '• llama-3.3-70b-versatile\n'
              '• llama-3.1-70b-versatile\n'
              '• mixtral-8x7b-32768',
          'stories': null,
        };
      } else if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        return {
          'message': 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.',
          'stories': null,
        };
      }
      
      return {
        'message': 'Xin lỗi, có lỗi xảy ra: ${e.toString()}\n\nVui lòng thử lại sau!',
        'stories': null,
      };
    }
  }

  /// Gửi tin nhắn và nhận phản hồi từ Groq
  Future<String> sendMessage(String message) async {
    final result = await sendMessageWithStories(message);
    return result['message'] as String;
  }

  /// Gửi tin nhắn và nhận phản hồi kèm danh sách truyện đầy đủ (formatted text)
  /// 
  /// Khác với sendMessageWithStories, phương thức này trả về text đã format
  /// bao gồm cả danh sách truyện chi tiết trong message
  Future<String> sendMessageWithFormattedStories(String message) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Thêm tin nhắn user vào lịch sử
      _chatHistory.add({
        'role': 'user',
        'content': message,
      });
      
      // Gọi Groq API
      final response = await http.post(
        Uri.parse(GroqConfig.apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${GroqConfig.apiKey}',
        },
        body: json.encode({
          'model': GroqConfig.model,
          'messages': _chatHistory,
          'temperature': 0.7,
          'max_tokens': 1024,
          'top_p': 1,
          'stream': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final assistantMessage = data['choices'][0]['message']['content'] as String;
        
        // Thêm phản hồi vào lịch sử
        _chatHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
        });
        
        // 🔥 Kiểm tra xem có phải là story query không
        if (assistantMessage.contains('[STORY_QUERY]')) {
          return await _handleStoryQuery(assistantMessage);
        }
        
        return assistantMessage;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('Groq API error: $errorMessage');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Groq API error: $e');
      
      // Xóa tin nhắn user khỏi lịch sử nếu lỗi
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
      
      rethrow;
    }
  }

  /// Xóa lịch sử chat
  Future<void> clearChatHistory() async {
    _chatHistory.clear();
    
    // Thêm lại system prompt
    _chatHistory.add({
      'role': 'system',
      'content': _systemPrompt,
    });
  }

  /// 🔥 Xử lý story query từ AI response (trả về cả stories)
  /// 
  /// Parse [STORY_QUERY] block và gọi StoryQueryService để tìm truyện
  Future<Map<String, dynamic>> _handleStoryQueryWithStories(String aiResponse) async {
    try {
      // ignore: avoid_print
      print('🔍 Handling story query...');

      // Parse query parameters từ [STORY_QUERY] block
      final queryParams = _parseStoryQuery(aiResponse);
      
      if (queryParams.isEmpty) {
        return {
          'message': aiResponse,
          'stories': null,
        };
      }

      // Trích xuất parameters
      final keywords = queryParams['keywords'] as List<String>?;
      final category = queryParams['category'] as String?;
      final isFree = queryParams['isFree'] as bool?;
      final status = queryParams['status'] as String?;
      final sortBy = queryParams['sortBy'] as String?;
      final limit = queryParams['limit'] as int? ?? 10;

      // ignore: avoid_print
      print('📋 Query params: keywords=$keywords, category=$category, isFree=$isFree, status=$status, sortBy=$sortBy, limit=$limit');

      // Gọi StoryQueryService để tìm truyện
      final stories = await _storyQueryService.queryStories(
        keywords: keywords,
        category: category,
        isFree: isFree,
        status: status,
        sortBy: sortBy,
        limit: limit,
      );

      // ignore: avoid_print
      print('✅ Found ${stories.length} stories');

      // Format response text (không bao gồm danh sách truyện)
      final messageText = _formatStoryResultsText(aiResponse, stories.length);

      return {
        'message': messageText,
        'stories': stories,
      };
    } catch (e) {
      // ignore: avoid_print
      print('❌ _handleStoryQueryWithStories error: $e');
      return {
        'message': aiResponse,
        'stories': null,
      };
    }
  }

  /// 🔥 Xử lý story query từ AI response
  /// 
  /// Parse [STORY_QUERY] block và gọi StoryQueryService để tìm truyện
  /// Trả về text đã format bao gồm danh sách truyện chi tiết
  Future<String> _handleStoryQuery(String aiResponse) async {
    try {
      // ignore: avoid_print
      print('🔍 Handling story query with formatted results...');

      // Parse query parameters từ [STORY_QUERY] block
      final queryParams = _parseStoryQuery(aiResponse);
      
      if (queryParams.isEmpty) {
        return aiResponse;
      }

      // Trích xuất parameters
      final keywords = queryParams['keywords'] as List<String>?;
      final category = queryParams['category'] as String?;
      final isFree = queryParams['isFree'] as bool?;
      final status = queryParams['status'] as String?;
      final sortBy = queryParams['sortBy'] as String?;
      final limit = queryParams['limit'] as int? ?? 10;

      // ignore: avoid_print
      print('📋 Query params: keywords=$keywords, category=$category, isFree=$isFree, status=$status, sortBy=$sortBy, limit=$limit');

      // Gọi StoryQueryService để tìm truyện
      final stories = await _storyQueryService.queryStories(
        keywords: keywords,
        category: category,
        isFree: isFree,
        status: status,
        sortBy: sortBy,
        limit: limit,
      );

      // ignore: avoid_print
      print('✅ Found ${stories.length} stories');

      // Format response với danh sách truyện đầy đủ
      return _formatStoryResults(aiResponse, stories);
    } catch (e) {
      // ignore: avoid_print
      print('❌ _handleStoryQuery error: $e');
      return aiResponse;
    }
  }

  /// Parse [STORY_QUERY] block từ AI response
  Map<String, dynamic> _parseStoryQuery(String response) {
    try {
      final startTag = '[STORY_QUERY]';
      final endTag = '[/STORY_QUERY]';
      
      if (!response.contains(startTag) || !response.contains(endTag)) {
        return {};
      }

      final startIndex = response.indexOf(startTag) + startTag.length;
      final endIndex = response.indexOf(endTag);
      
      if (startIndex >= endIndex) return {};

      final queryBlock = response.substring(startIndex, endIndex).trim();
      final lines = queryBlock.split('\n');
      
      final params = <String, dynamic>{};

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        final parts = line.split(':');
        if (parts.length < 2) continue;

        final key = parts[0].trim();
        final value = parts.sublist(1).join(':').trim();

        if (value.isEmpty) continue;

        // Parse theo type
        if (key == 'keywords') {
          params[key] = value
              .split(',')
              .map((k) => k.trim())
              .where((k) => k.isNotEmpty)
              .toList();
        } else if (key == 'isFree') {
          params[key] = value.toLowerCase() == 'true';
        } else if (key == 'limit') {
          params[key] = int.tryParse(value) ?? 10;
        } else {
          params[key] = value;
        }
      }

      return params;
    } catch (e) {
      // ignore: avoid_print
      print('❌ _parseStoryQuery error: $e');
      return {};
    }
  }

  /// Format kết quả tìm kiếm truyện (chỉ text, không bao gồm danh sách)
  String _formatStoryResultsText(String originalResponse, int storyCount) {
    // Loại bỏ [STORY_QUERY] block khỏi response
    String cleanResponse = originalResponse;
    final startTag = '[STORY_QUERY]';
    final endTag = '[/STORY_QUERY]';
    
    if (cleanResponse.contains(startTag) && cleanResponse.contains(endTag)) {
      final startIndex = cleanResponse.indexOf(startTag);
      final endIndex = cleanResponse.indexOf(endTag) + endTag.length;
      cleanResponse = cleanResponse.substring(0, startIndex) + 
                     cleanResponse.substring(endIndex);
    }
    
    cleanResponse = cleanResponse.trim();

    // Nếu không tìm thấy truyện
    if (storyCount == 0) {
      return 'Hmm... mình không tìm thấy truyện nào phù hợp với yêu cầu của bạn 😔\n\n'
          'Bạn có thể thử:\n'
          '• Mô tả chi tiết hơn về loại truyện bạn muốn\n'
          '• Thử thể loại khác\n'
          '• Hỏi mình về các truyện hot/mới nhất nhé!';
    }

    // Các cụm từ giới thiệu tự nhiên
    final introductions = [
      'Đây là những truyện mình tìm được cho bạn',
      'Mình có vài gợi ý hay ho đây',
      'Bạn thử xem mấy truyện này nhé',
      'Đây là các truyện phù hợp với sở thích của bạn',
      'Mình nghĩ bạn sẽ thích những truyện này',
      'Có $storyCount truyện hay mà bạn có thể thích',
    ];
    
    // Chọn ngẫu nhiên một cụm từ
    final intro = introductions[DateTime.now().millisecond % introductions.length];

    // Nếu có cleanResponse từ AI, dùng nó
    if (cleanResponse.isNotEmpty && !cleanResponse.contains('[STORY_QUERY]')) {
      return '$cleanResponse\n\n📚 Nhấn vào truyện để xem chi tiết nhé!';
    }

    // Nếu không có, dùng intro mặc định
    return '$intro! 📚\n\nNhấn vào truyện để xem chi tiết và đọc ngay nhé!';
  }

  /// Format kết quả tìm kiếm truyện
  String _formatStoryResults(String originalResponse, List<Story> stories) {
    // Loại bỏ [STORY_QUERY] block khỏi response
    String cleanResponse = originalResponse;
    final startTag = '[STORY_QUERY]';
    final endTag = '[/STORY_QUERY]';
    
    if (cleanResponse.contains(startTag) && cleanResponse.contains(endTag)) {
      final startIndex = cleanResponse.indexOf(startTag);
      final endIndex = cleanResponse.indexOf(endTag) + endTag.length;
      cleanResponse = cleanResponse.substring(0, startIndex) + 
                     cleanResponse.substring(endIndex);
    }
    
    cleanResponse = cleanResponse.trim();

    // Nếu không tìm thấy truyện
    if (stories.isEmpty) {
      return '$cleanResponse\n\n'
          '😔 Xin lỗi, tôi không tìm thấy truyện phù hợp với yêu cầu của bạn.\n\n'
          'Bạn có thể thử:\n'
          '• Mô tả chi tiết hơn về loại truyện bạn muốn\n'
          '• Thử thể loại khác\n'
          '• Hỏi về các truyện hot/mới nhất';
    }

    // Format danh sách truyện
    final buffer = StringBuffer();
    buffer.writeln(cleanResponse);
    buffer.writeln();
    buffer.writeln('📚 Tôi tìm thấy ${stories.length} truyện phù hợp:');
    buffer.writeln();

    for (var i = 0; i < stories.length; i++) {
      final story = stories[i];
      buffer.writeln('${i + 1}. **${story.title}**');
      buffer.writeln('   👤 Tác giả: ${story.author}');
      buffer.writeln('   📂 Thể loại: ${story.category}');
      
      if (story.status.isNotEmpty) {
        buffer.writeln('   📊 Trạng thái: ${story.status}');
      }
      
      buffer.writeln('   💰 ${story.isFree ? "Miễn phí" : "${story.price.toInt()} xu"}');
      
      if (story.description.isNotEmpty) {
        final shortDesc = story.description.length > 100
            ? '${story.description.substring(0, 100)}...'
            : story.description;
        buffer.writeln('   📝 $shortDesc');
      }
      
      buffer.writeln();
    }

    buffer.writeln('💡 Nhấn vào truyện để xem chi tiết và đọc ngay!');

    return buffer.toString();
  }

  /// Kiểm tra xem service đã được khởi tạo chưa
  bool get isInitialized => _isInitialized;
  
  /// Kiểm tra xem API key có được cấu hình chưa
  bool get isConfigured => GroqConfig.isConfigured;
}
