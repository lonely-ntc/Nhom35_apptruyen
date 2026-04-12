import 'package:flutter/material.dart';
import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';
import 'story_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState
    extends State<CategoryDetailScreen> {
  bool isGrid = true;
  List<Story> stories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// 🔥 LOAD DATA
  Future loadData() async {
    final allStories =
        await DatabaseService.instance.getStories();

    final filtered = allStories.where((story) {
      final categories =
          story.category.toLowerCase().split(',');

      return categories.any((c) =>
          c.trim() ==
          widget.category.toLowerCase());
    }).toList();

    setState(() {
      stories = filtered;
      isLoading = false;
    });

    print("CATEGORY ${widget.category}: ${stories.length}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.category,
          style: const TextStyle(color: Colors.black),
        ),
        iconTheme:
            const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isGrid = !isGrid;
              });
            },
            icon: Icon(
                isGrid ? Icons.view_list : Icons.grid_view),
          )
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stories.isEmpty
              ? _buildEmpty()
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child:
                      isGrid ? _buildGrid() : _buildList(),
                ),
    );
  }

  /// EMPTY
  Widget _buildEmpty() {
    return const Center(
      child: Text(
        "Chưa có truyện trong thể loại này",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  /// 🔥 GRID (FIX 100%)
  Widget _buildGrid() {
    return GridView.builder(
      itemCount: stories.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (_, index) {
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                /// 🔥 IMAGE FIX
                Expanded(
                  child: FutureBuilder<String>(
                    future: ImageHelper.getImageFromStory(
                      title: story.title,
                      category: story.category,
                      pathFromDb: story.image,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        );
                      }

                      final imagePath = snapshot.data!;

                      return ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(
                                top: Radius.circular(12)),
                        child: Image(
                          width: double.infinity,
                          fit: BoxFit.cover,
                          image: ImageHelper.isNetwork(
                                  imagePath)
                              ? NetworkImage(imagePath)
                              : AssetImage(imagePath)
                                  as ImageProvider,
                        ),
                      );
                    },
                  ),
                ),

                /// INFO
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Chương ${story.totalChapters}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
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
    );
  }

  /// LIST (GIỮ NGUYÊN)
  Widget _buildList() {
    return ListView.builder(
      itemCount: stories.length,
      itemBuilder: (_, index) {
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              children: [

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
                          BorderRadius.circular(8),
                      child: Image(
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                        image: ImageHelper.isNetwork(
                                imagePath)
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
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.author,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color:
                              Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Chương: ${story.totalChapters}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
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
  }
}