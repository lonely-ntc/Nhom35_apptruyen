import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../services/language_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_styles.dart';
import '../../widgets/animated_badge.dart';
import '../../utils/image_helper.dart';
import '../../utils/text_helper.dart';
import 'story_detail_screen.dart';
import 'search_screen.dart';
import 'all_stories_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Story> stories = [];
  List<Story> allStories = [];
  List<Story> trendingStories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadAllStories();
  }

  Future<void> loadAllStories() async {
    setState(() => isLoading = true);

    // Load tất cả truyện từ database
    final data = await DatabaseService.instance.searchStories("");

    if (!mounted) return;

    // Debug: In ra số lượng truyện
    print('📚 Loaded ${data.length} stories from database');

    // Lấy 4 truyện đầu tiên làm trending (hoặc có thể sort theo rating sau)
    final trending = data.length >= 4 ? data.take(4).toList() : data;
    
    print('🔥 Trending stories: ${trending.length}');

    setState(() {
      allStories = data;
      stories = data.length >= 10 ? data.take(10).toList() : data; // Lấy tối đa 10 truyện
      trendingStories = trending;
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
      body: CustomScrollView(
        slivers: [
          /// ===== MODERN HEADER =====
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'KHÁM PHÁ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// ===== TRENDING SECTION =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: AppColors.orangeGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thịnh hành',
                    style: AppStyles.heading4.copyWith(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBadge(
                    text: '${trendingStories.length}',
                    color: AppColors.primaryOrange,
                    icon: Icons.local_fire_department_rounded,
                  ),
                ],
              ),
            ),
          ),

          /// ===== TRENDING STORIES (Horizontal Scroll - 4 items) =====
          if (isLoading)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (trendingStories.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 48,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có truyện thịnh hành',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: trendingStories.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 160,
                      margin: EdgeInsets.only(
                        right: index < trendingStories.length - 1 ? 12 : 0,
                      ),
                      child: _buildTrendingItem(
                        trendingStories[index],
                        theme,
                        isDark,
                      ),
                    );
                  },
                ),
              ),
            ),

          /// ===== ALL STORIES SECTION =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: AppColors.purpleGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tất cả truyện',
                    style: AppStyles.heading4.copyWith(
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBadge(
                    text: '${allStories.length}',
                    color: AppColors.primaryPurple,
                    icon: Icons.menu_book_rounded,
                  ),
                ],
              ),
            ),
          ),

          /// ===== STORIES GRID (10 items) =====
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (stories.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 64,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không có truyện nào',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildGridItem(stories[index], theme, isDark),
                  childCount: stories.length,
                ),
              ),
            ),

          /// ===== SEE ALL BUTTON =====
          if (!isLoading && stories.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllStoriesScreen(
                            category: "Tất cả",
                            allStories: allStories,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  /// ===== TRENDING ITEM (Horizontal Card) =====
  Widget _buildTrendingItem(Story story, ThemeData theme, bool isDark) {
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
              child: Stack(
                children: [
                  FutureBuilder<String>(
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
                              color: AppColors.primaryOrange,
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

                  // NEW Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.pinkGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [AppStyles.pinkShadow],
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Price Badge
                  if (!story.isFree)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.orangeGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${story.price.toStringAsFixed(0)}đ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            /// TITLE & AUTHOR
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
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 12,
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
                ],
              ),
            ),
          ],
        ),
      ),
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
            /// IMAGE WITH BADGE
            Expanded(
              child: Stack(
                children: [
                  FutureBuilder<String>(
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

                  // NEW Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.pinkGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [AppStyles.pinkShadow],
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Price Badge (bottom left)
                  if (!story.isFree)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.orangeGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${story.price.toStringAsFixed(0)}đ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
