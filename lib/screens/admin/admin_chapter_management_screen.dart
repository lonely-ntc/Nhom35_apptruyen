import 'package:flutter/material.dart';
import '../../services/chapter_management_service.dart';
import '../../services/notification_service.dart';
import '../../models/story_model.dart';


class AdminChapterManagementScreen extends StatefulWidget {
  final Story story;

  const AdminChapterManagementScreen({super.key, required this.story});

  @override
  State<AdminChapterManagementScreen> createState() =>
      _AdminChapterManagementScreenState();
}

class _AdminChapterManagementScreenState
    extends State<AdminChapterManagementScreen> {
  final _chapterService = ChapterManagementService.instance;
  List<Map<String, dynamic>> chapters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadChapters();
  }

  Future<void> loadChapters() async {
    setState(() => isLoading = true);
    final data = await _chapterService.getChaptersByStory(widget.story.title);
    setState(() {
      chapters = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý chương'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddChapterDialog(),
            tooltip: 'Thêm chương mới',
          ),
        ],
      ),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.story.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng số chương: ${chapters.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          /// CHAPTER LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : chapters.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 80,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có chương nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _showAddChapterDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm chương đầu tiên'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = chapters[index];
                          return _buildChapterItem(chapter, index, theme);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterItem(
    Map<String, dynamic> chapter,
    int index,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
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
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          'Nội dung: ${_truncateContent(chapter['noi_dung'] ?? '')}',
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditChapterDialog(chapter);
                break;
              case 'delete':
                _confirmDeleteChapter(chapter);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChapterDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm chương mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên chương *',
                  hintText: 'Ví dụ: Chương 1: Lần Đầu Tiên Gặp',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung *',
                  hintText: 'Nhập nội dung chương',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                );
                return;
              }

              Navigator.pop(context);

              // Tự động tạo link từ số chương
              final chapterNumber = chapters.length + 1;
              final autoLink = 'chuong-$chapterNumber';

              final success = await _chapterService.addChapter(
                storyTitle: widget.story.title,
                chapterTitle: titleController.text.trim(),
                link: autoLink,
                content: contentController.text.trim(),
              );

              if (success) {
                // 🔥 SEND NOTIFICATION TO FOLLOWERS
                await NotificationService.instance.notifyNewChapter(
                  storyTitle: widget.story.title,
                  chapterTitle: titleController.text.trim(),
                );
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Thêm chương thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
                loadChapters();
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Thêm chương thất bại!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditChapterDialog(Map<String, dynamic> chapter) {
    final titleController = TextEditingController(text: chapter['ten_chuong']);
    final contentController = TextEditingController(text: chapter['noi_dung']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa chương'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên chương',
                  hintText: 'Ví dụ: Chương 1: Lần Đầu Tiên Gặp',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  hintText: 'Nhập nội dung chương',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await _chapterService.updateChapter(
                oldLink: chapter['link'],
                storyTitle: widget.story.title,
                chapterTitle: titleController.text.trim(),
                newLink: chapter['link'], // Giữ nguyên link cũ
                content: contentController.text.trim(),
              );

              if (success) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Cập nhật chương thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
                loadChapters();
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Cập nhật chương thất bại!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChapter(Map<String, dynamic> chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${chapter['ten_chuong']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await _chapterService.deleteChapter(
                chapter['link'],
                widget.story.title,
              );

              if (success) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Xóa chương thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
                loadChapters();
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Xóa chương thất bại!'),
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

  /// Helper method to truncate content for display
  String _truncateContent(String content) {
    if (content.length <= 50) return content;
    return '${content.substring(0, 50)}...';
  }
}
