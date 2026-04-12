import 'package:flutter/material.dart';
import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';
import 'story_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool isGrid = true;
  List<Story> stories = [];
  bool isLoading = false;

  final TextEditingController _controller =
      TextEditingController();

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) {
      setState(() => stories = []);
      return;
    }

    setState(() => isLoading = true);

    final data =
        await DatabaseService.instance.searchStories(keyword);

    if (!mounted) return;

    setState(() {
      stories = data;
      isLoading = false;
    });

    print("SEARCH RESULT: ${stories.length}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),

        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _controller,
            onChanged: search,
            decoration: InputDecoration(
              hintText: "Tìm truyện...",
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  setState(() => stories = []);
                },
              ),
            ),
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isGrid = !isGrid;
              });
            },
            icon: Icon(
                isGrid ? Icons.view_list : Icons.grid_view),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : stories.isEmpty
                ? const Center(child: Text("Nhập để tìm truyện"))
                : isGrid
                    ? _buildGrid(stories)
                    : _buildList(stories),
      ),
    );
  }

  /// 🔥 GRID (FIX CHÍNH Ở ĐÂY)
  Widget _buildGrid(List<Story> stories) {
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
                  child: Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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
  Widget _buildList(List<Story> stories) {
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
              borderRadius: BorderRadius.circular(12),
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
                        width: 80,
                        height: 110,
                        color: Colors.grey.shade200,
                      );
                    }

                    final imagePath = snapshot.data!;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        width: 80,
                        height: 110,
                        fit: BoxFit.cover,
                        image: ImageHelper.isNetwork(imagePath)
                            ? NetworkImage(imagePath)
                            : AssetImage(imagePath)
                                as ImageProvider,
                      ),
                    );
                  },
                ),

                const SizedBox(width: 12),

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
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.author,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple,
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