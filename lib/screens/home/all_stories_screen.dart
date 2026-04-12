import 'package:flutter/material.dart';

import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';
import 'story_detail_screen.dart';
import 'filter_screen.dart';

class AllStoriesScreen extends StatefulWidget {
  const AllStoriesScreen({super.key});

  @override
  State<AllStoriesScreen> createState() =>
      _AllStoriesScreenState();
}

class _AllStoriesScreenState
    extends State<AllStoriesScreen> {

  List<Story> stories = [];
  List<Story> filtered = [];

  bool isLoading = true;
  bool isGrid = false;

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
      filtered = s;
      isLoading = false;
    });
  }

  /// 🔍 SEARCH
  void onSearch(String value) {
    setState(() {
      filtered = stories.where((s) {
        return s.title
            .toLowerCase()
            .contains(value.toLowerCase());
      }).toList();
    });
  }

  /// ⚙️ FILTER (FIX FULL)
  void openFilter() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FilterScreen(),
      ),
    );

    if (result == null) return;

    String sort = result["sort"];
    List selectedCategories = result["categories"];

    List<Story> temp = List.from(stories);

    /// 🔥 FILTER CATEGORY
    if (selectedCategories.isNotEmpty) {
      temp = temp.where((s) {
        return selectedCategories.any((c) =>
            s.category
                .toLowerCase()
                .contains(c.toLowerCase()));
      }).toList();
    }

    /// 🔥 SORT
    if (sort == "Mới xuất bản") {
      temp = temp.reversed.toList();
    }

    setState(() {
      filtered = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tất cả truyện"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                /// 🔥 SEARCH + FILTER + VIEW
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [

                      /// SEARCH
                      Expanded(
                        child: TextField(
                          onChanged: onSearch,
                          decoration: InputDecoration(
                            hintText: "Tìm truyện...",
                            prefixIcon:
                                const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// FILTER
                      IconButton(
                        onPressed: openFilter,
                        icon: const Icon(Icons.tune),
                      ),

                      /// TOGGLE GRID/LIST
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isGrid = !isGrid;
                          });
                        },
                        icon: Icon(
                          isGrid
                              ? Icons.view_list
                              : Icons.grid_view,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔥 LIST / GRID
                Expanded(
                  child: isGrid
                      ? GridView.builder(
                          padding:
                              const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (_, index) {
                            final story = filtered[index];

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
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  color: Colors.grey.shade200,
                                ),
                                child: Stack(
                                  children: [

                                    /// IMAGE (FIX CHUẨN)
                                    FutureBuilder<String>(
                                      future: ImageHelper
                                          .getImageFromStory(
                                        title: story.title,
                                        category:
                                            story.category,
                                        pathFromDb:
                                            story.image,
                                      ),
                                      builder:
                                          (context, snapshot) {
                                        if (!snapshot
                                            .hasData) {
                                          return const Center(
                                            child: Icon(Icons.image,
                                                size: 40),
                                          );
                                        }

                                        final imagePath =
                                            snapshot.data!;

                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(16),
                                          child: Image(
                                            width:
                                                double.infinity,
                                            height:
                                                double.infinity,
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

                                    /// GRADIENT
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(
                                                16),
                                        gradient:
                                            const LinearGradient(
                                          begin: Alignment
                                              .bottomCenter,
                                          end: Alignment.center,
                                          colors: [
                                            Colors.black87,
                                            Colors.transparent
                                          ],
                                        ),
                                      ),
                                    ),

                                    /// TITLE
                                    Positioned(
                                      left: 10,
                                      right: 10,
                                      bottom: 10,
                                      child: Text(
                                        story.title,
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    /// NEW TAG
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(8),
                                        ),
                                        child: const Text(
                                          "NEW",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (_, index) {
                            final story = filtered[index];

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
                                    const EdgeInsets.only(
                                        bottom: 12),
                                padding:
                                    const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                ),
                                child: Row(
                                  children: [

                                    /// IMAGE
                                    FutureBuilder<String>(
                                      future: ImageHelper
                                          .getImageFromStory(
                                        title: story.title,
                                        category:
                                            story.category,
                                        pathFromDb:
                                            story.image,
                                      ),
                                      builder:
                                          (context, snapshot) {
                                        if (!snapshot
                                            .hasData) {
                                          return Container(
                                            width: 60,
                                            height: 80,
                                            color: Colors
                                                .grey
                                                .shade200,
                                          );
                                        }

                                        final imagePath =
                                            snapshot.data!;

                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(8),
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
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            story.title,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: 4),
                                          Text(
                                            story.author,
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: 4),
                                          Text(
                                            story.category,
                                            style:
                                                const TextStyle(
                                              fontSize: 12,
                                              color: Colors
                                                  .deepPurple,
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
                ),
              ],
            ),
    );
  }
}