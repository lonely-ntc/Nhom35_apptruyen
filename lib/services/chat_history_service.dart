import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story_model.dart';

/// Lưu và load lịch sử chat vào SharedPreferences
class ChatHistoryService {
  static const String _sessionsKey = 'chat_sessions_v1';
  static const int _maxSessions = 50; // Giới hạn số phiên chat

  /// Lưu một phiên chat mới
  static Future<void> saveSession(List<ChatHistoryMessage> messages) async {
    if (messages.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load các phiên hiện có
      final sessions = await loadSessions();
      
      // Tạo phiên mới
      final newSession = ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        messages: messages,
        preview: _generatePreview(messages),
      );
      
      // Thêm phiên mới vào đầu danh sách
      sessions.insert(0, newSession);
      
      // Giới hạn số phiên
      if (sessions.length > _maxSessions) {
        sessions.removeRange(_maxSessions, sessions.length);
      }
      
      // Lưu lại
      final list = sessions.map((s) => s.toJson()).toList();
      await prefs.setString(_sessionsKey, jsonEncode(list));
    } catch (e) {
      // ignore
    }
  }

  /// Load tất cả các phiên chat
  static Future<List<ChatSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionsKey);
      if (raw == null || raw.isEmpty) return [];

      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Load một phiên chat cụ thể
  static Future<ChatSession?> loadSession(String sessionId) async {
    final sessions = await loadSessions();
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  /// Xóa một phiên chat
  static Future<void> deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await loadSessions();
      sessions.removeWhere((s) => s.id == sessionId);
      
      final list = sessions.map((s) => s.toJson()).toList();
      await prefs.setString(_sessionsKey, jsonEncode(list));
    } catch (e) {
      // ignore
    }
  }

  /// Xóa toàn bộ lịch sử
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }

  /// Tạo preview cho phiên chat (tin nhắn đầu tiên của user)
  static String _generatePreview(List<ChatHistoryMessage> messages) {
    // Tìm tin nhắn đầu tiên của user
    final userMessage = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => messages.first,
    );
    
    final text = userMessage.text;
    if (text.length <= 50) return text;
    return '${text.substring(0, 50)}...';
  }

  // ===== LEGACY METHODS (để tương thích với code cũ) =====
  
  /// Load lịch sử chat (legacy - trả về rỗng)
  static Future<List<ChatHistoryMessage>> load() async {
    return [];
  }

  /// Lưu lịch sử chat (legacy - chuyển sang saveSession)
  static Future<void> save(List<ChatHistoryMessage> messages) async {
    await saveSession(messages);
  }
}

/// Model cho một phiên chat
class ChatSession {
  final String id;
  final DateTime timestamp;
  final List<ChatHistoryMessage> messages;
  final String preview;

  ChatSession({
    required this.id,
    required this.timestamp,
    required this.messages,
    required this.preview,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'messages': messages.map((m) => m.toJson()).toList(),
        'preview': preview,
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] as int? ?? 0),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) =>
                  ChatHistoryMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preview: json['preview'] as String? ?? '',
    );
  }
}

/// Model đơn giản để serialize/deserialize ChatMessage
/// (không phụ thuộc vào Story object để tránh vòng lặp)
class ChatHistoryMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  // Lưu stories dưới dạng JSON-serializable
  final List<Map<String, dynamic>>? storiesData;

  ChatHistoryMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.storiesData,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'storiesData': storiesData,
      };

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? stories;
    if (json['storiesData'] != null) {
      stories = (json['storiesData'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return ChatHistoryMessage(
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] as int? ?? 0),
      storiesData: stories,
    );
  }

  /// Convert storiesData → List<Story>
  List<Story>? get stories {
    if (storiesData == null) return null;
    return storiesData!.map((data) {
      // Hỗ trợ cả Firestore format và SQLite format
      if (data.containsKey('title')) {
        return Story.fromFirestore(data);
      }
      return Story.fromMap(data);
    }).toList();
  }
}
