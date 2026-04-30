import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/story_management_service.dart';
import '../../services/language_service.dart';
import '../../models/story_model.dart';
import '../../utils/image_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text.dart';
import 'admin_story_detail_screen.dart';
import 'admin_add_story_screen.dart';
import 'admin_edit_story_screen.dart';

class AdminStoryScreen extends StatefulWidget {
  const AdminStoryScreen({super.key});

  @override
  State<AdminStoryScreen> createState() => _AdminStoryScreenState();
}

class _AdminStoryScreenState extends State<AdminStoryScreen> {
  final db = DatabaseService.instance;
  final storyService = StoryManagementService.instance;
  final _searchController = TextEditingController();

  List<Story> stories = [];
  List<Story> filteredStories = [];
  bool isLoading = true;
  String? errorMessage;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    loadStories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadStories() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await db.getStories();
      setState(() {
        stories = data;
        filteredStories = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ loadStories error: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _filterStories(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredStories = stories;
      } else {
        filteredStories = stories.where((story) {
          final titleLower = story.title.toLowerCase();
          final authorLower = story.author.toLowerCase();
          final categoryLower = story.category.toLowerCase();
          final searchLower = query.toLowerCase();
          
          return titleLower.contains(searchLower) ||
                 authorLower.contains(searchLower) ||
                 categoryLower.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageService>().lang;

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm truyện, tác giả, thể loại...',
                  hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                  border: InputBorder.none,
                ),
                onChanged: _filterStories,
              )
            : Text(AppText.get("manage_stories", lang)),
        actions: [
          if (isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  isSearching = false;
                  _searchController.clear();
                  filteredStories = stories;
                });
              },
              tooltip: 'Đóng tìm kiếm',
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  isSearching = true;
                });
              },
              tooltip: 'Tìm kiếm',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAddStoryScreen(),
                  ),
                );
                
                // Refresh list nếu thêm thành công
                if (result == true) {
                  loadStories();
                }
              },
              tooltip: 'Thêm truyện mới',
            ),
          ],
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Lỗi tải dữ liệu',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: loadStories,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : filteredStories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSearching ? Icons.search_off : Icons.menu_book_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isSearching
                                ? 'Không tìm thấy truyện nào'
                                : 'Chưa có truyện',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (isSearching) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Thử tìm kiếm với từ khóa khác',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Search result count
                        if (isSearching && _searchController.text.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tìm thấy ${filteredStories.length} truyện',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Story list
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: loadStories,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredStories.length,
                              itemBuilder: (context, index) {
                                final story = filteredStories[index];
                                return _buildStoryItem(story, theme);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  /// 🔥 BUILD STORY ITEM với ImageHelper
  Widget _buildStoryItem(Story story, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 🔥 IMAGE với FutureBuilder + ImageHelper
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: FutureBuilder<String>(
                future: ImageHelper.getImageFromStory(
                  title: story.title,
                  category: story.category,
                  pathFromDb: story.image,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      width: 75,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final imagePath = snapshot.data!;

                  return Image(
                    image: ImageHelper.getImageProvider(imagePath),
                    width: 75,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 75,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 30),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            /// TEXT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.textTheme.bodyLarge?.color,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (story.totalChapters.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${story.totalChapters} chương",
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (story.status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: story.status.contains("Hoàn")
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              story.status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: story.status.contains("Hoàn")
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// ACTIONS
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: theme.iconTheme.color,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editStory(story);
                    break;
                  case 'delete':
                    _deleteStory(story);
                    break;
                  case 'view':
                    _viewStory(story);
                    break;
                }
              },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 20),
                    SizedBox(width: 8),
                    Text('Xem chi tiết'),
                  ],
                ),
              ),
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

          const SizedBox(width: 4),
        ],
      ),
      ),
    );
  }

  /// 🔥 ACTIONS
  void _viewStory(Story story) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminStoryDetailScreen(story: story),
      ),
    );
    
    // Refresh nếu có thay đổi
    if (result == true) {
      loadStories();
    }
  }

  void _editStory(Story story) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditStoryScreen(story: story),
      ),
    );
    
    if (result == true) {
      loadStories();
    }
  }

  void _deleteStory(Story story) {
    final lang = context.read<LanguageService>().lang;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.get("confirm_delete", lang)),
        content: Text("${AppText.get("delete_story_confirm", lang)} '${story.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppText.get("cancel", lang)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              final success = await storyService.deleteStory(story.title);
              
              if (!mounted) return;
              
              Navigator.pop(context); // Close loading
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Xóa truyện thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
                loadStories(); // Refresh list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Xóa truyện thất bại!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}