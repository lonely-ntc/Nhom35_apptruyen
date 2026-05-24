import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_text.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_styles.dart';
import '../../utils/image_helper.dart';
import '../../services/language_service.dart';
import '../../widgets/story_grid_card.dart';

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

    print('📚 Loaded ${data.length} stories');
    if (data.isNotEmpty) {
      print('   First 5 story titles:');
      for (var i = 0; i < (data.length < 5 ? data.length : 5); i++) {
        print('   - "${data[i].title}"');
      }
    }

    setState(() {
      allStories = data;
      isLoading = false;
    });
  }

  List<Story> filterStories(List<String> ids) {
    // 🔥 Normalize để so sánh
    final normalizedIds = ids.map((id) => _normalizeId(id)).toSet();
    
    print('🔍 Wishlist IDs: $ids');
    print('🔍 Normalized IDs: $normalizedIds');
    print('🔍 Total stories: ${allStories.length}');
    
    final filtered = allStories
        .where((s) {
          // So sánh cả title gốc và normalized title
          final titleMatch = ids.contains(s.title);
          final normalizedMatch = normalizedIds.contains(_normalizeId(s.title));
          final searchMatch = s.title.toLowerCase().contains(searchText);
          
          if (titleMatch || normalizedMatch) {
            print('✅ Match found: "${s.title}" (titleMatch: $titleMatch, normalizedMatch: $normalizedMatch)');
          }
          
          return (titleMatch || normalizedMatch) && searchMatch;
        })
        .toList();
    
    print('🔍 Filtered stories: ${filtered.length}');
    return filtered;
  }

  List<Story> filterReading(Map<String, int> map) {
    // 🔥 Normalize keys để so sánh
    final normalizedMap = <String, int>{};
    map.forEach((key, value) {
      normalizedMap[_normalizeId(key)] = value;
    });
    
    print('🔍 Reading IDs: ${map.keys.toList()}');
    print('🔍 Normalized reading IDs: ${normalizedMap.keys.toList()}');
    
    final filtered = allStories
        .where((s) {
          // So sánh cả title gốc và normalized title
          final titleMatch = map.keys.contains(s.title);
          final normalizedMatch = normalizedMap.containsKey(_normalizeId(s.title));
          final searchMatch = s.title.toLowerCase().contains(searchText);
          
          if (titleMatch || normalizedMatch) {
            print('✅ Reading match found: "${s.title}" (titleMatch: $titleMatch, normalizedMatch: $normalizedMatch)');
          }
          
          return (titleMatch || normalizedMatch) && searchMatch;
        })
        .toList();
    
    print('🔍 Filtered reading stories: ${filtered.length}');
    return filtered;
  }

  /// 🔥 Normalize ID (giống như trong FirebaseService)
  /// Handles Vietnamese characters properly
  String _normalizeId(String text) {
    // Map Vietnamese characters to ASCII equivalents
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
    
    // Replace Vietnamese characters
    vietnameseMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
    
    // Remove special characters and replace spaces with underscores
    normalized = normalized
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    
    return normalized;
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
            _buildModernHeader(theme, isDark, lang),

            /// ===== MODERN TAB BAR =====
            _buildModernTabBar(theme, isDark, lang),

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
                                AppText.get("no_favorite", lang),
                                AppText.get("add_favorite_hint", lang),
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
                                AppText.get("no_reading", lang),
                                AppText.get("start_reading_hint", lang),
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
  Widget _buildModernHeader(ThemeData theme, bool isDark, String lang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          Row(
            children: [
              /// APP ICON
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 28,
                    height: 28,
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
                      AppText.get("app_name", lang),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      AppText.get("your_library", lang),
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
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    isSearching ? Icons.close_rounded : Icons.search_rounded,
                    color: theme.iconTheme.color,
                    size: 22,
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
                  hintText: AppText.get("search_hint", lang),
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
  Widget _buildModernTabBar(ThemeData theme, bool isDark, String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.grey50,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.purpleGradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
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
        tabs: [
          Tab(
            icon: Icon(Icons.favorite_rounded, size: 18),
            text: AppText.get("favorite_stories", lang),
          ),
          Tab(
            icon: Icon(Icons.menu_book_rounded, size: 18),
            text: AppText.get("reading", lang),
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
        return StoryGridCard(
          story: stories[index],
          badge: StoryGridCardBadge.favorite,
        );
      },
    );
  }

  /// ===== MODERN READING LIST =====
  Widget _buildModernReadingList(List<Story> stories, Map<String, int> map,
      ThemeData theme, bool isDark, String lang) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stories.length,
      cacheExtent: 500, // Tối ưu performance
      itemBuilder: (context, index) {
        final story = stories[index];
        final chapter = map[story.title] ?? 1;

        return _ReadingListItem(
          story: story,
          chapter: chapter,
          theme: theme,
          isDark: isDark,
          lang: lang,
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

/// ===== SEPARATE WIDGET TO AVOID NESTED FUTUREBUILDER =====
class _ReadingListItem extends StatelessWidget {
  final Story story;
  final int chapter;
  final ThemeData theme;
  final bool isDark;
  final String lang;

  const _ReadingListItem({
    required this.story,
    required this.chapter,
    required this.theme,
    required this.isDark,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.getChapters(story.title),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final chapters = snapshot.data!;
        final total = chapters.length;

        if (total == 0) return const SizedBox.shrink();

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
  }
}

