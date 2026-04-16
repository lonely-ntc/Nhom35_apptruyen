class CommentModel {
  final String id;
  final String storyId;
  final String storyName;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.storyId,
    required this.storyName,
    required this.content,
    required this.createdAt,
  });
}