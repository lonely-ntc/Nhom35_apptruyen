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
    with SingleTickerProviderStateMixin {
  List<Story> stories = [];
  List<Story> recommendedStories = [];
  List<Story> popularStories = [];
  bool isLoading = true;
  bool hasPreferences = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _animationController.dispose();
    super.dispose();
  }

  Future loadData() async {
    // Load stories từ SQLite trước (nhanh nhất)
    final data = await DatabaseService.instance.getStories();
    
    if (!mounted) return;
    
    // Hiển thị UI ngay lập tức với data cơ bản
    setState(() {
      stories = data;
      isLoading = false;
    });

    // Load recommendations và popular stories song song trong background
    // Không block UI
    Future.wait([
      loadRecommendations(),
      loadPopularStories(data),
    ]).catchError((e) {
      print('❌ Background loading error: $e');
    });
  }

  Future<void> loadPopularStories(List<Story> allStories) async {
    try {
      // Giảm xuống 20 truyện để load nhanh hơn
      final limitedStories = allStories.take(20).toList();
      
      final popular = await PopularityService.instance.getPopularStories(
        limitedStories,
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        popularStories = popular;
      });
    } catch (e) {
      print('❌ loadPopularStories error: $e');
      // Fallback: use first 10 stories
      if (!mounted) return;
      setState(() {
        popularStories = allStories.take(10).toList();
      });
    }
  }

  Future<void> loadRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final preferencesSet = doc.data()?['preferencesSet'] ?? false;

      if (preferencesSet) {
        final favCategories = List<String>.from(
          doc.data()?['favoriteCategories'] ?? [],
        );

        if (favCategories.isNotEmpty) {
          final recommended = await RecommendationService.instance
              .getRecommendedStories(favCategories);

          setState(() {
            recommendedStories = recommended;
            hasPreferences = true;
          });
        }
      }
    } catch (e) {
      print('❌ loadRecommendations error: $e');
    }
  }

  List<Story> get validStories {
    return stories.where((s) => s.image.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                    onRefresh: loadData,
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
              const Text(
                'Gợi ý cho bạn',
                style: TextStyle(
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
    // Sử dụng popularStories hoặc fallback
    final displayStories = popularStories.isNotEmpty 
        ? popularStories.where((s) => s.image.isNotEmpty).take(10).toList()
        : validStories.take(5).toList();

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
            ],
          ),
        ),
        const SizedBox(height: AppStyles.space16),
        SizedBox(
          height: 190,
          child: displayStories.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
                  scrollDirection: Axis.horizontal,
                  itemCount: displayStories.length,
                  // Tối ưu performance
                  cacheExtent: 500,
                  itemBuilder: (_, index) {
                    final story = displayStories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: AppStyles.space12),
                      child: SizedBox(
                        width: 120,
                        child: StoryCard(story: story),
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
                  'Xem tất cả',
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
