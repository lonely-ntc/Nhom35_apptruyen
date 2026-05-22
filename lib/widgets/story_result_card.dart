import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../utils/app_colors.dart';
import '../utils/image_helper.dart';
import '../screens/home/story_detail_screen.dart';

class StoryResultCard extends StatelessWidget {
  final Story story;
  final int index;

  const StoryResultCard({
    Key? key,
    required this.story,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoryDetailScreen(story: story),
            ),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Index badge ──────────────────────────────────────
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // ── Cover image (dùng ImageHelper giống StoryCard) ───
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 80,
                    child: _StoryImage(story: story, isDark: isDark),
                  ),
                ),
                const SizedBox(width: 10),

                // ── Info ─────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        story.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Author
                      _infoRow(
                        icon: Icons.person_outline_rounded,
                        text: story.author.isNotEmpty ? story.author : 'Không rõ',
                      ),
                      const SizedBox(height: 3),

                      // Category
                      _infoRow(
                        icon: Icons.local_library_outlined,
                        text: story.category.isNotEmpty ? story.category : '—',
                      ),

                      // Status (optional)
                      if (story.status.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _infoRow(
                          icon: Icons.info_outline_rounded,
                          text: story.status,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Price badge
                      _priceBadge(),
                    ],
                  ),
                ),

                // ── Arrow ────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.only(top: 2, left: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _priceBadge() {
    final isFree = story.isFree;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isFree ? Colors.green : Colors.orange).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isFree ? Colors.green : Colors.orange).withOpacity(0.6),
        ),
      ),
      child: Text(
        isFree ? 'Miễn phí' : '${story.price.toInt()} xu',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isFree ? Colors.green[700] : Colors.orange[700],
        ),
      ),
    );
  }
}

/// Widget load ảnh dùng ImageHelper — hỗ trợ cả asset lẫn network URL
class _StoryImage extends StatelessWidget {
  final Story story;
  final bool isDark;

  const _StoryImage({required this.story, required this.isDark});

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
          return _shimmer(isDark);
        }

        final path = snapshot.data!;
        final imageProvider = ImageHelper.isNetwork(path)
            ? NetworkImage(path) as ImageProvider
            : AssetImage(path) as ImageProvider;

        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(isDark),
        );
      },
    );
  }

  Widget _shimmer(bool isDark) {
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark ? Colors.grey[700] : Colors.grey[200],
      child: Icon(
        Icons.menu_book_rounded,
        size: 28,
        color: isDark ? Colors.grey[500] : Colors.grey[400],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class StoryResultsList extends StatelessWidget {
  final List<Story> stories;

  const StoryResultsList({
    Key? key,
    required this.stories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '📚 Tìm thấy ${stories.length} truyện:',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        ...stories.asMap().entries.map(
              (e) => StoryResultCard(story: e.value, index: e.key),
            ),
      ],
    );
  }
}
