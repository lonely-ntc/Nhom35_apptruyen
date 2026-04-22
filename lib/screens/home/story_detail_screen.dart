// 👉 giữ nguyên import của bạn
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/user_service.dart';
import '../../models/story_model.dart';
import '../../services/database_service.dart';
import '../../utils/image_helper.dart';
import '../../utils/app_text.dart';
import '../../services/language_service.dart';

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
    loadUserRating();
  }

  Future loadUserRating() async {
    final rating = await db.getUserRating(
      storyId: widget.story.title,
      userId: userId,
    );

    setState(() {
      selectedRating = rating ?? 0;
    });
  }

  Future loadChapters() async {
    final data = await db.getChapters(widget.story.title);
    final list = List<Map<String, dynamic>>.from(data);

    setState(() {
      chapters = list;
      isLoading = false;
    });
  }

  Future loadFavorite() async {
    final result =
        await db.isFavorite(userId, widget.story.title);
    setState(() {
      isFavorite = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final theme = Theme.of(context);
    final lang = context.watch<LanguageService>().lang; // 🔥 THÊM

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: FutureBuilder<String>(
        future: ImageHelper.getImageFromStory(
          title: story.title,
          category: story.category,
          pathFromDb: story.image,
        ),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final imagePath = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [

                /// ===== HEADER =====
                Stack(
                  children: [
                    Image(
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      image: ImageHelper.isNetwork(imagePath)
                          ? NetworkImage(imagePath)
                          : AssetImage(imagePath)
                              as ImageProvider,
                    ),

                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),

                    SafeArea(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            _circleBtn(Icons.arrow_back,
                                () => Navigator.pop(context),
                                theme),
                            _circleBtn(Icons.share, _showShare,
                                theme),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      /// ===== INFO =====
                      Row(
                        children: [
                          ClipRRect(
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
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(story.title,
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      color: theme
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    )),

                                /// 🔥 FIX
                                Text(
                                  "${AppText.get("author", lang)}: ${story.author}",
                                  style: TextStyle(
                                      color: theme
                                          .textTheme
                                          .bodySmall
                                          ?.color),
                                ),

                                Text(
                                  "${AppText.get("category", lang)}: ${story.category}",
                                  style: TextStyle(
                                      color: theme
                                          .colorScheme
                                          .primary),
                                ),
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
                                storyId: story.title,
                              );
                              setState(() =>
                                  isFavorite = !isFavorite);
                            },
                          )
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// ===== BUTTON =====
                      AnimatedReadButton(
                        text: AppText.get("read_now", lang), // 🔥 FIX
                        onTap: () {
                          if (chapters.isEmpty) return;
                          _openChapter(chapters.first, 1);
                        },
                      ),

                      const SizedBox(height: 20),

                      /// ===== DESCRIPTION =====
                      Text(
                        AppText.get("description", lang), // 🔥 FIX
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),

                      Text(
                        story.description.isEmpty
                            ? AppText.get("no_description", lang)
                            : story.description,
                        style: TextStyle(
                            color: theme.textTheme.bodyMedium
                                ?.color),
                      ),

                      const SizedBox(height: 20),

                      /// ===== RATING (GIỮ NGUYÊN) =====
                      FutureBuilder<Map<int, int>>(
                        future:
                            db.getRatingStats(story.title),
                        builder: (_, snapshot) {
                          if (!snapshot.hasData)
                            return const SizedBox();

                          final stats = snapshot.data!;
                          final total = stats.values
                              .fold(0, (a, b) => a + b);

                          double avg = 0;
                          stats.forEach(
                              (k, v) => avg += k * v);
                          avg = total == 0 ? 0 : avg / total;

                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Row(
                                children: [
                                  Text(
                                    avg.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight:
                                          FontWeight.bold,
                                      color: theme
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children:
                                        List.generate(5,
                                            (index) {
                                      return Icon(
                                        index <
                                                avg.round()
                                            ? Icons.star
                                            : Icons
                                                .star_border,
                                        color:
                                            Colors.amber,
                                      );
                                    }),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              const SizedBox(height: 10),

                              /// 🔥 FIX
                              Text(AppText.get("rate_story", lang)),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children:
                                    List.generate(5,
                                        (index) {
                                  return IconButton(
                                    icon: Icon(
                                      index <
                                              selectedRating
                                          ? Icons.star
                                          : Icons
                                              .star_border,
                                      color:
                                          Colors.amber,
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        selectedRating =
                                            index + 1;
                                      });

                                      await db.rateStory(
                                        storyId:
                                            story.title,
                                        userId: userId,
                                        rating:
                                            index + 1,
                                      );
                                    },
                                  );
                                }),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      /// ===== COMMENT =====
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppText.get("comment", lang), // 🔥 FIX
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme
                                    .bodyLarge?.color),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CommentScreen(
                                          storyId:
                                              story.title),
                                ),
                              );
                            },
                            child: Text(
                              AppText.get("see_more", lang), // 🔥 FIX
                              style: TextStyle(
                                  color: theme
                                      .colorScheme
                                      .primary),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: commentController,
                        style: TextStyle(
                            color: theme.textTheme.bodyLarge
                                ?.color),
                        decoration: InputDecoration(
                          hintText: AppText.get("write_comment", lang), // 🔥 FIX
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              if (commentController.text.isEmpty) return;

                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;

                              final avatar =
                                  await UserService.instance.getAvatar();

                              await db.addComment(
                                storyId: story.title,
                                userId: userId,
                                content: commentController.text,
                                userName: user.displayName ?? "Người dùng",
                                avatar: avatar,
                              );

                              commentController.clear();
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// ===== CHAPTER =====
                      Text(
                        AppText.get("chapter_list", lang), // 🔥 FIX
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: chapters.length > 5 ? 5 : chapters.length,
                        itemBuilder: (_, index) {
                          final chap = chapters[index];

                          return GestureDetector(
                            onTap: () => _openChapter(chap, index + 1),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                chap['ten_chuong'],
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChapterListScreen(storyId: widget.story.title),
                            ),
                          );
                        },
                        child: Text(
                          AppText.get("see_more", lang), // 🔥 FIX
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                          ),
                        ),
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

  void _showShare() {}

  void _openChapter(Map<String, dynamic> chap, int index) {}

  Widget _circleBtn(
      IconData icon, VoidCallback onTap, ThemeData theme) {
    return CircleAvatar(
      backgroundColor: theme.cardColor,
      child: IconButton(
        icon: Icon(icon, color: theme.iconTheme.color),
        onPressed: onTap,
      ),
    );
  }
}

/// BUTTON (giữ animation)
class AnimatedReadButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;

  const AnimatedReadButton({
    super.key,
    required this.onTap,
    required this.text,
  });

  @override
  State<AnimatedReadButton> createState() =>
      _AnimatedReadButtonState();
}

class _AnimatedReadButtonState
    extends State<AnimatedReadButton> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => scale = 0.95),
      onTapUp: (_) => setState(() => scale = 1.0),
      onTapCancel: () => setState(() => scale = 1.0),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6A5AE0),
                Color(0xFF8F7BFF),
              ],
            ),
          ),
          child: Center(
            child: Text(
              widget.text, // 🔥 FIX LANG
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}