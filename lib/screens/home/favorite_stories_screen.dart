import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../services/language_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text.dart';
import '../../widgets/story_grid_card.dart';

class FavoriteStoriesScreen extends StatefulWidget {
  const FavoriteStoriesScreen({super.key});

  @override
  State<FavoriteStoriesScreen> createState() => _FavoriteStoriesScreenState();
}

class _FavoriteStoriesScreenState extends State<FavoriteStoriesScreen> {
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
    loadAllStories();
  }

  @override
  void dispose() {
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
    if (ids.isEmpty) return [];
    // So sánh cả title gốc và normalized để tương thích mọi trường hợp
    final normalizedIds = ids.map(_normalizeId).toSet();
    return allStories
        .where((s) =>
            (ids.contains(s.title) || normalizedIds.contains(_normalizeId(s.title))) &&
            s.title.toLowerCase().contains(searchText))
        .toList();
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
    vietnameseMap.forEach((k, v) => normalized = normalized.replaceAll(k, v));
    return normalized
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = context.watch<LanguageService>().lang;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.iconTheme.color,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.pinkGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(AppText.get("favorite_stories_title", lang)),
          ],
        ),
        actions: [
          IconButton(
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
        ],
      ),
      body: Column(
        children: [
          /// SEARCH FIELD
          if (isSearching)
            Container(
              margin: const EdgeInsets.all(16),
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
                  hintText: lang == "vi" ? 'Tìm kiếm truyện yêu thích...' : 'Search favorite stories...',
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

          /// CONTENT
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<String>>(
                    stream: db.getWishlist(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final stories = filterStories(snapshot.data!);

                      if (stories.isEmpty) {
                        return _buildEmptyState(theme, isDark);
                      }

                      return _buildGridView(stories, theme, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// ===== GRID VIEW =====
  Widget _buildGridView(List<Story> stories, ThemeData theme, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
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

  /// ===== EMPTY STATE =====
  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    final lang = context.watch<LanguageService>().lang;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.pinkGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.pinkGradient.colors.first.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            lang == "vi" ? 'Chưa có truyện yêu thích' : 'No favorite stories yet',
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
              lang == "vi" ? 'Thêm truyện vào yêu thích để đọc sau' : 'Add stories to favorites to read later',
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
