import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';
import 'story_detail_screen.dart';
import 'reader_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() =>
      _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final db = DatabaseService.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  List<Story> allStories = [];
  bool isLoading = true;

  String searchText = "";
  bool isSearching = false;

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadAllStories();
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
    return allStories
        .where((s) =>
            ids.contains(s.title) &&
            s.title.toLowerCase().contains(searchText))
        .toList();
  }

  List<Story> filterReading(Map<String, int> map) {
    return allStories
        .where((s) =>
            map.keys.contains(s.title) &&
            s.title.toLowerCase().contains(searchText))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // 🔥 FIX

      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        titleSpacing: 10,

        /// SEARCH UI
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Tìm truyện...",
                  hintStyle: TextStyle(
                      color: theme.textTheme.bodySmall?.color),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
              )
            : Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.dividerColor),
                      image: const DecorationImage(
                        image: AssetImage(
                            "assets/images/app_icon.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "COMIC MANGA",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: theme.iconTheme.color,
            ),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchText = "";
                searchController.clear();
              });
            },
          )
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                /// TAB
                Container(
                  color: theme.cardColor, // 🔥 FIX
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor:
                        theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.6),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.favorite_border),
                        text: "Truyện theo dõi",
                      ),
                      Tab(
                        icon: Icon(Icons.menu_book_outlined),
                        text: "Đang đọc",
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [

                      /// ❤️ WISHLIST
                      StreamBuilder<List<String>>(
                        stream: db.getWishlist(userId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child:
                                    CircularProgressIndicator());
                          }

                          final stories =
                              filterStories(snapshot.data!);

                          if (stories.isEmpty) {
                            return Center(
                              child: Text(
                                "Không có truyện",
                                style: TextStyle(
                                  color: theme
                                      .textTheme.bodyMedium?.color,
                                ),
                              ),
                            );
                          }

                          return _buildGridView(stories);
                        },
                      ),

                      /// 📖 READING
                      StreamBuilder<Map<String, int>>(
                        stream: db.getReadingList(userId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child:
                                    CircularProgressIndicator());
                          }

                          final map = snapshot.data!;
                          final stories =
                              filterReading(map);

                          return _buildReadingList(
                              stories, map);
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  /// GRID
  Widget _buildGridView(List<Story> stories) {
    final theme = Theme.of(context);

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: stories.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final story = stories[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    StoryDetailScreen(story: story),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: FutureBuilder<String>(
                    future: ImageHelper.getImageFromStory(
                      title: story.title,
                      category: story.category,
                      pathFromDb: story.image,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                            color: Colors.grey.shade200);
                      }

                      final imagePath = snapshot.data!;

                      return Image(
                        image: ImageHelper.isNetwork(imagePath)
                            ? NetworkImage(imagePath)
                            : AssetImage(imagePath)
                                as ImageProvider,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),

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

                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  /// READING
  Widget _buildReadingList(
      List<Story> stories, Map<String, int> map) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
        final chapter = map[story.title] ?? 1;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: db.getChapters(story.title),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox();
            }

            final chapters = snapshot.data!;
            final total = chapters.length;

            if (total == 0) return const SizedBox();

            final progress = chapter / total;

            return GestureDetector(
              onTap: () {
                final chap = chapters[chapter - 1];

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(
                      title: story.title,
                      chapterTitle: chap['ten_chuong'],
                      link: chap['link'],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.cardColor, // 🔥 FIX
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [

                    /// IMAGE
                    FutureBuilder<String>(
                      future: ImageHelper.getImageFromStory(
                        title: story.title,
                        category: story.category,
                        pathFromDb: story.image,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            width: 60,
                            height: 80,
                            color: Colors.grey.shade200,
                          );
                        }

                        final imagePath = snapshot.data!;

                        return ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Chương $chapter / $total",
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),

                          const SizedBox(height: 6),

                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor:
                                  Colors.grey.shade300,
                              color:
                                  theme.colorScheme.primary,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "${(progress * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}