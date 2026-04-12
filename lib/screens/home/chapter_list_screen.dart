import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/database_service.dart';

class ChapterListScreen extends StatefulWidget {
  final String storyId;

  const ChapterListScreen({super.key, required this.storyId});

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  final db = DatabaseService.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> chapters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadChapters();
  }

  Future loadChapters() async {
    final data = await db.getChapters(widget.storyId);

    setState(() {
      chapters = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách chương"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (_, index) {
                final chap = chapters[index];

                return ListTile(
                  title: Text(chap['ten_chuong']),
                  onTap: () => _openChapter(chap, index + 1),
                );
              },
            ),
    );
  }

  void _openChapter(Map<String, dynamic> chap, int index) async {
    final content = await db.getChapterContent(chap['link']);

    await db.saveReadingProgress(
      userId: userId,
      storyId: widget.storyId,
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
}