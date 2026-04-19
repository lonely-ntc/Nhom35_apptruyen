import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/story_card.dart';
import '../../services/database_service.dart';
import '../../models/story_model.dart';
import '../../services/language_service.dart';
import '../../utils/app_text.dart';
import 'notification_screen.dart';
import 'explore_category_screen.dart';
import 'search_screen.dart';
import 'category_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Story> stories = [];
  bool isLoading = true;

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
    loadData();
  }

  Future loadData() async {
    final data = await DatabaseService.instance.getStories();

    if (!mounted) return;

    setState(() {
      stories = data;
      isLoading = false;
    });
  }

  List<Story> get validStories {
    return stories.where((s) => s.image.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// 🔥 FIX QUAN TRỌNG
    final lang = context.watch<LanguageService>().lang;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        onPressed: () {},
        child: const Icon(Icons.chat, color: Colors.white),
      ),

      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : stories.isEmpty
                ? Center(
                    child: Text(
                      AppText.get("no_data", lang), // 🔥 FIX
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// HEADER
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 30,
                                  height: 30,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "COMIC MANGA",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
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
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SearchScreen(),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.search,
                                      color: theme.iconTheme.color),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationScreen(),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.notifications_none,
                                      color: theme.iconTheme.color),
                                ),
                              ],
                            )
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// POPULAR
                        _buildTitle(
                          AppText.get("popular", lang), // 🔥 FIX
                          context,
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          height: 190,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                validStories.length > 5
                                    ? 5
                                    : validStories.length,
                            itemBuilder: (_, index) {
                              final story = validStories[index];

                              return Padding(
                                padding:
                                    const EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: 120,
                                  child: StoryCard(story: story),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// CATEGORY
                        _buildTitle(
                          AppText.get("category", lang), // 🔥 FIX
                          context,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ExploreCategoryScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount: categories.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.8,
                          ),
                          itemBuilder: (context, index) {
                            final category = categories[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CategoryDetailScreen(
                                      category: category,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(14),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.asset(
                                        "assets/images/CATEGORY.jpg",
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withOpacity(
                                          theme.brightness ==
                                                  Brightness.dark
                                              ? 0.6
                                              : 0.25,
                                        ),
                                      ),
                                    ),

                                    Positioned(
                                      left: 12,
                                      bottom: 12,
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        /// NEW UPDATE
                        _buildTitle(
                          AppText.get("new_update", lang), // 🔥 FIX
                          context,
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                validStories.length > 10
                                    ? 10
                                    : validStories.length,
                            itemBuilder: (_, index) {
                              final story = validStories[index];

                              return Padding(
                                padding:
                                    const EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: 140,
                                  child: StoryCard(story: story),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTitle(String text, BuildContext context,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.iconTheme.color,
            ),
          ),
      ],
    );
  }
}