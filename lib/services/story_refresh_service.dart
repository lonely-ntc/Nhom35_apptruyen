import 'package:flutter/foundation.dart';

/// 🔥 Service để thông báo cho các screen biết khi có truyện/chương thay đổi
class StoryRefreshService extends ChangeNotifier {
  static final StoryRefreshService instance = StoryRefreshService._();
  StoryRefreshService._();

  // Tiêu đề truyện vừa có chapter thay đổi (null = không có)
  String? _changedStoryTitle;
  String? get changedStoryTitle => _changedStoryTitle;

  /// Gọi khi có truyện mới được thêm, sửa, hoặc xóa
  void notifyStoriesChanged() {
    _changedStoryTitle = null;
    notifyListeners();
  }

  /// Gọi khi chapter của một truyện cụ thể thay đổi
  void notifyChaptersChanged(String storyTitle) {
    _changedStoryTitle = storyTitle;
    notifyListeners();
  }
}
