/// Cấu hình API key cho Groq AI
/// 
/// Lấy API key tại: https://console.groq.com/keys
/// 
/// Hướng dẫn:
/// 1. Truy cập https://console.groq.com
/// 2. Đăng ký/Đăng nhập (miễn phí)
/// 3. Vào "API Keys" → "Create API Key"
/// 4. Sao chép API key và dán vào đây
/// 
/// Ưu điểm Groq:
/// - MIỄN PHÍ với quota cao (30 requests/phút, 14400/ngày)
/// - Cực kỳ NHANH (nhanh hơn Gemini 5-10 lần)
/// - Hỗ trợ nhiều model mạnh: Llama, Mixtral, Gemma
/// - Không cần thẻ tín dụng
/// 
/// Lưu ý:
/// - KHÔNG chia sẻ API key với người khác
/// - KHÔNG commit file này lên Git nếu có API key thật
/// - Kiểm tra quota tại: https://console.groq.com/settings/limits

class GroqConfig {
  /// API key Groq - Thay thế bằng API key thực của bạn
  /// 
  /// Ví dụ: 'gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
  static const String apiKey = ''; // ⬅️ THAY ĐỔI API KEY TẠI ĐÂY
  
  /// Model Groq sử dụng
  /// 
  /// Models khuyến nghị (miễn phí, nhanh): 
  /// - 'llama-3.3-70b-versatile' (mạnh nhất, khuyến nghị) ⬅️ ĐANG DÙNG
  /// - 'llama-3.1-70b-versatile' (cân bằng tốt)
  /// - 'mixtral-8x7b-32768' (context dài)
  /// - 'gemma2-9b-it' (nhẹ, nhanh)
  /// - 'llama-3.1-8b-instant' (cực nhanh)
  static const String model = 'llama-3.3-70b-versatile';
  
  /// API endpoint
  static const String apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  /// Kiểm tra xem API key đã được cấu hình chưa
  static bool get isConfigured {
    return apiKey.isNotEmpty && 
           !apiKey.contains('xxxxxxxx') &&
           apiKey.startsWith('gsk_');
  }
  
  /// Thông báo lỗi khi chưa cấu hình API key
  static const String configErrorMessage = 
      'Vui lòng cấu hình API key Groq trong file:\n'
      'lib/config/groq_config.dart\n\n'
      'Lấy API key MIỄN PHÍ tại:\n'
      'https://console.groq.com/keys\n\n'
      'Groq nhanh hơn và quota cao hơn Gemini!';
}
