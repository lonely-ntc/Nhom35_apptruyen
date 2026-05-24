import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';
import '../utils/image_helper.dart';
import '../utils/app_styles.dart';
import '../utils/app_colors.dart';
import '../utils/story_navigation_helper.dart';

class StoryCard extends StatefulWidget {
  final Story story;
  final bool showRating; // ✅ Option to disable rating

  const StoryCard({
    super.key,
    required this.story,
    this.showRating = false, // ✅ Default: không hiển thị rating để tăng performance
  });

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppStyles.durationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🔥 LOAD ẢNH CHUẨN (DÙNG CHUNG LOGIC)
  Widget buildImage() {
    return FutureBuilder<String>(
      future: ImageHelper.getImageFromStory(
        title: widget.story.title,
        category: widget.story.category,
        pathFromDb: widget.story.image,
      ),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return _loading();
        }

        final imagePath = snapshot.data!;

        return Image(
          image: ImageHelper.isNetwork(imagePath)
              ? NetworkImage(imagePath)
              : AssetImage(imagePath) as ImageProvider,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _placeholder();
          },
        );
      },
    );
  }

  /// ⏳ loading
  Widget _loading() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// ❌ fallback
  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.broken_image, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: () {
        // 🔥 Navigate với latest story data
        StoryNavigationHelper.navigateToStoryDetail(context, widget.story);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Opacity(
          opacity: _isPressed ? 0.8 : 1.0,
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
            boxShadow: [AppStyles.shadowMedium],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
                  child: Stack(
                    children: [
                      /// 📷 IMAGE
                      Positioned.fill(child: buildImage()),

                      /// 🌑 GRADIENT OVERLAY
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      /// 📝 TITLE
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Text(
                          widget.story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// 🔥 NEW TAG
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
                            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPink.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            "NEW",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      /// 📊 CHAPTER COUNT
                      if (widget.story.totalChapters.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.purpleGradient,
                              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryPurple.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.menu_book,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.story.totalChapters,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      /// 💰 PRICE TAG (if not free)
                      if (!widget.story.isFree)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.orangeGradient,
                              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryOrange.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                Text(
                                  '${widget.story.price.toStringAsFixed(0)} xu',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      /// ⭐ RATING BADGE - đọc trực tiếp từ Firebase
                      if (widget.showRating)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: _RatingBadge(storyId: widget.story.title),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

/// ⭐ Widget hiển thị rating badge - đọc trực tiếp từ Firebase
class _RatingBadge extends StatelessWidget {
  final String storyId;

  const _RatingBadge({required this.storyId});

  @override
  Widget build(BuildContext context) {
    // Dùng title gốc — nhất quán với cách rateStory() lưu dữ liệu
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .collection('ratings')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        final total = docs.length;
        double sum = 0;
        for (var doc in docs) {
          sum += (doc['rating'] as num?)?.toDouble() ?? 0;
        }
        final avg = sum / total;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            border: Border.all(
              color: Colors.amber.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
              const SizedBox(width: 2),
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '($total)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
