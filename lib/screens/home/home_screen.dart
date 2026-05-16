import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/story_card.dart';
import '../../widgets/shimmer_card.dart';
import '../../widgets/gradient_text.dart';
import '../../services/database_service.dart';
import '../../services/recommendation_service.dart';
import '../../services/popularity_service.dart';
import '../../services/story_refresh_service.dart';
import '../../models/story_model.dart';
import '../../services/language_service.dart';
import '../../utils/app_text.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_styles.dart';
import 'notification_screen.dart';
import 'explore_category_screen.dart';
import 'search_screen.dart';
import 'category_detail_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<Story> stories = [];
  List<Story> recommendedStories = [];
  List<Story> popularStories = [];
  bool isLoading = true;
  bool hasPreferences = false;
  
  // Cache để tránh load lại
  bool _hasLoadedRecommendations = false;
  bool _hasLoadedPopular = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Keep state alive để tránh rebuild khi switch tabs
  @override
  bool get wantKeepAlive => true;

  final categories = const [
    "Tiên Hiệp",
    "Kiếm Hiệp",
    "Ngôn Tình",
    "Đam Mỹ",
    "Bách Hợp",
    "Quan Trường",
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    loadData();
    // 🔥 Lắng nghe khi có truyện mới được thêm/sửa/xóa từ admin
    StoryRefreshService.instance.addListener(_onStoriesChanged);
  }

  /// 🔥 Callback khi StoryRefreshService thông báo có thay đổi
  void _onStoriesChanged() {
    if (mounted) {
      _refreshData();
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    StoryRefreshService.instance.removeListener(_onStoriesChanged);
    _animationController.dispose();
    super.dispose();
  }

  Future loadData() async {
    // Load stories từ SQLite + Firestore
    final data = await DatabaseService.instance.getStories();
    
    if (!mounted) return;
    
    setState(() {
      stories = data;
      isLoading = false;
    });

    // Load recommendations và popular stories song song trong background
    if (!_hasLoadedRecommendations || !_hasLoadedPopular) {
      Future.wait([
        if (!_hasLoadedRecommendations) loadRecommendations(),
        if (!_hasLoadedPopular) loadPopularStories(data),
      ]).catchError((e) {
        debugPrint('❌ Background loading error: $e');
        return <void>[];
      });
    }
  }

  /// 🔥 Gọi khi pull-to-refresh — xóa cache để lấy dữ liệu mới nhất
  Future<void> _refreshData() async {
    DatabaseService.instance.clearCache();
    PopularityService.instance.clearCache();
    setState(() {
      _hasLoadedPopular = false;
      _hasLoadedRecommendations = false;
    });
    await loadData();
  }

  Future<void> loadPopularStories(List<Story> allStories) async {
    // ✅ Cache check - chỉ load 1 lần
    if (_hasLoadedPopular && popularStories.isNotEmpty) {
      return;
    }
    
    try {
      print('🔥 Loading popular stories...');
      
      // ✅ Thêm timeout 5 giây để tránh load quá lâu
      final popular = await PopularityService.instance.getPopularStories(
        allStories,
        limit: 5,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ Popular stories timeout, using fallback');
          return allStories.take(5).toList();
        },
      );

      if (!mounted) return;

      setState(() {
        popularStories = popular;
        _hasLoadedPopular = true;
      });
      
      print('✅ Loaded ${popular.length} popular stories');
    } catch (e) {
      debugPrint('❌ loadPopularStories error: $e');
      // Fallback: use first 5 stories
      if (!mounted) return;
      setState(() {
        popularStories = allStories.take(5).toList();
        _hasLoadedPopular = true;
      });
    }
  }

  Future<void> loadRecommendations() async {
    if (_hasLoadedRecommendations) return; // Cache check
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ No user logged in');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        print('⚠️ User document not found');
        return;
      }

      final preferencesSet = doc.data()?['preferencesSet'] ?? false;
      print('📋 preferencesSet: $preferencesSet');

      if (preferencesSet) {
        final favCategories = List<String>.from(
          doc.data()?['favoriteCategories'] ?? [],
        );

        print('❤️ favoriteCategories: $favCategories');

        if (favCategories.isNotEmpty) {
          final recommended = await RecommendationService.instance
              .getRecommendedStories(favCategories);

          print('✅ Got ${recommended.length} recommended stories');

          if (!mounted) return;

          setState(() {
            recommendedStories = recommended;
            hasPreferences = true;
            _hasLoadedRecommendations = true; // Mark as loaded
          });
        } else {
          print('⚠️ No favorite categories');
        }
      } else {
        print('⚠️ Preferences not set');
      }
    } catch (e) {
      debugPrint('❌ loadRecommendations error: $e');
    }
  }

  List<Story> get validStories {
    return stories.where((s) => s.image.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final theme = Theme.of(context);
    final lang = context.watch<LanguageService>().lang;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : stories.isEmpty
                ? _buildEmptyState(theme, lang)
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(theme, context),
                            const SizedBox(height: AppStyles.space20),
                            
                            if (hasPreferences && recommendedStories.isNotEmpty)
                              _buildRecommendations(theme, lang),
                            
                            _buildPopularSection(theme, lang),
                            const SizedBox(height: AppStyles.space24),
                            _buildCategoriesSection(theme, lang, context),
                            const SizedBox(height: AppStyles.space24),
                            _buildNewUpdateSection(theme, lang),
                            const SizedBox(height: AppStyles.space32),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        elevation: 8,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(AppStyles.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerCard(width: 200, height: 30),
          const SizedBox(height: AppStyles.space20),
          Row(
            children: List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.only(right: AppStyles.space12),
                child: ShimmerStoryCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 80,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: AppStyles.space16),
          Text(
            AppText.get("no_data", lang),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.space16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    boxShadow: [AppStyles.purpleShadow],
                  ),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: AppStyles.space12),
                const GradientText(
                  text: "COMIC MANGA",
                  gradient: AppColors.purpleGradient,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                      boxShadow: [AppStyles.shadowSmall],
                    ),
                    child: Icon(
                      Icons.search,
                      color: theme.iconTheme.color,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppStyles.space8),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                      boxShadow: [AppStyles.shadowSmall],
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      color: theme.iconTheme.color,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(ThemeData theme, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppStyles.space12),
              Text(
                AppText.get("suggestions_for_you", lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppStyles.space16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
            scrollDirection: Axis.horizontal,
            itemCount: recommendedStories.length > 10 ? 10 : recommendedStories.length,
            cacheExtent: 500, // Tối ưu performance
            itemBuilder: (_, index) {
              final story = recommendedStories[index];
              return Padding(
                padding: const EdgeInsets.only(right: AppStyles.space12),
                child: SizedBox(
                  width: 140,
                  child: StoryCard(story: story),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppStyles.space24),
      ],
    );
  }

  Widget _buildPopularSection(ThemeData theme, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.pinkGradient,
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppStyles.space12),
                  Text(
                    AppText.get("popular", lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Badge trạng thái
              if (!_hasLoadedPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryPurple),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đang tải...',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (popularStories.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Top ${popularStories.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppStyles.space16),
        SizedBox(
          height: 190,
          child: !_hasLoadedPopular
              // Đang load: hiển thị shimmer
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppStyles.space16),
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(right: AppStyles.space12),
                    child: ShimmerStoryCard(),
                  ),
                )
              : popularStories.isEmpty
                  // Đã load xong nhưng không có truyện nào được đánh giá
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_border_rounded,
                            size: 40,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có truyện được đánh giá',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  // Đã có dữ liệu: hiển thị danh sách sắp xếp theo rating
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.space16),
                      scrollDirection: Axis.horizontal,
                      itemCount: popularStories.length,
                      cacheExtent: 500,
                      itemBuilder: (_, index) {
                        final story = popularStories[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(right: AppStyles.space12),
                          child: SizedBox(
                            width: 120,
                            child: StoryCard(
                              story: story,
                              showRating: true, // Luôn hiển thị rating trong section này
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, String lang, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.blueGradient,
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.category,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppStyles.space12),
                  Text(
                    AppText.get("category", lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExploreCategoryScreen(),
                    ),
                  );
                },
                child: Text(
                  AppText.get("see_all", lang),
                  style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppStyles.space16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppStyles.space12,
              crossAxisSpacing: AppStyles.space12,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final gradients = [
                AppColors.purpleGradient,
                AppColors.blueGradient,
                AppColors.pinkGradient,
                AppColors.orangeGradient,
                AppColors.greenGradient,
                AppColors.sunsetGradient,
              ];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(category: category),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradients[index % gradients.length],
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    boxShadow: [AppStyles.shadowMedium],
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewUpdateSection(ThemeData theme, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.greenGradient,
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
                child: const Icon(
                  Icons.fiber_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppStyles.space12),
              Text(
                AppText.get("new_update", lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppStyles.space16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
            scrollDirection: Axis.horizontal,
            itemCount: validStories.length > 10 ? 10 : validStories.length,
            cacheExtent: 500, // Tối ưu performance
            itemBuilder: (_, index) {
              final story = validStories[index];
              return Padding(
                padding: const EdgeInsets.only(right: AppStyles.space12),
                child: SizedBox(
                  width: 140,
                  child: StoryCard(story: story),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
