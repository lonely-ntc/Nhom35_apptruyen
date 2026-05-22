import 'package:flutter/material.dart';
import '../../services/keyword_service.dart';
import '../../services/database_service.dart';
import '../../models/story_model.dart';
import '../../utils/app_colors.dart';

/// 🔥 Admin Keyword Sync Screen
/// 
/// Màn hình sync và xem keywords được tạo bởi Groq AI

class AdminKeywordSyncScreen extends StatefulWidget {
  const AdminKeywordSyncScreen({super.key});

  @override
  State<AdminKeywordSyncScreen> createState() => _AdminKeywordSyncScreenState();
}

class _AdminKeywordSyncScreenState extends State<AdminKeywordSyncScreen> {
  final KeywordService _keywordService = KeywordService();
  final DatabaseService _dbService = DatabaseService.instance;

  List<Story> _stories = [];
  final Map<String, List<String>> _storyKeywords = {}; // storyId -> keywords
  bool _isLoading = false;
  bool _isSyncing = false;
  int _syncProgress = 0;
  int _syncTotal = 0;
  String _syncStatus = '';

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);

    try {
      final stories = await _dbService.getStories();
      setState(() {
        _stories = stories;
        _isLoading = false;
      });

      // Load keywords cho mỗi truyện
      _loadAllKeywords();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi tải truyện: $e');
    }
  }

  Future<void> _loadAllKeywords() async {
    for (var story in _stories) {
      final storyId = _normalizeId(story.title);
      final keywords = await _keywordService.getKeywords(storyId);
      if (mounted) {
        setState(() {
          _storyKeywords[storyId] = keywords;
        });
      }
    }
  }

  Future<void> _syncAllKeywords() async {
    final confirm = await _showConfirmDialog(
      'Sync Tất Cả Keywords',
      'Bạn có chắc muốn sync keywords cho tất cả ${_stories.length} truyện?\n\n'
          'Groq AI sẽ phân tích và tạo keywords tự động.\n'
          'Quá trình này có thể mất vài phút.',
    );

    if (confirm != true) return;

    setState(() {
      _isSyncing = true;
      _syncProgress = 0;
      _syncTotal = _stories.length;
      _syncStatus = 'Đang bắt đầu...';
    });

    try {
      await _keywordService.syncAllStories(
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _syncProgress = current;
              _syncTotal = total;
              _syncStatus = 'Đang xử lý: $current/$total';
            });
          }
        },
      );

      setState(() {
        _isSyncing = false;
        _syncStatus = 'Hoàn thành!';
      });

      _showSuccess('✅ Sync keywords thành công cho ${_stories.length} truyện!');
      
      // Reload keywords
      _loadAllKeywords();
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _syncStatus = 'Lỗi!';
      });
      _showError('Lỗi sync keywords: $e');
    }
  }

  Future<void> _syncStoryKeywords(Story story) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tạo keywords...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await _keywordService.syncStory(story.title);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        _showSuccess('✅ Sync keywords thành công!');
        
        // Reload keywords cho truyện này
        final storyId = _normalizeId(story.title);
        final keywords = await _keywordService.getKeywords(storyId);
        setState(() {
          _storyKeywords[storyId] = keywords;
        });
        
        // Show keywords
        _viewKeywords(story);
      } else {
        _showError('❌ Không thể sync keywords');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      _showError('Lỗi: $e');
    }
  }

  void _viewKeywords(Story story) {
    final storyId = _normalizeId(story.title);
    final keywords = _storyKeywords[storyId] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.label, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Keywords từ Groq AI',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Story info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            story.author,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.category, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          story.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Keywords count
              Row(
                children: [
                  const Icon(Icons.tag, size: 18, color: AppColors.primaryPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng số: ${keywords.length} keywords',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Keywords
              if (keywords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Chưa có keywords',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nhấn "Sync" để Groq AI tạo keywords tự động',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: keywords.map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryPurple.withOpacity(0.1),
                            AppColors.primaryPurple.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryPurple.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        keyword,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (keywords.isEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _syncStoryKeywords(story);
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Tạo với Groq AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
              ),
            ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
            ),
            child: const Text('Xác Nhận'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _normalizeId(String text) {
    const vietnameseMap = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
    };

    String normalized = text.trim().toLowerCase();
    vietnameseMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
    normalized = normalized
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Keywords với Groq AI'),
        backgroundColor: AppColors.primaryPurple,
      ),
      body: Column(
        children: [
          // Header với Sync Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple.withOpacity(0.1),
                  AppColors.primaryPurple.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Groq AI sẽ phân tích truyện và tạo keywords tự động',
                          style: TextStyle(fontSize: 13, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Sync All button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _syncAllKeywords,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      _isSyncing
                          ? 'Đang Sync... ($_syncProgress/$_syncTotal)'
                          : 'Sync Tất Cả Keywords',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                // Progress bar
                if (_isSyncing) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _syncTotal > 0 ? _syncProgress / _syncTotal : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _syncStatus,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),

          // Story List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _stories.isEmpty
                    ? const Center(child: Text('Không có truyện nào'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stories.length,
                        itemBuilder: (context, index) {
                          final story = _stories[index];
                          final storyId = _normalizeId(story.title);
                          final keywords = _storyKeywords[storyId] ?? [];
                          final hasKeywords = keywords.isNotEmpty;

                          return _buildStoryCard(story, keywords, hasKeywords);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Story story, List<String> keywords, bool hasKeywords) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewKeywords(story),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: story.image.isNotEmpty
                    ? Image.network(
                        story.image,
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 70,
                          color: Colors.grey[300],
                          child: const Icon(Icons.book),
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 70,
                        color: Colors.grey[300],
                        child: const Icon(Icons.book),
                      ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${story.author} • ${story.category}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          hasKeywords ? Icons.check_circle : Icons.warning_amber,
                          size: 16,
                          color: hasKeywords ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasKeywords
                              ? '${keywords.length} keywords'
                              : 'Chưa có keywords',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasKeywords ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    _viewKeywords(story);
                  } else if (value == 'sync') {
                    _syncStoryKeywords(story);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18),
                        SizedBox(width: 8),
                        Text('Xem Keywords'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'sync',
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 18),
                        SizedBox(width: 8),
                        Text('Tạo Keywords'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
