import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';
import '../../utils/app_text.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_styles.dart';
import '../../services/language_service.dart';

import 'story_detail_screen.dart';
import 'reader_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final db = DatabaseService.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  List<Story> allStories = [];
  bool isLoading = true;

  String searchText = "";
  bool isSearching = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadAllStories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future loadAllStories() async {
    final data = await db.getStories();

    if (!mounted) return;

    setState(() {
      allStories = data;
      isLoading = false;
    });
  }

  List<Story> filterStories(List<String> ids) {
    return allStories
        .where((s) =>
            ids.contains(s.title) &&
            s.title.toLowerCase().contains(searchText))
        .toList();
  }

  List<Story> filterReading(Map<String, int> map) {
    return allStories
        .where((s) =>
            map.keys.contains(s.title) &&
            s.title.toLowerCase().contains(searchText))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageService>().lang;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            /// ===== MODERN HEADER =====
            _buildModernHeader(theme, isDark),

            /// ===== MODERN TAB BAR =====
            _buildModernTabBar(theme, isDark),

            /// ===== CONTENT =====
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        /// ❤️ WISHLIST
                        StreamBuilder<List<String>>(
                          stream: db.getWishlist(userId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final stories = filterStories(snapshot.data!);

                            if (stories.isEmpty) {
                              return _buildEmptyState(
                                theme,
                                isDark,
                                Icons.favorite_border_rounded,
                                'Chưa có truyện yêu thích',
                                'Thêm truyện vào yêu thích để đọc sau',
                                AppColors.pinkGradient,
                              );
                            }

                            return _buildModernGridView(stories, theme, isDark);
                          },
                        ),

                        /// 📖 READING
                        StreamBuilder<Map<String, int>>(
                          stream: db.getReadingList(userId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final map = snapshot.data!;
                            final stories = filterReading(map);

                            if (stories.isEmpty) {
                              return _buildEmptyState(
                                theme,
                                isDark,
                                Icons.menu_book_outlined,
                                'Chưa có truyện đang đọc',
                                'Bắt đầu đọc truyện để theo dõi tiến độ',
                                AppColors.purpleGradient,
                              );
                            }

                            return _buildModernReadingList(
                                stories, map, theme, isDark, lang);
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== MODERN HEADER =====
  Widget _buildModernHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              /// APP ICON
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.purpleGradient,
                  boxShadow: [AppStyles.purpleShadow],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// TITLE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMIC MANGA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Thư viện của bạn',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),

              /// SEARCH BUTTON
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    isSearching ? Icons.close_rounded : Icons.search_rounded,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    setState(() {
                      isSearching = !isSearching;
                      if (!isSearching) {
                        searchText = "";
                        searchController.clear();
                      }
                    });
                  },
                ),
              ),
            ],
          ),

          /// SEARCH FIELD
          if (isSearching) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm truyện...',
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: theme.textTheme.bodySmall?.color,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              searchText = "";
                              searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ===== MODERN TAB BAR =====
  Widget _buildModernTabBar(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppStyles.shadowMedium],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.purpleGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [AppStyles.purpleShadow],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.favorite_rounded, size: 20),
            text: "Yêu thích",
            height: 60,
          ),
          Tab(
            icon: Icon(Icons.menu_book_rounded, size: 20),
            text: "Đang đọc",
            height: 60,
          ),
        ],
      ),
    );
  }

  /// ===== MODERN GRID VIEW =====
  Widget _buildModernGridView(
      List<Story> stories, ThemeData theme, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final story = stories[index];
        return _buildModernStoryCard(story, theme, isDark);
      },
    );
  }

  /// ===== MODERN STORY CARD =====
  Widget _buildModernStoryCard(Story story, ThemeData theme, bool isDark) {
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

                  /// FAVORITE BADGE
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppColors.pinkGradient,
                        shape: BoxShape.circle,
                        boxShadow: [AppStyles.pinkShadow],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// INFO
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.textTheme.bodyLarge?.color,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
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

  /// ===== MODERN READING LIST =====
  Widget _buildModernReadingList(List<Story> stories, Map<String, int> map,
      ThemeData theme, bool isDark, String lang) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
        final chapter = map[story.title] ?? 1;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: db.getChapters(story.title),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox();
            }

            final chapters = snapshot.data!;
            final total = chapters.length;

            if (total == 0) return const SizedBox();

            final progress = chapter / total;

            return GestureDetector(
              onTap: () {
                if (chapter > chapters.length) return;
                final chap = chapters[chapter - 1];

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(
                      title: story.title,
                      chapterTitle: chap['ten_chuong'],
                      link: chap['link'],
                    ),
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.textTheme.bodyLarge?.color,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.purpleGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Chương $chapter/$total",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "${(progress * 100).toStringAsFixed(0)}%",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          /// PROGRESS BAR
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : AppColors.grey100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ===== EMPTY STATE =====
  Widget _buildEmptyState(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
    Gradient gradient,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
