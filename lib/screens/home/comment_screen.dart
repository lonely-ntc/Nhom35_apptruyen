import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class CommentScreen extends StatelessWidget {
  final String storyId;

  const CommentScreen({super.key, required this.storyId});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Bình luận")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.getComments(storyId),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final comments = snapshot.data!;

          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (_, index) {
              final c = comments[index];

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(c['content'] ?? ""),
                subtitle: const Text("1 ngày trước"),
              );
            },
          );
        },
      ),
    );
  }
}