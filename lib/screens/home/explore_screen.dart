import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'all_stories_screen.dart';
import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../widgets/story_card.dart';
import '../../utils/image_helper.dart';
import 'explore_category_screen.dart';
import 'category_detail_screen.dart';
import 'story_detail_screen.dart';
import 'search_screen.dart';
import '../../services/language_service.dart';
import '../../utils/app_text.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Story> stories = [];
  List<Story> filteredStories = [];

  bool isLoading = true;

  final List<String> categories = const [
    "Tiên Hiệp",
    "Kiếm Hiệp",
    "Ngôn Tình",
    "Đam Mỹ",
    "Bách Hợp",
    "Quan Trường",
    "Đô Thị",
    "Huyền Huyễn",
    "Xuyên Không",
    "Trọng Sinh",
    "Lịch Sử",
    "Hệ Thống",
    "Dị Giới",
    "Hiện Đại",
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future loadData() async {
    final s = await DatabaseService.instance.getStories();

    if (!mounted) return;

    setState(() {
      stories = s;
      filteredStories = s;
      isLoading = false;
    });
  }

  List<Story> get validStories {
    return filteredStories.where((s) {
      return s.image.isNotEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// 🔥 FIX LANGUAGE
    final lang = context.watch<LanguageService>().lang;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : stories.isEmpty
                ? Center(
                    child: Text(
                      AppText.get("no_data", lang),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// CATEGORY
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppText.get("category", lang), // 🔥 FIX
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ExploreCategoryScreen(),
                                  ),
                                );
                              },
                              child: Icon(Icons.arrow_forward_ios,
                                  size: 14,
                                  color: theme.iconTheme.color),
                            )
                          ],
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((e) {
                            return _Chip(e);
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        /// TRENDING
                        Text(
                          AppText.get("trending", lang), // 🔥 FIX
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount:
                              validStories.length > 4
                                  ? 4
                                  : validStories.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.62,
                          ),
                          itemBuilder: (_, index) {
                            return StoryCard(
                                story: validStories[index]);
                          },
                        ),

                        const SizedBox(height: 20),

                        /// ALL STORIES
                        Text(
                          AppText.get("all_story", lang), // 🔥 FIX
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        ListView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount:
                              filteredStories.length > 10
                                  ? 10
                                  : filteredStories.length,
                          itemBuilder: (_, index) {
                            final story =
                                filteredStories[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StoryDetailScreen(
                                            story: story),
                                  ),
                                );
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.only(bottom: 12),
                                padding:
                                    const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [

                                    /// IMAGE
                                    FutureBuilder<String>(
                                      future: ImageHelper.getImageFromStory(
                                        title: story.title,
                                        category:
                                            story.category,
                                        pathFromDb:
                                            story.image,
                                      ),
                                      builder:
                                          (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return Container(
                                            width: 60,
                                            height: 80,
                                            color: Colors.grey.shade200,
                                          );
                                        }

                                        final imagePath =
                                            snapshot.data!;

                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image(
                                            width: 60,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            image: ImageHelper.isNetwork(imagePath)
                                                ? NetworkImage(imagePath)
                                                : AssetImage(imagePath)
                                                    as ImageProvider,
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            story.title,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style:
                                                TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: theme.textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            story.author,
                                            style:
                                                TextStyle(
                                              color: theme.textTheme.bodySmall?.color,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            story.category,
                                            style:
                                                TextStyle(
                                              fontSize: 12,
                                              color:
                                                  theme.colorScheme.primary,
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
                        ),

                        const SizedBox(height: 10),

                        /// BUTTON
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AllStoriesScreen(),
                                ),
                              );
                            },
                            child: Text(
                              AppText.get("see_more", lang), // 🔥 FIX
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CategoryDetailScreen(category: text),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.deepPurple.withOpacity(0.3)
              : Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}