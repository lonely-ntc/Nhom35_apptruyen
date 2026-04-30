import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../services/user_service.dart';
import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../services/experience_service.dart';
import '../../services/notification_service.dart';
import '../../utils/image_helper.dart';
import '../../utils/app_text.dart';
import '../../services/language_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_styles.dart';

import '../../widgets/modern_button.dart';
import '../../widgets/animated_badge.dart';

import 'chapter_list_screen.dart';
import 'comment_screen.dart';
import 'reader_screen.dart';

class StoryDetailScreen extends StatefulWidget {
  final Story story;

  const StoryDetailScreen({super.key, required this.story});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final db = DatabaseService.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> chapters = [];
  bool isLoading = true;
  bool isFavorite = false;

  int selectedRating = 0;
  final commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadChapters();
    loadFavorite();
    loadUserRating();
  }

  Future loadUserRating() async {
    final rating = await db.getUserRating(
      storyId: widget.story.title,
      userId: userId,
    );

    setState(() {
      selectedRating = rating ?? 0;
    });
  }

  Future loadChapters() async {
    final data = await db.getChapters(widget.story.title);
    final list = List<Map<String, dynamic>>.from(data);

    setState(() {
      chapters = list;
      isLoading = false;
    });
  }

  Future loadFavorite() async {
    final result =
        await db.isFavorite(userId, widget.story.title);
    setState(() {
      isFavorite = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final theme = Theme.of(context);
    final lang = context.watch<LanguageService>().lang;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,

      body: FutureBuilder<String>(
        future: ImageHelper.getImageFromStory(
          title: story.title,
          category: story.category,
          pathFromDb: story.image,
        ),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final imagePath = snapshot.data!;

          return Stack(
            children: [
              // Main Content
              CustomScrollView(
                slivers: [
                  /// ===== PARALLAX HEADER =====
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    leading: _modernCircleBtn(
                      Icons.arrow_back,
                      () => Navigator.pop(context),
                      theme,
                    ),
                    actions: [
                      _modernCircleBtn(
                        Icons.share,
                        _showShare,
                        theme,
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Parallax Image (NO rounded corners)
                          Image(
                            fit: BoxFit.cover,
                            image: ImageHelper.isNetwork(imagePath)
                                ? NetworkImage(imagePath)
                                : AssetImage(imagePath) as ImageProvider,
                          ),
                          
                          // Gradient Overlay (NO rounded corners)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.7),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  /// ===== CONTENT WITH ROUNDED TOP =====
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Transform.translate(
                        offset: const Offset(0, -30),
                        child: Column(
                          children: [
                            const SizedBox(height: 30), // Compensate for transform
                            
                            /// ===== GLASSMORPHISM INFO CARD =====
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail with shadow
                                  Hero(
                                    tag: 'story_${story.title}',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [AppStyles.shadowLarge],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image(
                                          width: 75,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          image: ImageHelper.isNetwork(imagePath)
                                              ? NetworkImage(imagePath)
                                              : AssetImage(imagePath) as ImageProvider,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 14),
                                  
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          story.title,
                                          style: AppStyles.heading4.copyWith(
                                            color: theme.textTheme.bodyLarge?.color,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              size: 14,
                                              color: theme.textTheme.bodySmall?.color,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                story.author,
                                                style: AppStyles.bodySmall.copyWith(
                                                  color: theme.textTheme.bodySmall?.color,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 4),
                                        
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.category_outlined,
                                              size: 14,
                                              color: AppColors.primaryPurple,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                story.category,
                                                style: AppStyles.bodySmall.copyWith(
                                                  color: AppColors.primaryPurple,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 10),
                                        
                                        // Price Badge
                                        AnimatedBadge(
                                          text: _isFreeStory()
                                              ? AppText.get("free", lang)
                                              : "${_getStoryPrice()} đ",
                                          color: _isFreeStory()
                                              ? AppColors.successGreen
                                              : AppColors.primaryOrange,
                                          icon: _isFreeStory()
                                              ? Icons.check_circle
                                              : Icons.monetization_on,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ), // ✅ FIX: Đóng Container của Info Card
                          
                          const SizedBox(height: 16),
                          
                          /// ===== ACTION BUTTON =====
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FutureBuilder<bool>(
                              future: _checkIfPurchased(),
                              builder: (context, snapshot) {
                                final isPurchased = snapshot.data ?? false;
                                final isFree = _isFreeStory();
                                
                                if (isPurchased || isFree) {
                                  return ModernButton(
                                    text: AppText.get("read_now", lang),
                                    icon: Icons.menu_book_rounded,
                                    gradient: AppColors.purpleGradient,
                                    onPressed: () {
                                      if (chapters.isEmpty) return;
                                      _openChapter(chapters.first, 1);
                                    },
                                  );
                                }
                                
                                return ModernButton(
                                  text: "${AppText.get("buy_story", lang)} - ${_getStoryPrice()} đ",
                                  icon: Icons.shopping_cart_rounded,
                                  gradient: AppColors.orangeGradient,
                                  onPressed: _showPurchaseDialog,
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          /// ===== DESCRIPTION =====
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                      AppText.get("description", lang),
                                      style: AppStyles.heading4.copyWith(
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCard
                                        : AppColors.grey50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    story.description.isEmpty
                                        ? AppText.get("no_description", lang)
                                        : story.description,
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: theme.textTheme.bodyMedium?.color,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),

                          
                          /// ===== RATING SECTION =====
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FutureBuilder<Map<int, int>>(
                              future: db.getRatingStats(story.title),
                              builder: (_, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();

                                final stats = snapshot.data!;
                                final total = stats.values.fold(0, (a, b) => a + b);

                                double avg = 0;
                                stats.forEach((k, v) => avg += k * v);
                                avg = total == 0 ? 0 : avg / total;

                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.purpleGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [AppStyles.purpleShadow],
                                  ),
                                  child: Column(
                                    children: [
                                      // Average Rating Display
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            avg.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: List.generate(5, (index) {
                                                  return Icon(
                                                    index < avg.round()
                                                        ? Icons.star_rounded
                                                        : Icons.star_outline_rounded,
                                                    color: Colors.amber,
                                                    size: 24,
                                                  );
                                                }),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$total đánh giá',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      const Divider(color: Colors.white24),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // User Rating
                                      Text(
                                        AppText.get("rate_story", lang),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(5, (index) {
                                          return GestureDetector(
                                            onTap: () async {
                                              setState(() {
                                                selectedRating = index + 1;
                                              });

                                              await db.rateStory(
                                                storyId: story.title,
                                                userId: userId,
                                                rating: index + 1,
                                              );
                                              
                                              if (!mounted) return;
                                              final lang = context.read<LanguageService>().lang;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(AppText.get("rated_success", lang)),
                                                  backgroundColor: AppColors.successGreen,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: AnimatedScale(
                                              scale: index < selectedRating ? 1.2 : 1.0,
                                              duration: AppStyles.durationFast,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Icon(
                                                  index < selectedRating
                                                      ? Icons.star_rounded
                                                      : Icons.star_outline_rounded,
                                                  color: Colors.amber,
                                                  size: 36,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 24),

                          
                          /// ===== COMMENT SECTION =====
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.blueGradient,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppText.get("comment", lang),
                                      style: AppStyles.heading4.copyWith(
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CommentScreen(
                                              storyId: story.title,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                                      label: Text(AppText.get("see_more", lang)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCard
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [AppStyles.shadowMedium],
                                  ),
                                  child: TextField(
                                    controller: commentController,
                                    style: TextStyle(
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: AppText.get("write_comment", lang),
                                      hintStyle: TextStyle(
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      suffixIcon: Container(
                                        margin: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.blueGradient,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.send_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            if (commentController.text.isEmpty) return;

                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user == null) return;

                                            final avatar = await UserService.instance.getAvatar();

                                            await db.addComment(
                                              storyId: story.title,
                                              userId: userId,
                                              content: commentController.text,
                                              userName: user.displayName ?? "Người dùng",
                                              avatar: avatar,
                                            );

                                            commentController.clear();
                                            
                                            if (!mounted) return;
                                            final lang = context.read<LanguageService>().lang;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(AppText.get("comment_sent", lang)),
                                                backgroundColor: AppColors.successGreen,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),

                          
                          /// ===== CHAPTER LIST =====
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                      AppText.get("chapter_list", lang),
                                      style: AppStyles.heading4.copyWith(
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.orangeGradient,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${chapters.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: chapters.length > 5 ? 5 : chapters.length,
                                  itemBuilder: (_, index) {
                                    final chap = chapters[index];

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primaryPurple.withOpacity(0.1),
                                            AppColors.primaryBlue.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.primaryPurple.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () => _openChapter(chap, index + 1),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    gradient: AppColors.purpleGradient,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                
                                                const SizedBox(width: 12),
                                                
                                                Expanded(
                                                  child: Text(
                                                    chap['ten_chuong'],
                                                    style: AppStyles.bodyMedium.copyWith(
                                                      color: theme.textTheme.bodyLarge?.color,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                
                                                const SizedBox(width: 8),
                                                
                                                Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  size: 16,
                                                  color: AppColors.primaryPurple,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                
                                if (chapters.length > 5) ...[
                                  const SizedBox(height: 12),
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChapterListScreen(
                                              storyId: widget.story.title,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.list_rounded),
                                      label: Text(
                                        AppText.get("see_more", lang),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primaryPurple,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  ), // Đóng SliverToBoxAdapter
                ], // Đóng slivers array
              ), // Đóng CustomScrollView
              
              /// ===== FLOATING ACTION BUTTONS =====
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  children: [
                    // Favorite Button
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isFavorite
                              ? AppColors.pinkGradient
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade300,
                                    Colors.grey.shade400,
                                  ],
                                ),
                          boxShadow: [
                            if (isFavorite) AppStyles.pinkShadow
                            else AppStyles.shadowMedium,
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () async {
                              await db.toggleWishlist(
                                userId: userId,
                                storyId: story.title,
                              );
                              setState(() => isFavorite = !isFavorite);
                              
                              if (!mounted) return;
                              final lang = context.read<LanguageService>().lang;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFavorite 
                                        ? '✅ ${AppText.get("added_to_wishlist", lang)}'
                                        : '❌ ${AppText.get("removed_from_wishlist", lang)}',
                                  ),
                                  backgroundColor: isFavorite 
                                      ? AppColors.successGreen 
                                      : Colors.grey,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showShare() {
    // TODO: Implement share functionality
  }

  void _openChapter(Map<String, dynamic> chap, int chapterNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          title: widget.story.title,
          chapterTitle: chap['ten_chuong'] ?? 'Chương $chapterNumber',
          link: chap['link'] ?? '',
        ),
      ),
    );
  }

  /// 🔥 CHECK IF STORY IS FREE
  bool _isFreeStory() {
    return widget.story.isFree;
  }

  /// 🔥 GET STORY PRICE
  String _getStoryPrice() {
    return widget.story.price.toStringAsFixed(0);
  }

  /// 🔥 CHECK IF USER PURCHASED
  Future<bool> _checkIfPurchased() async {
    try {
      final purchased = await db.getPurchasedStories(userId);
      return purchased.any((p) => p['title'] == widget.story.title);
    } catch (e) {
      return false;
    }
  }

  /// 🔥 MODERN PURCHASE DIALOG
  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final lang = context.read<LanguageService>().lang;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [AppStyles.shadowXLarge],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
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
                          Icons.shopping_cart_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          AppText.get("buy_story", lang),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.story.title,
                        style: AppStyles.heading4.copyWith(
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryOrange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppText.get("price", lang),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_getStoryPrice()} đ',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard_rounded,
                              color: AppColors.successGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppText.get("you_will_receive", lang),
                                style: const TextStyle(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: theme.dividerColor,
                                  ),
                                ),
                              ),
                              child: Text(AppText.get("cancel", lang)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ModernButton(
                              text: AppText.get("buy_now", lang),
                              icon: Icons.check_circle_rounded,
                              gradient: AppColors.orangeGradient,
                              onPressed: () async {
                                Navigator.pop(context);
                                await _purchaseStory();
                              },
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
      },
    );
  }

  /// 🔥 PURCHASE STORY
  Future<void> _purchaseStory() async {
    try {
      // TODO: Implement payment logic
      // 1. Check user balance
      // 2. Deduct money
      // 3. Add to purchased list
      
      // Add to purchased list
      await db.addPurchasedStory(
        userId: userId,
        storyTitle: widget.story.title,
        storyImage: widget.story.image,
        price: widget.story.price,
      );
      
      // 🔥 ADD PURCHASE EXP (+1000 EXP)
      await ExperienceService.instance.addPurchaseExp(userId, widget.story.title);
      
      // 🔥 ADD PURCHASE NOTIFICATION
      await NotificationService.instance.notifyPurchase(
        userId: userId,
        storyTitle: widget.story.title,
        price: widget.story.price,
      );
      
      if (!mounted) return;
      final lang = context.read<LanguageService>().lang;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${AppText.get("purchase_success", lang)}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh UI
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      final lang = context.read<LanguageService>().lang;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${AppText.get("purchase_error", lang)}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔥 MODERN CIRCLE BUTTON
  Widget _modernCircleBtn(
      IconData icon, VoidCallback onTap, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.3),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// BUTTON (giữ animation)
class AnimatedReadButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  final Color? color;

  const AnimatedReadButton({
    super.key,
    required this.onTap,
    required this.text,
    this.color,
  });

  @override
  State<AnimatedReadButton> createState() =>
      _AnimatedReadButtonState();
}

class _AnimatedReadButtonState
    extends State<AnimatedReadButton> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => scale = 0.95),
      onTapUp: (_) => setState(() => scale = 1.0),
      onTapCancel: () => setState(() => scale = 1.0),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: widget.color != null
                  ? [
                      widget.color!,
                      widget.color!.withOpacity(0.8),
                    ]
                  : [
                      const Color(0xFF6A5AE0),
                      const Color(0xFF8F7BFF),
                    ],
            ),
          ),
          child: Center(
            child: Text(
              widget.text, // 🔥 FIX LANG
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}