import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../services/language_service.dart';
import '../../utils/app_text.dart';
import '../../utils/image_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_styles.dart';
import '../../utils/text_helper.dart';
import 'story_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Story> stories = [];
  List<Story> recentSearches = [];
  bool isLoading = false;
  bool isGrid = false; // Default to list view for search

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        stories = [];
        isLoading = false;
      });
      return;
    }

    setState(() => isLoading = true);

    final data = await DatabaseService.instance.searchStories(keyword);

    if (!mounted) return;

    setState(() {
      stories = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageService>().lang;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : AppColors.grey50,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [AppStyles.shadowSmall],
          ),
          child: TextField(
            controller: _controller,
            onChanged: search,
            autofocus: true,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: AppText.get("search_hint", lang),
              hintStyle: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primaryPurple,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.iconTheme.color,
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() => stories = []);
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isGrid = !isGrid;
              });
            },
            icon: Icon(
              isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: theme.iconTheme.color,
            ),
          ),
        ],
      ),
      body: _buildBody(theme, lang, isDark),
    );
  }

  Widget _buildBody(ThemeData theme, String lang, bool isDark) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primaryPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tìm kiếm...',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    if (_controller.text.isEmpty) {
      return _buildEmptyState(theme);
    }

    if (stories.isEmpty) {
      return _buildNoResults(theme);
    }

    return isGrid
        ? _buildGridView(theme, isDark)
        : _buildListView(theme, isDark);
  }

  /// ===== EMPTY STATE (No search yet) =====
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tìm kiếm truyện',
            style: AppStyles.heading3.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập tên truyện, tác giả hoặc thể loại',
            style: AppStyles.bodyMedium.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  /// ===== NO RESULTS STATE =====
  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả',
            style: AppStyles.heading4.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác',
            style: AppStyles.bodyMedium.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  /// ===== GRID VIEW =====
  Widget _buildGridView(ThemeData theme, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) =>
          _buildGridItem(stories[index], theme, isDark),
    );
  }

  /// ===== LIST VIEW =====
  Widget _buildListView(ThemeData theme, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stories.length,
      itemBuilder: (context, index) =>
          _buildListItem(stories[index], theme, isDark),
    );
  }

  /// ===== MODERN GRID ITEM =====
  Widget _buildGridItem(Story story, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryDetailScreen(story: story),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppStyles.shadowMedium],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            Expanded(
              child: FutureBuilder<String>(
                future: ImageHelper.getImageFromStory(
                  title: story.title,
                  category: story.category,
                  pathFromDb: story.image,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    );
                  }

                  final imagePath = snapshot.data!;

                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image(
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      image: ImageHelper.isNetwork(imagePath)
                          ? NetworkImage(imagePath)
                          : AssetImage(imagePath) as ImageProvider,
                    ),
                  );
                },
              ),
            ),

            /// TITLE & INFO
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          story.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bodySmall.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      story.category,
                      style: AppStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== MODERN LIST ITEM =====
  Widget _buildListItem(Story story, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryDetailScreen(story: story),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppStyles.shadowMedium],
        ),
        child: Row(
          children: [
            /// IMAGE
            FutureBuilder<String>(
              future: ImageHelper.getImageFromStory(
                title: story.title,
                category: story.category,
                pathFromDb: story.image,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    width: 70,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                final imagePath = snapshot.data!;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [AppStyles.shadowMedium],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                      image: ImageHelper.isNetwork(imagePath)
                          ? NetworkImage(imagePath)
                          : AssetImage(imagePath) as ImageProvider,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 12),

            /// INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          story.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bodySmall.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          TextHelper.formatCategories(story.category, maxShow: 2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (story.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: AppColors.successGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'FREE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.monetization_on_rounded,
                                size: 12,
                                color: AppColors.primaryOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${story.price.toStringAsFixed(0)}đ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}