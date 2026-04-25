/// 📝 TEXT HELPER - Format text cho UI
class TextHelper {
  /// Format category string - giới hạn số lượng thể loại hiển thị
  /// Input: "Tiên Hiệp, Huyền Huyễn, Dị Giới, Lịch Sử, Khác, Sắc"
  /// Output: "Tiên Hiệp, Huyền Huyễn, +4"
  static String formatCategories(String categories, {int maxShow = 2}) {
    if (categories.isEmpty) return '';
    
    final list = categories.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    if (list.length <= maxShow) {
      return list.join(', ');
    }
    
    final shown = list.take(maxShow).join(', ');
    final remaining = list.length - maxShow;
    return '$shown, +$remaining';
  }
  
  /// Lấy danh sách categories dạng List
  static List<String> getCategoryList(String categories) {
    if (categories.isEmpty) return [];
    return categories.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  
  /// Truncate text với ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
