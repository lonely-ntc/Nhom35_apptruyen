import 'package:flutter/material.dart';

import '../models/story_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../utils/image_helper.dart';
import '../utils/story_navigation_helper.dart';

/// Enum để chọn loại badge hiển thị góc trên phải của card
enum StoryGridCardBadge {
  none,
  favorite, // ❤️ dùng cho wishlist / favorites
  purchased, // ✅ dùng cho purchased
}

/// Widget card truyện dùng chung cho tất cả màn hình grid:
/// - WishlistScreen (tab Yêu thích)
/// - FavoriteStoriesScreen
/// - AllStoriesScreen
/// - CategoryDetailScreen
///
/// Thiết kế nhất quán:
/// - borderRadius: 16
/// - padding info: EdgeInsets.all(12)
/// - Hiển thị: ảnh bìa, tiêu đề (2 dòng), tác giả, badge giá
class StoryGridCard extends StatelessWidget {
  final Story story;
  final StoryGridCardBadge badge;

  const StoryGridCard({
    super.key,
    required this.story,
    this.badge = StoryGridCardBadge.none,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => StoryNavigationHelper.navigateToStoryDetail(context, story),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [AppStyles.shadowMedium],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ── ẢNH BÌA ──────────────────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    /// Ảnh
                    _StoryGridImage(story: story, isDark: isDark),

                    /// Gradient overlay nhẹ
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    /// Badge góc trên phải
                    if (badge != StoryGridCardBadge.none)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildBadge(),
                      ),

                    /// Badge giá (nếu có phí) — góc trên trái
                    if (!story.isFree)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.orangeGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryOrange.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on,
                                  color: Colors.white, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                '${story.price.toInt()} xu',
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

            /// ── THÔNG TIN ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Tiêu đề
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.3,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),

                  /// Tác giả
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
                          story.author.isNotEmpty ? story.author : 'Không rõ',
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

  Widget _buildBadge() {
    switch (badge) {
      case StoryGridCardBadge.favorite:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppColors.pinkGradient,
            shape: BoxShape.circle,
            boxShadow: [AppStyles.pinkShadow],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 14,
          ),
        );
      case StoryGridCardBadge.purchased:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green.shade700],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 10),
              SizedBox(width: 3),
              Text(
                'Đã mua',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case StoryGridCardBadge.none:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Widget load ảnh bìa — dùng ImageHelper, hỗ trợ asset + network
class _StoryGridImage extends StatelessWidget {
  final Story story;
  final bool isDark;

  const _StoryGridImage({required this.story, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: ImageHelper.getImageFromStory(
        title: story.title,
        category: story.category,
        pathFromDb: story.image,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: isDark ? AppColors.darkCard : AppColors.grey100,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryPurple,
              ),
            ),
          );
        }

        final path = snapshot.data!;
        return Image(
          fit: BoxFit.cover,
          image: ImageHelper.isNetwork(path)
              ? NetworkImage(path) as ImageProvider
              : AssetImage(path) as ImageProvider,
          errorBuilder: (context, error, stackTrace) => Container(
            color: isDark ? Colors.grey[700] : Colors.grey[200],
            child: Icon(
              Icons.menu_book_rounded,
              size: 40,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        );
      },
    );
  }
}
