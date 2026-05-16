import 'package:flutter/material.dart';
import '../../services/chapter_management_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/story_refresh_service.dart';
import '../../models/story_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/image_helper.dart';

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
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadChapters();
    // 🔥 Lắng nghe khi có chapter thay đổi
    StoryRefreshService.instance.addListener(_onChaptersChanged);
  }

  @override
  void dispose() {
    StoryRefreshService.instance.removeListener(_onChaptersChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// 🔥 Callback khi có chapter thay đổi
  void _onChaptersChanged() {
    final changedStory = StoryRefreshService.instance.changedStoryTitle;
    if (changedStory == widget.story.title && mounted) {
      loadChapters();
    }
  }

  Future<void> loadChapters() async {
    setState(() => isLoading = true);
    // Xóa cache để lấy dữ liệu mới nhất từ Firestore
    DatabaseService.instance.clearChapterCache(widget.story.title);
    final data = await _chapterService.getChaptersByStory(widget.story.title);
    setState(() {
      chapters = data;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredChapters {
    if (_searchQuery.isEmpty) return chapters;
    return chapters.where((c) {
      final name = (c['ten_chuong'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(theme, innerBoxIsScrolled),
        ],
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredChapters.isEmpty
                ? _buildEmptyState(theme)
                : _buildChapterList(theme),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddChapterScreen(),
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm chương',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      floating: false,
      backgroundColor: theme.colorScheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Tìm chương...',
                hintStyle: TextStyle(color: Colors.white60),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
          : AnimatedOpacity(
              opacity: innerBoxIsScrolled ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                widget.story.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
      actions: [
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          )
        else
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => setState(() => _isSearching = true),
            tooltip: 'Tìm kiếm chương',
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeader(theme),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Ảnh bìa nhỏ
              FutureBuilder<String>(
                future: ImageHelper.getImageFromStory(
                  title: widget.story.title,
                  category: widget.story.category,
                  pathFromDb: widget.story.image,
                ),
                builder: (context, snapshot) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: snapshot.hasData
                        ? Image(
                            image: ImageHelper.getImageProvider(snapshot.data!),
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 60,
                            height: 80,
                            color: Colors.white24,
                            child: const Icon(Icons.book, color: Colors.white54),
                          ),
                  );
                },
              ),
              const SizedBox(width: 14),
              // Thông tin truyện
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.story.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _headerChip(
                          Icons.menu_book_rounded,
                          '${chapters.length} chương',
                        ),
                        const SizedBox(width: 8),
                        _headerChip(
                          Icons.person_outline,
                          widget.story.author,
                        ),
                      ],
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

  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isEmpty = chapters.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEmpty ? Icons.book_outlined : Icons.search_off_rounded,
                size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEmpty ? 'Chưa có chương nào' : 'Không tìm thấy chương',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEmpty
                  ? 'Nhấn nút bên dưới để thêm chương đầu tiên'
                  : 'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            if (isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _openAddChapterScreen(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm chương đầu tiên'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList(ThemeData theme) {
    final list = _filteredChapters;
    return RefreshIndicator(
      onRefresh: loadChapters,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _buildChapterCard(list[index], index, theme);
        },
      ),
    );
  }

  Widget _buildChapterCard(
    Map<String, dynamic> chapter,
    int index,
    ThemeData theme,
  ) {
    final title = chapter['ten_chuong']?.toString() ?? 'Chương ${index + 1}';
    final content = chapter['noi_dung']?.toString() ?? '';
    final wordCount = content.trim().isEmpty
        ? 0
        : content.trim().split(RegExp(r'\s+')).length;
    final charCount = content.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openEditChapterScreen(chapter),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Số thứ tự
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nội dung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _statChip(
                          theme,
                          Icons.text_fields_rounded,
                          '$wordCount từ',
                        ),
                        const SizedBox(width: 6),
                        _statChip(
                          theme,
                          Icons.format_size_rounded,
                          '$charCount ký tự',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.textTheme.bodySmall?.color,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') _openEditChapterScreen(chapter);
                  if (value == 'delete') _confirmDeleteChapter(chapter);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
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

  Widget _statChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.primary),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _openAddChapterScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChapterEditorScreen(
          story: widget.story,
          chapterNumber: chapters.length + 1,
        ),
      ),
    );
    if (result == true) loadChapters();
  }

  void _openEditChapterScreen(Map<String, dynamic> chapter) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChapterEditorScreen(
          story: widget.story,
          existingChapter: chapter,
          chapterNumber: chapters.indexOf(chapter) + 1,
        ),
      ),
    );
    if (result == true) loadChapters();
  }

  void _confirmDeleteChapter(Map<String, dynamic> chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Xóa chương'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc muốn xóa chương này?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chapter['ten_chuong'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hành động này không thể hoàn tác.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              nav.pop();

              final docId = chapter['firestoreDocId'] as String?;
              final isFirestore = chapter['isFirestore'] == true;

              final success = await _chapterService.deleteChapter(
                docId ?? chapter['link'] ?? '',
                widget.story.title,
                isFirestore: isFirestore,
              );
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success ? '✅ Xóa chương thành công!' : '❌ Xóa chương thất bại!',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
              if (success) loadChapters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHAPTER EDITOR SCREEN — Full-screen add/edit
// ═══════════════════════════════════════════════════════════════════════════

class _ChapterEditorScreen extends StatefulWidget {
  final Story story;
  final Map<String, dynamic>? existingChapter;
  final int chapterNumber;

  const _ChapterEditorScreen({
    required this.story,
    this.existingChapter,
    required this.chapterNumber,
  });

  @override
  State<_ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends State<_ChapterEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chapterService = ChapterManagementService.instance;

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final FocusNode _contentFocus = FocusNode();

  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isPreview = false;

  bool get _isEditing => widget.existingChapter != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingChapter?['ten_chuong'] ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingChapter?['noi_dung'] ?? '',
    );
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount => _contentController.text.length;

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bỏ thay đổi?'),
        content: const Text(
          'Bạn có thay đổi chưa lưu. Bạn có muốn thoát không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục chỉnh sửa'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Thoát', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success;

      if (_isEditing) {
        final docId = widget.existingChapter!['firestoreDocId'] as String?;
        final isFirestore = widget.existingChapter!['isFirestore'] == true;

        success = await _chapterService.updateChapter(
          storyTitle: widget.story.title,
          chapterTitle: _titleController.text.trim(),
          content: _contentController.text.trim(),
          chapterDocId: isFirestore ? docId : null,
          oldLink: isFirestore ? null : widget.existingChapter!['link'],
          newLink: isFirestore ? null : widget.existingChapter!['link'],
        );
      } else {
        final autoLink = 'chuong-${widget.chapterNumber}';
        success = await _chapterService.addChapter(
          storyTitle: widget.story.title,
          chapterTitle: _titleController.text.trim(),
          link: autoLink,
          content: _contentController.text.trim(),
          saveToFirestore: true,
        );

        if (success) {
          await NotificationService.instance.notifyNewChapter(
            storyTitle: widget.story.title,
            chapterTitle: _titleController.text.trim(),
          );
        }
      }

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? '✅ Cập nhật chương thành công!'
                  : '✅ Thêm chương thành công!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? '❌ Cập nhật thất bại!' : '❌ Thêm chương thất bại!',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  void _insertText(String before, String after) {
    final controller = _contentController;
    final selection = controller.selection;
    final text = controller.text;

    if (!selection.isValid) {
      controller.text = text + before + after;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length - after.length,
      );
      return;
    }

    final selectedText = selection.textInside(text);
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$before$selectedText$after',
    );
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + before.length + selectedText.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Story context bar
              _buildContextBar(theme),
              // Stats bar
              _buildStatsBar(theme),
              // Editor / Preview toggle
              Expanded(
                child: _isPreview
                    ? _buildPreview(theme)
                    : _buildEditor(theme),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(theme),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () async {
          final nav = Navigator.of(context);
          if (await _onWillPop()) nav.pop();
        },
      ),
      title: Text(
        _isEditing ? 'Chỉnh sửa chương' : 'Thêm chương mới',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        // Preview toggle
        IconButton(
          icon: Icon(
            _isPreview ? Icons.edit_rounded : Icons.preview_rounded,
            color: _isPreview ? AppColors.primaryPurple : null,
          ),
          onPressed: () => setState(() => _isPreview = !_isPreview),
          tooltip: _isPreview ? 'Chỉnh sửa' : 'Xem trước',
        ),
        // Save button
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton.icon(
                  onPressed: _hasChanges ? _save : null,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Lưu'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    disabledForegroundColor: Colors.grey,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildContextBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.story.title,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Chương ${widget.chapterNumber}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _contentController,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              _statItem(theme, Icons.text_fields_rounded, '$_wordCount từ'),
              const SizedBox(width: 16),
              _statItem(theme, Icons.format_size_rounded, '$_charCount ký tự'),
              const Spacer(),
              if (_hasChanges)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Chưa lưu',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildEditor(ThemeData theme) {
    return Column(
      children: [
        // Title field
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextFormField(
            controller: _titleController,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'Tên chương (vd: Chương 1: Khởi Đầu)',
              hintStyle: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              prefixIcon: Icon(
                Icons.title_rounded,
                color: theme.colorScheme.primary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên chương' : null,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _contentFocus.requestFocus(),
          ),
        ),

        // Formatting toolbar
        _buildFormattingToolbar(theme),

        // Content field
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextFormField(
              controller: _contentController,
              focusNode: _contentFocus,
              style: TextStyle(
                fontSize: 15,
                color: theme.textTheme.bodyLarge?.color,
                height: 1.7,
              ),
              decoration: InputDecoration(
                hintText:
                    'Nhập nội dung chương tại đây...\n\nMẹo: Dùng thanh công cụ bên trên để định dạng văn bản.',
                hintStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  height: 1.7,
                ),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(16),
                alignLabelWithHint: true,
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập nội dung chương' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormattingToolbar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolbarBtn(
              theme,
              icon: Icons.format_bold,
              tooltip: 'In đậm',
              onTap: () => _insertText('**', '**'),
            ),
            _toolbarDivider(theme),
            _toolbarBtn(
              theme,
              icon: Icons.format_italic,
              tooltip: 'In nghiêng',
              onTap: () => _insertText('_', '_'),
            ),
            _toolbarDivider(theme),
            _toolbarBtn(
              theme,
              icon: Icons.format_underline,
              tooltip: 'Gạch chân',
              onTap: () => _insertText('<u>', '</u>'),
            ),
            _toolbarDivider(theme),
            _toolbarBtn(
              theme,
              icon: Icons.format_quote_rounded,
              tooltip: 'Trích dẫn',
              onTap: () => _insertText('\n> ', '\n'),
            ),
            _toolbarDivider(theme),
            _toolbarBtn(
              theme,
              icon: Icons.horizontal_rule_rounded,
              tooltip: 'Dòng kẻ ngang',
              onTap: () => _insertText('\n\n---\n\n', ''),
            ),
            _toolbarDivider(theme),
            _toolbarBtn(
              theme,
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Danh sách',
              onTap: () => _insertText('\n- ', ''),
            ),
            _toolbarDivider(theme),
            _toolbarTextBtn(
              theme,
              label: '¶',
              tooltip: 'Đoạn văn mới',
              onTap: () => _insertText('\n\n', ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarBtn(
    ThemeData theme, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(
            icon,
            size: 18,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _toolbarTextBtn(
    ThemeData theme, {
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbarDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 20,
      color: theme.dividerColor,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.preview_rounded,
                  size: 14,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: 4),
                Text(
                  'Xem trước',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Chapter title
          Text(
            title.isEmpty ? '(Chưa có tên chương)' : title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: title.isEmpty
                  ? theme.textTheme.bodySmall?.color
                  : theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 12),
          // Content
          Text(
            content.isEmpty ? '(Chưa có nội dung)' : content,
            style: TextStyle(
              fontSize: 16,
              color: content.isEmpty
                  ? theme.textTheme.bodySmall?.color
                  : theme.textTheme.bodyLarge?.color,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                if (await _onWillPop()) nav.pop();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Hủy',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isEditing ? Icons.save_rounded : Icons.add_circle_rounded,
                      size: 18,
                    ),
              label: Text(_isEditing ? 'Cập nhật chương' : 'Thêm chương'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
