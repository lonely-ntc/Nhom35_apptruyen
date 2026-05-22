import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// Service để chuyển văn bản thành giọng nói sử dụng Flutter TTS (Native)
/// 
/// Ưu điểm:
/// - Không cần API key
/// - Hoạt động offline
/// - Miễn phí hoàn toàn
/// - Hỗ trợ nhiều ngôn ngữ
/// - Ổn định hơn
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;

  // Cấu hình mặc định
  String _currentLanguage = 'vi-VN'; // Tiếng Việt
  double _currentRate = 0.5; // Tốc độ đọc (0.0 - 1.0)
  double _currentVolume = 1.0; // Âm lượng (0.0 - 1.0)
  double _currentPitch = 1.0; // Cao độ giọng (0.5 - 2.0)

  // Callbacks
  Function()? onComplete;
  Function()? onStart;
  Function()? onPause;
  Function()? onContinue;
  Function(String)? onError;

  /// Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Cấu hình TTS với error handling
      try {
        await _flutterTts.setLanguage(_currentLanguage);
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ Warning: Could not set language: $e');
      }
      
      await _flutterTts.setSpeechRate(_currentRate);
      await _flutterTts.setVolume(_currentVolume);
      await _flutterTts.setPitch(_currentPitch);

      // iOS specific - wrap in try-catch vì Android không hỗ trợ
      try {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ iOS audio settings not available (Android device): $e');
      }

      // Setup handlers
      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        onStart?.call();
        // ignore: avoid_print
        print('🎤 TTS started');
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        onComplete?.call();
        // ignore: avoid_print
        print('✅ TTS completed');
      });

      _flutterTts.setPauseHandler(() {
        _isPlaying = false;
        onPause?.call();
        // ignore: avoid_print
        print('⏸️ TTS paused');
      });

      _flutterTts.setContinueHandler(() {
        _isPlaying = true;
        onContinue?.call();
        // ignore: avoid_print
        print('▶️ TTS continued');
      });

      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        
        // Xử lý lỗi -8 (ERROR_SYNTHESIS) trên Android
        if (msg.contains('-8') || msg.contains('ERROR_SYNTHESIS')) {
          // ignore: avoid_print
          print('⚠️ TTS synthesis error (common on Android), retrying...');
          // Không gọi onError để tránh hiển thị lỗi cho user
          return;
        }
        
        onError?.call(msg);
        // ignore: avoid_print
        print('❌ TTS error: $msg');
      });

      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
        // ignore: avoid_print
        print('⏹️ TTS cancelled');
      });

      _isInitialized = true;
      // ignore: avoid_print
      print('✅ TtsService initialized successfully');
    } catch (e) {
      // ignore: avoid_print
      print('❌ TtsService initialization error: $e');
      rethrow;
    }
  }

  /// Chuyển văn bản thành giọng nói và phát
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Kiểm tra text
      if (text.trim().isEmpty) {
        throw Exception('Văn bản trống, không thể chuyển đổi');
      }

      // ignore: avoid_print
      print('🎤 Starting TTS for ${text.length} characters');

      // Dừng audio hiện tại nếu đang phát
      if (_isPlaying) {
        await stop();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Phát văn bản với retry mechanism cho lỗi -8
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          final result = await _flutterTts.speak(text);
          
          if (result == 1) {
            _isPlaying = true;
            // ignore: avoid_print
            print('✅ TTS started successfully');
            return;
          } else if (result == 0) {
            // Result 0 có thể là đang khởi tạo, retry
            retryCount++;
            if (retryCount < maxRetries) {
              // ignore: avoid_print
              print('⚠️ TTS not ready (attempt $retryCount/$maxRetries), retrying...');
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
              continue;
            }
          }
          
          throw Exception('Failed to start TTS (result: $result)');
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow;
          }
          // ignore: avoid_print
          print('⚠️ TTS error (attempt $retryCount/$maxRetries): $e');
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ TtsService speak error: $e');
      _isPlaying = false;
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Tạm dừng
  Future<void> pause() async {
    if (_isPlaying) {
      await _flutterTts.pause();
    }
  }

  /// Dừng
  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
  }

  /// Đặt ngôn ngữ
  /// 
  /// Các ngôn ngữ phổ biến:
  /// - 'vi-VN': Tiếng Việt
  /// - 'en-US': English (US)
  /// - 'en-GB': English (UK)
  /// - 'zh-CN': Chinese
  /// - 'ja-JP': Japanese
  /// - 'ko-KR': Korean
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await _flutterTts.setLanguage(language);
  }

  /// Đặt tốc độ đọc (0.0 - 1.0)
  /// 
  /// - 0.0: Rất chậm
  /// - 0.5: Bình thường (mặc định)
  /// - 1.0: Rất nhanh
  Future<void> setSpeechRate(double rate) async {
    _currentRate = rate.clamp(0.0, 1.0);
    await _flutterTts.setSpeechRate(_currentRate);
  }

  /// Đặt âm lượng (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _currentVolume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_currentVolume);
  }

  /// Đặt cao độ giọng (0.5 - 2.0)
  /// 
  /// - 0.5: Giọng trầm
  /// - 1.0: Bình thường (mặc định)
  /// - 2.0: Giọng cao
  Future<void> setPitch(double pitch) async {
    _currentPitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_currentPitch);
  }

  /// Lấy danh sách ngôn ngữ có sẵn
  Future<List<dynamic>> getLanguages() async {
    return await _flutterTts.getLanguages;
  }

  /// Lấy danh sách giọng đọc có sẵn
  Future<List<dynamic>> getVoices() async {
    return await _flutterTts.getVoices;
  }

  /// Kiểm tra ngôn ngữ có được hỗ trợ không
  Future<bool> isLanguageAvailable(String language) async {
    final result = await _flutterTts.isLanguageAvailable(language);
    return result == 1;
  }

  /// Lấy trạng thái
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  String get currentLanguage => _currentLanguage;
  double get currentRate => _currentRate;
  double get currentVolume => _currentVolume;
  double get currentPitch => _currentPitch;

  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    await _flutterTts.stop();
    _isInitialized = false;
  }
}
