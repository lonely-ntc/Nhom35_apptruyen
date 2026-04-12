import 'package:flutter/material.dart';
import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';
import 'transaction_history_screen.dart';
import 'story_detail_screen.dart';

class PurchasedScreen extends StatelessWidget {
  const PurchasedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Đã mua"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const TransactionHistoryScreen(),
                ),
              );
            },
            child: const Text("Lịch sử"),
          )
        ],
      ),

      body: FutureBuilder<List<Story>>(
        future: DatabaseService.instance.getStories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final stories = snapshot.data!;

          if (stories.isEmpty) {
            return const Center(
                child: Text("Chưa có truyện nào"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: stories.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      /// 🔥 IMAGE + TITLE
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.vertical(
                                  top: Radius.circular(14)),
                          child: Stack(
                            children: [

                              /// 🔥 FIX 100% IMAGE
                              Positioned.fill(
                                child:
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
                                        color: Colors
                                            .grey.shade200,
                                      );
                                    }

                                    final imagePath =
                                        snapshot.data!;

                                    return Image(
                                      fit: BoxFit.cover,
                                      image: ImageHelper
                                              .isNetwork(
                                                  imagePath)
                                          ? NetworkImage(
                                              imagePath)
                                          : AssetImage(
                                                  imagePath)
                                              as ImageProvider,
                                    );
                                  },
                                ),
                              ),

                              /// GRADIENT
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient:
                                        LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black
                                            .withOpacity(
                                                0.8),
                                      ],
                                      begin:
                                          Alignment.topCenter,
                                      end: Alignment
                                          .bottomCenter,
                                    ),
                                  ),
                                ),
                              ),

                              /// TITLE
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: Text(
                                  story.title,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                              /// TAG
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                          horizontal: 6,
                                          vertical: 2),
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius:
                                        BorderRadius
                                            .circular(6),
                                  ),
                                  child: const Text(
                                    "ĐÃ MUA",
                                    style: TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// INFO
                      Padding(
                        padding:
                            const EdgeInsets.all(8),
                        child: Text(
                          "Chương ${story.totalChapters}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}