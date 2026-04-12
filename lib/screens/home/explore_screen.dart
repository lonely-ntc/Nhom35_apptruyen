import 'package:flutter/material.dart';
import 'all_stories_screen.dart';
import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../widgets/story_card.dart';
import '../../utils/image_helper.dart';
import 'explore_category_screen.dart';
import 'category_detail_screen.dart';
import 'story_detail_screen.dart';
import 'search_screen.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : stories.isEmpty
                ? const Center(child: Text("Không có dữ liệu"))
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
                                const Text(
                                  "COMIC MANGA",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
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
                              icon: const Icon(Icons.search),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// CATEGORY
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Thể loại",
                                style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold)),
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
                              child: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14),
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
                        const Text("Thịnh hành",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),

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
                        const Text("Tất cả truyện",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),

                        const SizedBox(height: 10),

                        /// 🔥 GIỚI HẠN 10 TRUYỆN
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
                                  color: Colors.white,
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
                                            color: Colors
                                                .grey.shade200,
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
                                            image: ImageHelper
                                                    .isNetwork(
                                                        imagePath)
                                                ? NetworkImage(
                                                    imagePath)
                                                : AssetImage(
                                                        imagePath)
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
                                                const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            story.author,
                                            style:
                                                const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            story.category,
                                            style:
                                                const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.deepPurple,
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

                        /// 🔥 NÚT ĐỌC THÊM
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text("Đọc thêm"),
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
          color: Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.deepPurple),
        ),
      ),
    );
  }
}