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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // 🔥 FIX

      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),

        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: theme.cardColor, // 🔥 FIX
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _controller,
            onChanged: search,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: "Tìm truyện...",
              hintStyle: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search,
                  color: theme.iconTheme.color),
              suffixIcon: IconButton(
                icon: Icon(Icons.close,
                    color: theme.iconTheme.color),
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
              isGrid ? Icons.view_list : Icons.grid_view,
              color: theme.iconTheme.color,
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : stories.isEmpty
                ? Center(
                    child: Text(
                      "Nhập để tìm truyện",
                      style: TextStyle(
                        color:
                            theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  )
                : isGrid
                    ? _buildGrid(stories)
                    : _buildList(stories),
      ),
    );
  }

  /// GRID
  Widget _buildGrid(List<Story> stories) {
    final theme = Theme.of(context);

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
              color: theme.cardColor, // 🔥 FIX
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                /// IMAGE
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

                /// TITLE
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.textTheme.bodyLarge?.color,
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

  /// LIST
  Widget _buildList(List<Story> stories) {
    final theme = Theme.of(context);

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
              color: theme.cardColor, // 🔥 FIX
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.author,
                        style: TextStyle(
                          color:
                              theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.category,
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
  }
}