import 'package:flutter/material.dart';
import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../services/story_management_service.dart';
import '../../services/story_refresh_service.dart';
import '../../utils/image_helper.dart';
import 'admin_edit_story_screen.dart';
import 'admin_chapter_management_screen.dart';

class AdminStoryDetailScreen extends StatefulWidget {
  final Story story;

  const AdminStoryDetailScreen({super.key, required this.story});

  @override
  State<AdminStoryDetailScreen> createState() => _AdminStoryDetailScreenState();
}

class _AdminStoryDetailScreenState extends State<AdminStoryDetailScreen> {
  final db = DatabaseService.instance;
  final storyService = StoryManagementService.instance;
  List<Map<String, dynamic>> chapters = [];
  bool isLoading = true;
  // Lưu story hiện tại để có thể cập nhật khi edit
  late Story _currentStory;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentStory = widget.story;
    _loadData();
    // 🔥 Lắng nghe khi có thay đổi từ admin (thêm/sửa/xóa chapter hoặc story)
    StoryRefreshService.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    StoryRefreshService.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  /// 🔥 Callback khi có thay đổi từ StoryRefreshService
  void _onDataChanged() {
    final changedStory = StoryRefreshService.instance.changedStoryTitle;
    
    // Nếu có chapter thay đổi và đúng truyện này
    if (changedStory == _currentStory.title && mounted) {
      _loadData();
      return;
    }
    
    // Nếu có story thay đổi (changedStory == null)
    if (changedStory == null && mounted) {
      _reloadStoryInfo();
    }
  }

  /// 🔥 Reload thông tin truyện từ DB
  Future<void> _reloadStoryInfo() async {
    try {
      db.clearCache();
      final updatedStories = await db.getStories();
      if (!mounted) return;
      
      final updated = updatedStories.firstWhere(
        (s) => s.title == _currentStory.title,
        orElse: () => _currentStory,
      );
      
      setState(() {
        _currentStory = updated;
        _hasChanges = true;
      });
      
      await _loadData();
    } catch (e) {
      print('❌ _reloadStoryInfo error: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    // Xóa cache để lấy dữ liệu mới nhất
    db.clearChapterCache(_currentStory.title);
    final data = await db.getChapters(_currentStory.title);
    setState(() {
      chapters = data;
      isLoading = false;
    });
  }

  Future<void> loadChapters() => _loadData();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final story = _currentStory;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Chi tiết truyện'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminEditStoryScreen(story: _currentStory),
                  ),
                );
                
                if (result == true && mounted) {
                  // Reload story data từ DB và cập nhật UI ngay lập tức
                  DatabaseService.instance.clearCache();
                  final updatedStories = await db.getStories();
                  if (!mounted) return;
                  final updated = updatedStories.firstWhere(
                    (s) => s.title == _currentStory.title,
                    orElse: () => _currentStory,
                  );
                  setState(() => _currentStory = updated);
                  await _loadData();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// IMAGE HEADER
              FutureBuilder<String>(
                future: ImageHelper.getImageFromStory(
                  title: story.title,
                  category: story.category,
                  pathFromDb: story.image,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final imagePath = snapshot.data!;

                  return Stack(
                    children: [
                      Image(
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        image: ImageHelper.getImageProvider(imagePath),
                      ),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    Text(
                      story.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// INFO CARDS
                    _infoCard(
                      icon: Icons.person,
                      label: 'Tác giả',
                      value: story.author,
                      theme: theme,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _infoCard(
                      icon: Icons.category,
                      label: 'Thể loại',
                      value: story.category,
                      theme: theme,
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _infoCard(
                            icon: Icons.book,
                            label: 'Số chương',
                            value: story.totalChapters.isEmpty ? 'N/A' : story.totalChapters,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoCard(
                            icon: Icons.info,
                            label: 'Trạng thái',
                            value: story.status.isEmpty ? 'N/A' : story.status,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// DESCRIPTION
                    Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      story.description.isEmpty
                          ? 'Chưa có mô tả'
                          : story.description,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ACTIONS
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminEditStoryScreen(story: _currentStory),
                                ),
                              );
                              
                              if (result == true && mounted) {
                                // Reload story data từ DB và cập nhật UI ngay lập tức
                                DatabaseService.instance.clearCache();
                                final updatedStories = await db.getStories();
                                if (!mounted) return;
                                final updated = updatedStories.firstWhere(
                                  (s) => s.title == _currentStory.title,
                                  orElse: () => _currentStory,
                                );
                                setState(() => _currentStory = updated);
                                await _loadData();
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Chỉnh sửa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminChapterManagementScreen(
                                    story: _currentStory,
                                  ),
                                ),
                              );
                              // Reload chapters sau khi quay lại từ quản lý chương
                              if (mounted) await _loadData();
                            },
                            icon: const Icon(Icons.list),
                            label: const Text('Quản lý chương'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// CHAPTERS LIST
                    Text(
                      'Danh sách chương (${chapters.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (chapters.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Chưa có chương nào',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: chapters.length > 10 ? 10 : chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = chapters[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                chapter['ten_chuong'] ?? '',
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: theme.iconTheme.color,
                              ),
                            ),
                          );
                        },
                      ),

                    if (chapters.length > 10)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            // TODO: Show all chapters
                          },
                          child: Text('Xem tất cả ${chapters.length} chương'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa truyện "${widget.story.title}"?\n\nHành động này sẽ xóa:\n- Thông tin truyện\n- Tất cả chương\n- Ảnh bìa\n\nKhông thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              // Delete story
              final success = await storyService.deleteStory(widget.story.title);
              
              if (!mounted) return;
              
              Navigator.pop(context); // Close loading
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Xóa truyện thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true); // Return to list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Xóa truyện thất bại!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
