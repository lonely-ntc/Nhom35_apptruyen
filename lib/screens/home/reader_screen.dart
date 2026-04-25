import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/database_service.dart';
import '../../services/experience_service.dart';
import '../../utils/app_colors.dart';
import 'comment_screen.dart';

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
  bool showControls = true;
  bool showControlBar = false; // Control bar ẩn mặc định

  final ScrollController _scrollController = ScrollController();

  /// 🔥 NEW
  final db = DatabaseService.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  int currentChapter = 1;
  List<Map<String, dynamic>> allChapters = [];

  /// 🔥 TIME TRACKING
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    
    /// 🔥 START TIME TRACKING
    _startTime = DateTime.now();
    
    loadChapters();
    loadContent();

    /// 🔥 AUTO SAVE SCROLL
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent * 0.3) {
        saveProgress();
      }
    });
  }

  @override
  void dispose() {
    /// 🔥 CALCULATE READING TIME & ADD EXP
    if (_startTime != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_startTime!);
      final minutes = duration.inMinutes;
      
      if (minutes > 0) {
        // Add reading exp asynchronously (don't await in dispose)
        ExperienceService.instance.addReadingExp(userId, minutes);
      }
    }
    
    _scrollController.dispose();
    super.dispose();
  }

  /// 🔥 LOAD CHAPTERS
  Future loadChapters() async {
    try {
      final chapters = await db.getChapters(widget.title);
      
      if (!mounted) return;
      
      setState(() {
        allChapters = chapters;
        // Find current chapter index
        currentChapter = chapters.indexWhere(
          (ch) => ch['link'] == widget.link
        ) + 1;
        if (currentChapter == 0) currentChapter = 1;
      });
    } catch (e) {
      debugPrint('❌ loadChapters error: $e');
    }
  }

  /// 🔥 LOAD CONTENT
  Future loadContent() async {
    setState(() => isLoading = true);
    
    try {
      final data = await DatabaseService.instance
          .getChapterContent(widget.link);

      if (!mounted) return;

      setState(() {
        content = data;
        isLoading = false;
      });

      /// 🔥 SAVE PROGRESS
      saveProgress();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        content = "Lỗi tải nội dung";
        isLoading = false;
      });
    }
  }

  /// 🔥 NAVIGATE TO CHAPTER
  void goToChapter(int index) {
    if (index < 0 || index >= allChapters.length) return;
    
    final chapter = allChapters[index];
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          title: widget.title,
          chapterTitle: chapter['ten_chuong'],
          link: chapter['link'],
        ),
      ),
    );
  }

  /// 🔥 SHOW CHAPTER LIST
  void showChapterList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.list_rounded,
                      color: AppColors.primaryPurple,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Danh sách chương",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${allChapters.length} chương",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Chapter list
              Expanded(
                child: ListView.builder(
                  itemCount: allChapters.length,
                  itemBuilder: (context, index) {
                    final chapter = allChapters[index];
                    final isCurrent = index == currentChapter - 1;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primaryPurple
                              : (isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? Colors.white
                                  : (isDarkMode
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        chapter['ten_chuong'],
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent
                              ? AppColors.primaryPurple
                              : (isDarkMode ? Colors.white : Colors.black),
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(
                              Icons.play_circle_filled,
                              color: AppColors.primaryPurple,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (!isCurrent) {
                          goToChapter(index);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
      appBar: showControls
          ? AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              iconTheme: IconThemeData(color: textColor),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chapterTitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                  if (allChapters.isNotEmpty)
                    Text(
                      "Chương $currentChapter/${allChapters.length}",
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              actions: [
                /// DARK MODE TOGGLE
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
                ),

                /// CHAPTER LIST
                IconButton(
                  icon: Icon(
                    Icons.list_rounded,
                    color: textColor,
                  ),
                  onPressed: showChapterList,
                ),

                /// COMMENTS
                IconButton(
                  icon: Icon(
                    Icons.comment_rounded,
                    color: textColor,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentScreen(
                          storyId: widget.title,
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,

      /// BODY
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                /// CONTENT
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showControls = !showControls;
                    });
                  },
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        20,
                        16,
                        showControlBar ? 200 : 80, // Extra padding when control bar is open
                      ),
                      child: Text(
                        content.isEmpty ? "Không có nội dung" : content,
                        style: TextStyle(
                          fontSize: fontSize,
                          height: 1.8,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),

                /// FLOATING CONTROL BUTTON (when control bar is hidden)
                if (!showControlBar && showControls)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      backgroundColor: AppColors.primaryPurple,
                      onPressed: () {
                        setState(() {
                          showControlBar = true;
                        });
                      },
                      child: const Icon(
                        Icons.tune,
                        color: Colors.white,
                      ),
                    ),
                  ),

                /// CONTROL BAR (expandable)
                if (showControlBar)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade900
                            : Colors.grey.shade200,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          )
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// CLOSE BUTTON
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Điều khiển",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: textColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      showControlBar = false;
                                    });
                                  },
                                ),
                              ],
                            ),

                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            /// ROW 1: Font size & Scroll
                            Row(
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
                                    fontWeight: FontWeight.bold,
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

                                /// SCROLL BOTTOM
                                IconButton(
                                  icon: Icon(Icons.vertical_align_bottom,
                                      color: textColor),
                                  onPressed: () {
                                    _scrollController.animateTo(
                                      _scrollController
                                          .position.maxScrollExtent,
                                      duration:
                                          const Duration(milliseconds: 400),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            /// ROW 2: Chapter navigation
                            Row(
                              children: [
                                /// PREV CHAPTER
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: currentChapter > 1
                                        ? () => goToChapter(currentChapter - 2)
                                        : null,
                                    icon:
                                        const Icon(Icons.arrow_back, size: 18),
                                    label: const Text("Chương trước"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: currentChapter > 1
                                          ? AppColors.primaryPurple
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                /// NEXT CHAPTER
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        currentChapter < allChapters.length
                                            ? () => goToChapter(currentChapter)
                                            : null,
                                    icon: const Icon(Icons.arrow_forward,
                                        size: 18),
                                    label: const Text("Chương sau"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          currentChapter < allChapters.length
                                              ? AppColors.primaryPurple
                                              : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}