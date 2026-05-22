import 'dart:async';
import 'package:flutter/foundation.dart';
import 'tts_service.dart';

/// Service để đọc văn bản dài bằng cách chia nhỏ thành các đoạn
/// 
/// Giải quyết vấn đề:
/// - TTS Error -8 (ERROR_SYNTHESIS) khi văn bản quá dài
/// - Android TTS engine có giới hạn độ dài văn bản
/// 
/// Cách hoạt động:
/// 1. Chia văn bản thành các đoạn nhỏ (theo câu hoặc đoạn văn)
/// 2. Đọc tuần tự từng đoạn
/// 3. Tự động chuyển sang đoạn tiếp theo khi hoàn thành
class ChunkedTtsService {
  static final ChunkedTtsService _instance = ChunkedTtsService._internal();
  factory ChunkedTtsService() => _instance;
  ChunkedTtsService._internal();

  final TtsService _ttsService = TtsService();
  
  // Chunk management
  List<String> _chunks = [];
  int _currentChunkIndex = 0;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isStopped = false;

  // Callbacks
  Function()? onComplete;
  Function()? onStart;
  Function()? onPause;
  Function()? onContinue;
  Function(String)? onError;
  Function(int current, int total)? onChunkProgress;

  // Configuration
  static const int maxChunkLength = 1000; // Độ dài tối đa mỗi chunk (ký tự)
  static const int minChunkLength = 100; // Độ dài tối thiểu mỗi chunk

  /// Khởi tạo service
  Future<void> initialize() async {
    await _ttsService.initialize();
    
    // Setup TTS callbacks
    _ttsService.onComplete = _onChunkComplete;
    _ttsService.onError = (error) {
      debugPrint('❌ Chunk TTS error: $error');
      onError?.call(error);
    };
  }

  /// Chia văn bản thành các đoạn nhỏ
  /// 
  /// Ưu tiên chia theo:
  /// 1. Dấu chấm câu kết thúc (. ! ?)
  /// 2. Dấu phẩy, chấm phẩy
  /// 3. Khoảng trắng
  List<String> _splitIntoChunks(String text) {
    if (text.length <= maxChunkLength) {
      return [text];
    }

    final chunks = <String>[];
    String remaining = text.trim();

    while (remaining.isNotEmpty) {
      if (remaining.length <= maxChunkLength) {
        chunks.add(remaining);
        break;
      }

      // Tìm điểm cắt tốt nhất trong khoảng maxChunkLength
      int cutPoint = maxChunkLength;
      
      // 1. Ưu tiên cắt ở dấu chấm câu kết thúc
      final endPunctuationPattern = RegExp(r'[.!?]\s+');
      final endMatches = endPunctuationPattern.allMatches(
        remaining.substring(0, maxChunkLength)
      );
      
      if (endMatches.isNotEmpty) {
        cutPoint = endMatches.last.end;
      } else {
        // 2. Cắt ở dấu phẩy, chấm phẩy
        final midPunctuationPattern = RegExp(r'[,;]\s+');
        final midMatches = midPunctuationPattern.allMatches(
          remaining.substring(0, maxChunkLength)
        );
        
        if (midMatches.isNotEmpty) {
          cutPoint = midMatches.last.end;
        } else {
          // 3. Cắt ở khoảng trắng
          final lastSpace = remaining.substring(0, maxChunkLength).lastIndexOf(' ');
          if (lastSpace > minChunkLength) {
            cutPoint = lastSpace + 1;
          }
        }
      }

      // Thêm chunk và cập nhật remaining
      final chunk = remaining.substring(0, cutPoint).trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }
      remaining = remaining.substring(cutPoint).trim();
    }

    return chunks;
  }

  /// Đọc văn bản (tự động chia nhỏ)
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('Văn bản trống, không thể chuyển đổi');
    }

    // Reset state
    _isStopped = false;
    _isPaused = false;

    // Chia văn bản thành chunks
    _chunks = _splitIntoChunks(text);
    _currentChunkIndex = 0;

    debugPrint('📚 Split text into ${_chunks.length} chunks');
    debugPrint('📝 Total length: ${text.length} characters');
    
    // Bắt đầu đọc chunk đầu tiên
    await _speakCurrentChunk();
  }

  /// Đọc chunk hiện tại
  Future<void> _speakCurrentChunk() async {
    if (_currentChunkIndex >= _chunks.length || _isStopped) {
      return;
    }

    final chunk = _chunks[_currentChunkIndex];
    debugPrint('🎤 Speaking chunk ${_currentChunkIndex + 1}/${_chunks.length} (${chunk.length} chars)');

    try {
      // Notify progress
      onChunkProgress?.call(_currentChunkIndex + 1, _chunks.length);

      // Notify start (chỉ lần đầu)
      if (_currentChunkIndex == 0 && !_isPlaying) {
        _isPlaying = true;
        onStart?.call();
      }

      // Đọc chunk
      await _ttsService.speak(chunk);
    } catch (e) {
      debugPrint('❌ Error speaking chunk: $e');
      onError?.call(e.toString());
      _isPlaying = false;
    }
  }

  /// Callback khi hoàn thành một chunk
  void _onChunkComplete() {
    if (_isStopped) {
      return;
    }

    debugPrint('✅ Chunk ${_currentChunkIndex + 1}/${_chunks.length} completed');

    // Chuyển sang chunk tiếp theo
    _currentChunkIndex++;

    if (_currentChunkIndex < _chunks.length) {
      // Còn chunk, tiếp tục đọc
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isStopped && !_isPaused) {
          _speakCurrentChunk();
        }
      });
    } else {
      // Hết chunk, hoàn thành
      debugPrint('✅ All chunks completed');
      _isPlaying = false;
      _isPaused = false;
      onComplete?.call();
    }
  }

  /// Tạm dừng
  Future<void> pause() async {
    if (_isPlaying && !_isPaused) {
      await _ttsService.pause();
      _isPaused = true;
      _isPlaying = false;
      onPause?.call();
      debugPrint('⏸️ Paused at chunk ${_currentChunkIndex + 1}/${_chunks.length}');
    }
  }

  /// Tiếp tục
  Future<void> resume() async {
    if (_isPaused) {
      _isPaused = false;
      _isPlaying = true;
      onContinue?.call();
      
      // Đọc lại chunk hiện tại (vì TTS không hỗ trợ resume)
      await _speakCurrentChunk();
      debugPrint('▶️ Resumed at chunk ${_currentChunkIndex + 1}/${_chunks.length}');
    }
  }

  /// Dừng
  Future<void> stop() async {
    _isStopped = true;
    _isPlaying = false;
    _isPaused = false;
    await _ttsService.stop();
    _chunks.clear();
    _currentChunkIndex = 0;
    debugPrint('⏹️ Stopped');
  }

  /// Chuyển sang chunk tiếp theo
  Future<void> skipToNextChunk() async {
    if (_currentChunkIndex < _chunks.length - 1) {
      await _ttsService.stop();
      _currentChunkIndex++;
      await _speakCurrentChunk();
      debugPrint('⏭️ Skipped to chunk ${_currentChunkIndex + 1}/${_chunks.length}');
    }
  }

  /// Quay lại chunk trước
  Future<void> skipToPreviousChunk() async {
    if (_currentChunkIndex > 0) {
      await _ttsService.stop();
      _currentChunkIndex--;
      await _speakCurrentChunk();
      debugPrint('⏮️ Skipped to chunk ${_currentChunkIndex + 1}/${_chunks.length}');
    }
  }

  /// Đặt ngôn ngữ
  Future<void> setLanguage(String language) async {
    await _ttsService.setLanguage(language);
  }

  /// Đặt tốc độ đọc
  Future<void> setSpeechRate(double rate) async {
    await _ttsService.setSpeechRate(rate);
  }

  /// Đặt âm lượng
  Future<void> setVolume(double volume) async {
    await _ttsService.setVolume(volume);
  }

  /// Đặt cao độ giọng
  Future<void> setPitch(double pitch) async {
    await _ttsService.setPitch(pitch);
  }

  /// Getters
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isInitialized => _ttsService.isInitialized;
  int get currentChunkIndex => _currentChunkIndex;
  int get totalChunks => _chunks.length;
  double get progress => _chunks.isEmpty ? 0.0 : (_currentChunkIndex + 1) / _chunks.length;

  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    await stop();
    await _ttsService.dispose();
  }
}
