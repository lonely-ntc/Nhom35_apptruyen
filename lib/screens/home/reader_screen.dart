import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/database_service.dart';

class ReaderScreen extends StatefulWidget {
  final String title;
  final String chapterTitle;
  final String link;

  const ReaderScreen({
    super.key,
    required this.title,
    required this.chapterTitle,
    required this.link,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  String content = "";
  bool isLoading = true;

  double fontSize = 18;
  bool isDarkMode = false;

  final ScrollController _scrollController = ScrollController();

  /// 🔥 NEW
  final db = DatabaseService.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  int currentChapter = 1;

  @override
  void initState() {
    super.initState();
    loadContent();

    /// 🔥 AUTO SAVE SCROLL
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent * 0.3) {
        saveProgress();
      }
    });
  }

  /// 🔥 LOAD CONTENT
  Future loadContent() async {
    try {
      final data = await DatabaseService.instance
          .getChapterContent(widget.link);

      if (!mounted) return;

      setState(() {
        content = data;
        isLoading = false;
      });

      /// 🔥 LOAD PROGRESS (OPTIONAL)
      saveProgress();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        content = "Lỗi tải nội dung";
        isLoading = false;
      });
    }
  }

  /// 🔥 SAVE FIREBASE
  Future saveProgress() async {
    await db.saveReadingProgress(
      userId: userId,
      storyId: widget.title,
      chapter: currentChapter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,

      /// APP BAR
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          widget.chapterTitle,
          style: TextStyle(color: textColor),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: textColor,
            ),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          )
        ],
      ),

      /// BODY
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [

                /// CONTENT
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Text(
                        content.isEmpty
                            ? "Không có nội dung"
                            : content,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 1.8,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),

                /// CONTROL BAR
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey.shade900
                        : Colors.grey.shade200,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                      )
                    ],
                  ),
                  child: Row(
                    children: [

                      /// FONT -
                      IconButton(
                        icon: Icon(Icons.remove, color: textColor),
                        onPressed: () {
                          setState(() {
                            if (fontSize > 12) fontSize -= 2;
                          });
                        },
                      ),

                      Text(
                        "${fontSize.toInt()}",
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),

                      /// FONT +
                      IconButton(
                        icon: Icon(Icons.add, color: textColor),
                        onPressed: () {
                          setState(() {
                            if (fontSize < 32) fontSize += 2;
                          });
                        },
                      ),

                      const SizedBox(width: 10),

                      /// SCROLL TOP
                      IconButton(
                        icon: Icon(Icons.vertical_align_top,
                            color: textColor),
                        onPressed: () {
                          _scrollController.animateTo(
                            0,
                            duration:
                                const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                          );
                        },
                      ),

                      const Spacer(),

                      /// PREV
                      IconButton(
                        icon:
                            Icon(Icons.arrow_back, color: textColor),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Chưa hỗ trợ chương trước"),
                            ),
                          );
                        },
                      ),

                      /// NEXT
                      IconButton(
                        icon: Icon(Icons.arrow_forward,
                            color: textColor),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Chưa hỗ trợ chương sau"),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}