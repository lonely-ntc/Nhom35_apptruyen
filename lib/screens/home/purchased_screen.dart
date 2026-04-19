import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';
import 'transaction_history_screen.dart';
import 'story_detail_screen.dart';

class PurchasedScreen extends StatefulWidget {
  const PurchasedScreen({super.key});

  @override
  State<PurchasedScreen> createState() => _PurchasedScreenState();
}

class _PurchasedScreenState extends State<PurchasedScreen> {
  final db = DatabaseService.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> purchased = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPurchased();
  }

  Future loadPurchased() async {
    final data = await db.getPurchasedStories(userId);

    if (!mounted) return;

    setState(() {
      purchased = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // 🔥 FIX

      appBar: AppBar(
        title: const Text("Đã mua"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionHistoryScreen(),
                ),
              );
            },
            child: Text(
              "Lịch sử",
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          )
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : purchased.isEmpty
              ? Center(
                  child: Text(
                    "Chưa mua truyện nào",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: purchased.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final story = purchased[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryDetailScreen(
                              story: Story(
                                title: story['title'],
                                image: story['image'],
                                author: "",
                                category: "",
                                description: "",
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor, // 🔥 FIX
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            /// IMAGE
                            Expanded(
                              child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.vertical(
                                        top: Radius.circular(14)),
                                child: Stack(
                                  children: [

                                    Positioned.fill(
                                      child: FutureBuilder<String>(
                                        future: ImageHelper.getImageFromStory(
                                          title: story['title'],
                                          category: "",
                                          pathFromDb: story['image'],
                                        ),
                                        builder: (_, snapshot) {
                                          if (!snapshot.hasData) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                            );
                                          }

                                          final imagePath = snapshot.data!;

                                          return Image(
                                            fit: BoxFit.cover,
                                            image: ImageHelper.isNetwork(imagePath)
                                                ? NetworkImage(imagePath)
                                                : AssetImage(imagePath)
                                                    as ImageProvider,
                                          );
                                        },
                                      ),
                                    ),

                                    /// GRADIENT
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.8),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
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
                                        story['title'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),

                                    /// TAG
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          "ĐÃ MUA",
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
                            ),

                            /// INFO
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                "Đang đọc chương ${story['lastChapter'] ?? 1}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}