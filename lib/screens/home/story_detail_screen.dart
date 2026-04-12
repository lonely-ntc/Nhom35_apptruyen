import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';
import 'chapter_list_screen.dart';
import 'comment_screen.dart';

class StoryDetailScreen extends StatefulWidget {
  final Story story;

  const StoryDetailScreen({super.key, required this.story});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final db = DatabaseService.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> chapters = [];
  bool isLoading = true;
  bool isFavorite = false;

  int selectedRating = 0;
  final commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadChapters();
    loadFavorite();
  }

  Future loadChapters() async {
    final data = await db.getChapters(widget.story.title);
    setState(() {
      chapters = data;
      isLoading = false;
    });
  }

  Future loadFavorite() async {
    final result = await db.isFavorite(userId, widget.story.title);
    setState(() {
      isFavorite = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FutureBuilder<String>(
        future: ImageHelper.getImageFromStory(
          title: story.title,
          category: story.category,
          pathFromDb: story.image,
        ),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final imagePath = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [

                /// HEADER
                Stack(
                  children: [
                    Image(
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      image: ImageHelper.isNetwork(imagePath)
                          ? NetworkImage(imagePath)
                          : AssetImage(imagePath) as ImageProvider,
                    ),
                    Container(
                      height: 300,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.white],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _circleBtn(Icons.arrow_back,
                              () => Navigator.pop(context)),
                          _circleBtn(Icons.share, _showShare),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// INFO
                      Row(
                        children: [
                          Image(
                            width: 60,
                            height: 80,
                            image: ImageHelper.isNetwork(imagePath)
                                ? NetworkImage(imagePath)
                                : AssetImage(imagePath) as ImageProvider,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(story.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text("Tác giả: ${story.author}"),
                                Text("Thể loại: ${story.category}"),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await db.toggleWishlist(
                                  userId: userId,
                                  storyId: story.title);
                              setState(() => isFavorite = !isFavorite);
                            },
                          )
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (chapters.isEmpty) return;
                              _openChapter(chapters.first, 1);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              backgroundColor: Colors.deepPurple,
                            ),
                            child: const Text(
                              "Đọc ngay",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      /// DESCRIPTION
                      const Text("Cốt truyện",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(story.description.isEmpty
                          ? "Không có mô tả"
                          : story.description),

                      const SizedBox(height: 20),

                      /// ⭐ RATING BREAKDOWN
                      FutureBuilder<Map<int, int>>(
                        future: db.getRatingStats(story.title),
                        builder: (_, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

                          final stats = snapshot.data!;
                          final total =
                              stats.values.fold(0, (a, b) => a + b);

                          double avg = 0;
                          stats.forEach((k, v) => avg += k * v);
                          avg = total == 0 ? 0 : avg / total;

                          return Row(
                            children: [
                              Text(avg.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 10),

                              Column(
                                children: List.generate(5, (i) {
                                  int star = 5 - i;
                                  int count = stats[star] ?? 0;
                                  double percent =
                                      total == 0 ? 0 : count / total;

                                  return Row(
                                    children: [
                                      Text("$star"),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 120,
                                        height: 6,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: LinearProgressIndicator(
                                            value: percent),
                                      ),
                                    ],
                                  );
                                }),
                              )
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      /// ⭐ USER RATE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedRating = index + 1;
                              });

                              db.rateStory(
                                storyId: story.title,
                                userId: userId,
                                rating: index + 1,
                              );
                            },
                          );
                        }),
                      ),

                      const SizedBox(height: 10),

                      /// COMMENT HEADER
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Bình luận",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommentScreen(
                                      storyId: story.title),
                                ),
                              );
                            },
                            child: const Text("Xem thêm",
                                style:
                                    TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// COMMENT INPUT
                      TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: "Viết bình luận...",
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              if (commentController.text.isEmpty)
                                return;

                              db.addComment(
                                storyId: story.title,
                                userId: userId,
                                content: commentController.text,
                              );

                              commentController.clear();
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// CHAPTER
                      const Text("Danh sách chương",
                          style: TextStyle(fontWeight: FontWeight.bold)),

                      ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount:
                            chapters.length > 5 ? 5 : chapters.length,
                        itemBuilder: (_, index) {
                          final chap = chapters[index];

                          return GestureDetector(
                            onTap: () =>
                                _openChapter(chap, index + 1),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Text(chap['ten_chuong']),
                            ),
                          );
                        },
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChapterListScreen(
                                  storyId: story.title),
                            ),
                          );
                        },
                        child: const Text("Xem thêm"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showShare() {
    showModalBottomSheet(
      context: context,
      builder: (_) =>
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Chia sẻ"),
          ),
    );
  }

  void _openChapter(Map<String, dynamic> chap, int index) async {
    final content = await db.getChapterContent(chap['link']);

    await db.saveReadingProgress(
      userId: userId,
      storyId: widget.story.title,
      chapter: index,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(chap['ten_chuong'])),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(content),
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onTap,
      ),
    );
  }
}