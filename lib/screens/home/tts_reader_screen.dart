import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/chunked_tts_service.dart';
import '../../services/database_service.dart';
import '../../services/tts_settings_service.dart';
import '../../utils/app_colors.dart';

class TtsReaderScreen extends StatefulWidget {
  final String title;
  final String chapterTitle;
  final String link;
  final int currentChapterIndex;

  const TtsReaderScreen({
    super.key,
    required this.title,
    required this.chapterTitle,
    required this.link,
    this.currentChapterIndex = 0,
  });

  @override
  State<TtsReaderScreen> createState() => _TtsReaderScreenState();
}

class _TtsReaderScreenState extends State<TtsReaderScreen>
    with TickerProviderStateMixin {
  final ChunkedTtsService _ttsService = ChunkedTtsService();
  final DatabaseService _db = DatabaseService.instance;

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isLoading = false;
  String _errorMessage = '';

  double _selectedRate = 0.5; // Tốc độ đọc (0.0 - 1.0)
  double _selectedPitch = 1.0; // Cao độ giọng (0.5 - 2.0)
  double _volume = 1.0;

  late AnimationController _rotateController;

  // Chapter management
  List<Map<String, dynamic>> _allChapters = [];
  int _currentChapterIndex = 0;
  String _currentChapterTitle = '';
  String _currentContent = '';
  bool _autoPlayNext = true;

  // Chunk progress
  int _currentChunk = 0;
  int _totalChunks = 0;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.currentChapterIndex;
    _currentChapterTitle = widget.chapterTitle;

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _loadChapters();
    _loadSavedSettings(); // Load saved settings first
    _initializeTts();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await _db.getChapters(widget.title);
      if (mounted) {
        setState(() {
          _allChapters = chapters;
          final index = chapters.indexWhere((ch) => ch['link'] == widget.link);
          if (index != -1) {
            _currentChapterIndex = index;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ _loadChapters error: $e');
    }
  }

  /// Load saved TTS settings from SharedPreferences
  Future<void> _loadSavedSettings() async {
    try {
      final settings = await TtsSettingsService.loadAllSettings();
      if (mounted) {
        setState(() {
          _selectedRate = settings['rate']!;
          _selectedPitch = settings['pitch']!;
          _volume = settings['volume']!;
        });
        debugPrint('✅ Loaded TTS settings: rate=$_selectedRate, pitch=$_selectedPitch, volume=$_volume');
      }
    } catch (e) {
      debugPrint('❌ _loadSavedSettings error: $e');
    }
  }

  /// Phát đoạn mẫu để test settings
  Future<void> _playTestSample(String text) async {
    try {
      // Dừng TTS hiện tại nếu có
      await _ttsService.stop();
      
      // Đợi một chút để đảm bảo TTS đã dừng
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Phát đoạn mẫu với settings mới
      await _ttsService.speak(text);
      
      debugPrint('🎤 Playing test sample: $text');
    } catch (e) {
      debugPrint('❌ _playTestSample error: $e');
    }
  }

  Future<void> _loadChapterContent() async {
    if (_currentChapterIndex < 0 || _currentChapterIndex >= _allChapters.length) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chapter = _allChapters[_currentChapterIndex];
      final content = await _db.getChapterContent(
        chapter['link'],
        storyTitle: widget.title,
      );

      if (mounted) {
        setState(() {
          _currentContent = content;
          _currentChapterTitle = chapter['ten_chuong'];
          _isLoading = false;
        });
        
        // Log để debug
        debugPrint('✅ Loaded chapter: $_currentChapterTitle');
        debugPrint('📝 Content length: ${content.length} characters');
        
        if (content.isEmpty) {
          setState(() {
            _errorMessage = 'Nội dung chương trống';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nội dung chương trống'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ _loadChapterContent error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tải nội dung: $e';
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải nội dung: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _initializeTts() async {
    setState(() => _isLoading = true);

    try {
      await _ttsService.initialize();

      _ttsService.onComplete = () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isPaused = false;
          });
          _rotateController.stop();

          if (_autoPlayNext && _currentChapterIndex < _allChapters.length - 1) {
            _playNextChapter();
          }
        }
      };

      _ttsService.onStart = () {
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _isPaused = false;
          });
        }
      };

      _ttsService.onPause = () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isPaused = true;
          });
        }
      };

      _ttsService.onContinue = () {
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _isPaused = false;
          });
        }
      };

      _ttsService.onError = (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
            _isPlaying = false;
            _isLoading = false;
          });
          _rotateController.stop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi TTS: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      };

      // 🔥 Callback theo dõi tiến trình chunk
      _ttsService.onChunkProgress = (current, total) {
        if (mounted) {
          setState(() {
            _currentChunk = current;
            _totalChunks = total;
          });
          debugPrint('📊 Progress: $current/$total chunks');
        }
      };

      // Load nội dung chương đầu tiên
      await _loadChapterContent();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        
        // Tự động phát sau khi load xong
        if (_currentContent.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 500));
          await _playPause();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi tạo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _playPause() async {
    if (_currentContent.isEmpty) {
      await _loadChapterContent();
      if (_currentContent.isEmpty) {
        setState(() => _errorMessage = 'Không có nội dung để đọc');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có nội dung để đọc'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_isPlaying) {
      await _ttsService.pause();
      _rotateController.stop();
      setState(() {
        _isPlaying = false;
        _isPaused = true;
      });
    } else if (_isPaused) {
      // Resume
      await _ttsService.resume();
      _rotateController.repeat();
      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
    } else {
      // Start new
      setState(() => _isLoading = true);
      try {
        debugPrint('🎤 Starting chunked TTS with ${_currentContent.length} characters');
        await _ttsService.speak(_currentContent);
        _rotateController.repeat();
        setState(() {
          _isPlaying = true;
          _isPaused = false;
          _isLoading = false;
          _errorMessage = '';
        });
        debugPrint('✅ Chunked TTS started successfully');
      } catch (e) {
        debugPrint('❌ TTS error: $e');
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi phát âm thanh: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _playPause(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _stop() async {
    await _ttsService.stop();
    _rotateController.stop();
    _rotateController.reset();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });
  }

  Future<void> _playNextChapter() async {
    if (_currentChapterIndex >= _allChapters.length - 1) return;

    await _stop();
    setState(() {
      _currentChapterIndex++;
      _currentContent = '';
    });
    await _loadChapterContent();
    
    if (_autoPlayNext) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _playPause();
    }
  }

  Future<void> _playPreviousChapter() async {
    if (_currentChapterIndex <= 0) return;

    await _stop();
    setState(() {
      _currentChapterIndex--;
      _currentContent = '';
    });
    await _loadChapterContent();
  }

  void _showChapterList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildChapterList(),
    );
  }

  void _showVoiceSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: _buildVoiceSettings(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
              const Color(0xFF1a1a2e),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar with glassmorphism
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đang phát',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.playlist_play_rounded,
                          color: Colors.white, size: 26),
                      onPressed: _showChapterList,
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded,
                          color: Colors.white, size: 24),
                      onPressed: _showVoiceSettings,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading && _currentContent.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryPurple,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Đang tải nội dung...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage.isNotEmpty && _currentContent.isEmpty
                        ? _buildErrorState()
                        : _buildMusicPlayer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Lỗi khởi tạo TTS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _errorMessage = '');
                _initializeTts();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicPlayer() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Animated vinyl disc with sound waves - IMPROVED VERSION
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow rings (animated) - More rings for better effect
            ...List.generate(5, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 1500 + (index * 300)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return AnimatedOpacity(
                    opacity: _isPlaying ? (1.0 - value) * 0.4 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 240 + (index * 25.0 * value),
                      height: 240 + (index * 25.0 * value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryPurple.withValues(
                              alpha: (1.0 - value) * 0.3,
                            ),
                            AppColors.primaryPurple.withValues(
                              alpha: (1.0 - value) * 0.1,
                            ),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  );
                },
                onEnd: () {
                  if (_isPlaying && mounted) {
                    setState(() {}); // Trigger rebuild to restart animation
                  }
                },
              );
            }),

            // Main glow effect - Enhanced
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(
                      alpha: _isPlaying ? 0.5 : 0.2,
                    ),
                    blurRadius: _isPlaying ? 80 : 40,
                    spreadRadius: _isPlaying ? 15 : 5,
                  ),
                  BoxShadow(
                    color: const Color(0xFF8F7BFF).withValues(
                      alpha: _isPlaying ? 0.3 : 0.1,
                    ),
                    blurRadius: _isPlaying ? 50 : 25,
                    spreadRadius: _isPlaying ? 8 : 0,
                  ),
                ],
              ),
            ),

            // Rotating vinyl disc - Enhanced gradient
            RotationTransition(
              turns: _rotateController,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF9D8CFF),
                      const Color(0xFF8F7BFF),
                      const Color(0xFF7B68EE),
                      const Color(0xFF6B5FCD),
                      const Color(0xFF4B4B6B),
                      const Color(0xFF2a2a3e),
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vinyl grooves with better spacing
                    ...List.generate(11, (index) {
                      final size = 230.0 - (index * 18.0);
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.03 + (index * 0.008),
                            ),
                            width: 1.2,
                          ),
                        ),
                      );
                    }),

                    // Center label with better glassmorphism
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF3a3a4e),
                            const Color(0xFF2a2a3e),
                            const Color(0xFF1a1a2e),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.graphic_eq_rounded
                            : Icons.headphones_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Play status badge - Improved design
            if (_isPlaying)
              Positioned(
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryPurple,
                        const Color(0xFF8F7BFF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.6),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'Đang phát',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 30),

        // Chapter info with enhanced glassmorphism
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Chapter title
              Text(
                _currentChapterTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Story title & chapter number
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_rounded,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Chapter progress with better styling
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.3),
                      AppColors.primaryPurple.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Chương ${_currentChapterIndex + 1}/${_allChapters.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Chunk progress indicator
              if (_totalChunks > 1 && _isPlaying) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.waves_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Đoạn $_currentChunk/$_totalChunks',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Progress bar with enhanced styling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              // Progress indicator with gradient
              Container(
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // Background
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Progress with gradient
                      FractionallySizedBox(
                        widthFactor: _totalChunks > 0 ? _currentChunk / _totalChunks : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple,
                                const Color(0xFF8F7BFF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple.withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Main play/pause button with enhanced design
        Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPurple,
                const Color(0xFF8F7BFF),
                const Color(0xFF7B68EE),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: const Color(0xFF8F7BFF).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isInitialized ? _playPause : null,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(
                  _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Secondary controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous chapter
              _buildControlButton(
                icon: Icons.skip_previous_rounded,
                onPressed: _currentChapterIndex > 0
                    ? _playPreviousChapter
                    : null,
                size: 32,
              ),

              // Auto play toggle
              _buildControlButton(
                icon: _autoPlayNext
                    ? Icons.repeat_on_rounded
                    : Icons.repeat_rounded,
                onPressed: () {
                  setState(() => _autoPlayNext = !_autoPlayNext);
                },
                isActive: _autoPlayNext,
                size: 28,
              ),

              // Volume control
              _buildVolumeControl(),

              // Next chapter
              _buildControlButton(
                icon: Icons.skip_next_rounded,
                onPressed: _currentChapterIndex < _allChapters.length - 1
                    ? _playNextChapter
                    : null,
                size: 32,
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isActive = false,
    double size = 28,
  }) {
    final isEnabled = onPressed != null;
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? LinearGradient(
                colors: [
                  AppColors.primaryPurple.withValues(alpha: 0.3),
                  AppColors.primaryPurple.withValues(alpha: 0.2),
                ],
              )
            : null,
        color: isActive
            ? null
            : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: isActive
              ? AppColors.primaryPurple.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              size: size,
              color: isActive
                  ? AppColors.primaryPurple
                  : isEnabled
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: PopupMenuButton<double>(
        icon: Icon(
          _volume > 0.5
              ? Icons.volume_up_rounded
              : _volume > 0
                  ? Icons.volume_down_rounded
                  : Icons.volume_off_rounded,
          color: Colors.white.withValues(alpha: 0.8),
          size: 24,
        ),
        color: const Color(0xFF2a2a3e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem<double>(
            enabled: false,
            child: Column(
              children: [
                const Text(
                  'Âm lượng',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: AppColors.primaryPurple,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: AppColors.primaryPurple,
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: (value) {
                      setState(() => _volume = value);
                      _ttsService.setVolume(value);
                    },
                  ),
                ),
                Text(
                  '${(_volume * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2a2a3e),
            const Color(0xFF1a1a2e),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.list_rounded,
                    color: AppColors.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Danh sách chương",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_allChapters.length} chương",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),

          // Chapter list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _allChapters.length,
              itemBuilder: (context, index) {
                final chapter = _allChapters[index];
                final isCurrent = index == _currentChapterIndex;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primaryPurple.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primaryPurple.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isCurrent
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryPurple,
                                  AppColors.primaryPurple.withValues(alpha: 0.8),
                                ],
                              )
                            : null,
                        color: isCurrent
                            ? null
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isCurrent
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      chapter['ten_chuong'],
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    trailing: isCurrent
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_circle_filled,
                              color: AppColors.primaryPurple,
                              size: 20,
                            ),
                          )
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      if (!isCurrent) {
                        await _stop();
                        setState(() {
                          _currentChapterIndex = index;
                          _currentContent = '';
                        });
                        await _loadChapterContent();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSettings() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        // 🔥 SỬ DỤNG LOCAL VARIABLES để slider có thể di chuyển mượt mà
        // Khởi tạo từ parent state
        double localRate = _selectedRate;
        double localPitch = _selectedPitch;
        double localVolume = _volume;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2a2a3e),
                const Color(0xFF1a1a2e),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 25,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header with better design
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryPurple.withValues(alpha: 0.3),
                              AppColors.primaryPurple.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryPurple.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.primaryPurple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Cài đặt giọng đọc',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Speech Rate (Tốc độ đọc)
                  _buildSettingSection(
                    icon: Icons.speed_rounded,
                    title: 'Tốc độ đọc',
                    value: localRate,
                    displayValue: localRate == 0.0
                        ? 'Rất chậm'
                        : localRate < 0.3
                            ? 'Chậm'
                            : localRate < 0.7
                                ? 'Bình thường'
                                : 'Nhanh',
                    onChanged: (value) {
                      // Cập nhật local variable để slider di chuyển mượt
                      setModalState(() {
                        localRate = value;
                      });
                      
                      // Cập nhật parent state
                      setState(() {
                        _selectedRate = value;
                      });
                      
                      // ✅ ÁP DỤNG NGAY LẬP TỨC (không await để không block UI)
                      _ttsService.setSpeechRate(value);
                    },
                    onChangeEnd: (value) async {
                      // Lưu settings khi thả tay
                      await TtsSettingsService.saveSpeechRate(value);
                      
                      // Phát mẫu nếu không đang phát
                      if (!_isPlaying && mounted) {
                        _playTestSample('Tốc độ đọc đã được thay đổi');
                      }
                    },
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                  ),

                  const SizedBox(height: 14),

                  // Pitch (Cao độ giọng)
                  _buildSettingSection(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Cao độ giọng',
                    value: localPitch,
                    displayValue: localPitch < 0.8
                        ? 'Trầm'
                        : localPitch < 1.2
                            ? 'Bình thường'
                            : 'Cao',
                    onChanged: (value) {
                      // Cập nhật local variable để slider di chuyển mượt
                      setModalState(() {
                        localPitch = value;
                      });
                      
                      // Cập nhật parent state
                      setState(() {
                        _selectedPitch = value;
                      });
                      
                      // ✅ ÁP DỤNG NGAY LẬP TỨC (không await để không block UI)
                      _ttsService.setPitch(value);
                    },
                    onChangeEnd: (value) async {
                      // Lưu settings khi thả tay
                      await TtsSettingsService.savePitch(value);
                      
                      // Phát mẫu nếu không đang phát
                      if (!_isPlaying && mounted) {
                        _playTestSample('Cao độ giọng đã được thay đổi');
                      }
                    },
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                  ),

                  const SizedBox(height: 14),

                  // Volume (Âm lượng)
                  _buildSettingSection(
                    icon: Icons.volume_up_rounded,
                    title: 'Âm lượng',
                    value: localVolume,
                    displayValue: '${(localVolume * 100).toInt()}%',
                    onChanged: (value) {
                      // Cập nhật local variable để slider di chuyển mượt
                      setModalState(() {
                        localVolume = value;
                      });
                      
                      // Cập nhật parent state
                      setState(() {
                        _volume = value;
                      });
                      
                      // ✅ ÁP DỤNG NGAY LẬP TỨC (không await để không block UI)
                      _ttsService.setVolume(value);
                    },
                    onChangeEnd: (value) async {
                      // Lưu settings khi thả tay
                      await TtsSettingsService.saveVolume(value);
                      
                      // Phát mẫu nếu không đang phát
                      if (!_isPlaying && mounted) {
                        _playTestSample('Âm lượng đã được thay đổi');
                      }
                    },
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingSection({
    required IconData icon,
    required String title,
    required double value,
    required String displayValue,
    required ValueChanged<double> onChanged,
    required ValueChanged<double>? onChangeEnd,
    required double min,
    required double max,
    required int divisions,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.3),
                      AppColors.primaryPurple.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.3),
                      AppColors.primaryPurple.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  displayValue,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primaryPurple,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
                elevation: 2,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 16,
              ),
              activeTrackColor: AppColors.primaryPurple,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: Colors.white,
              overlayColor: AppColors.primaryPurple.withValues(alpha: 0.3),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}
