import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../services/language_service.dart';
import '../../utils/image_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text.dart';
import 'transaction_history_screen.dart';
import 'story_detail_screen.dart';
import 'all_stories_screen.dart';

class PurchasedScreen extends StatefulWidget {
  const PurchasedScreen({super.key});

  @override
  State<PurchasedScreen> createState() => _PurchasedScreenState();
}

class _PurchasedScreenState extends State<PurchasedScreen> {
  final db = DatabaseService.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  /// 🔥 FORMAT DATE
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
        date = (timestamp as dynamic).toDate();
      } else if (timestamp is String) {
        date = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else {
        return "";
      }
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final langService = Provider.of<LanguageService>(context);
    final lang = langService.lang;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.shopping_bag,
                color: AppColors.primaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(AppText.get("purchased", lang)),
          ],
        ),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistoryScreen(),
                  ),
                );
              },
              icon: Icon(Icons.history, size: 18, color: AppColors.primaryPurple),
              label: Text(
                AppText.get("history", lang),
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.getPurchasedStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchased = snapshot.data ?? [];

          if (purchased.isEmpty) {
            return _buildEmptyState(theme, lang);
          }

          return Column(
            children: [
              /// HEADER INFO
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple,
                      AppColors.primaryPurple.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.library_books,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppText.get("your_library", lang),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${purchased.length} ${AppText.get('stories_purchased', lang)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${purchased.length}",
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// GRID
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: purchased.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.58,
                  ),
                  itemBuilder: (context, index) {
                    final story = purchased[index];
                    return _buildStoryCard(story, theme, isDark, lang);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ================= EMPTY STATE =================
  Widget _buildEmptyState(ThemeData theme, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: AppColors.primaryPurple.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppText.get("no_purchased_stories", lang),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.get("explore_and_buy", lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Load all stories
              final allStories = await DatabaseService.instance.getStories();
              
              if (!context.mounted) return;
              
              // Close loading
              Navigator.pop(context);
              
              // Navigate to AllStoriesScreen (use push, not pushReplacement)
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
            icon: const Icon(Icons.explore, size: 20),
            label: Text(AppText.get("explore_stories", lang)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= STORY CARD =================
  Widget _buildStoryCard(
    Map<String, dynamic> story,
    ThemeData theme,
    bool isDark,
    String lang,
  ) {
    return GestureDetector(
      onTap: () async {
        // 🔥 Query full story info (including description) from database
        final allStories = await db.getStories();
        final fullStory = allStories.firstWhere(
          (s) => s.title == story['title'],
          orElse: () => Story(
            title: story['title'],
            image: story['image'] ?? '',
            author: story['author'] ?? '',
            category: story['category'] ?? '',
            description: '',
          ),
        );

        if (!context.mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryDetailScreen(story: fullStory),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE — chiếm phần lớn card
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FutureBuilder<String>(
                        future: ImageHelper.getImageFromStory(
                          title: story['title'],
                          category: "",
                          pathFromDb: story['image'],
                        ),
                        builder: (_, snapshot) {
                          if (!snapshot.hasData) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          final imagePath = snapshot.data!;
                          return Image(
                            fit: BoxFit.cover,
                            image: ImageHelper.isNetwork(imagePath)
                                ? NetworkImage(imagePath)
                                : AssetImage(imagePath) as ImageProvider,
                          );
                        },
                      ),
                    ),

                    /// GRADIENT OVERLAY
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    /// PURCHASED BADGE
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green, Colors.green.shade700],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              AppText.get("purchased_badge", lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// INFO SECTION — chiều cao cố định, không dùng Expanded
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// TITLE
                  Text(
                    story['title'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.3,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),

                  /// CHAPTER + DATE trên cùng 1 hàng
                  Row(
                    children: [
                      Icon(Icons.menu_book,
                          size: 11, color: AppColors.primaryPurple),
                      const SizedBox(width: 3),
                      Text(
                        "${AppText.get('chapter', lang)} ${story['lastChapter'] ?? 1}",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      if (story['purchaseDate'] != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_today,
                            size: 10,
                            color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _formatDate(story['purchaseDate']),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  /// XEM TRUYỆN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () async {
                        // 🔥 Query full story info (including description) from database
                        final allStories = await db.getStories();
                        final fullStory = allStories.firstWhere(
                          (s) => s.title == story['title'],
                          orElse: () => Story(
                            title: story['title'],
                            image: story['image'] ?? '',
                            author: story['author'] ?? '',
                            category: story['category'] ?? '',
                            description: '',
                          ),
                        );

                        if (!context.mounted) return;
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryDetailScreen(story: fullStory),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_stories, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            lang == 'vi' ? 'Xem truyện' : 'View story',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
  }
}