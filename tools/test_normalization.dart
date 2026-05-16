/// Script to test ID normalization logic
/// Chạy: dart tools/test_normalization.dart

void main() {
  print('🔍 Testing ID Normalization Logic\n');

  final testCases = [
    'Naruto Shippuden',
    'One Piece',
    'Thám Tử Lừng Danh Conan',
    'Bleach',
    'Dragon Ball Z',
    'Attack on Titan',
    'My Hero Academia',
    'Demon Slayer: Kimetsu no Yaiba',
    'Jujutsu Kaisen',
    'Chainsaw Man',
  ];

  print('Original Title → Normalized ID');
  print('=' * 60);

  for (var title in testCases) {
    final normalized = _normalizeId(title);
    print('"$title" → "$normalized"');
  }

  print('\n' + '=' * 60);
  print('\n✅ Test completed!\n');

  // Test matching logic
  print('🔍 Testing Matching Logic\n');
  
  final wishlistIds = ['naruto_shippuden', 'one_piece', 'bleach'];
  final storyTitles = [
    'Naruto Shippuden',
    'One Piece',
    'Dragon Ball Z',
    'Bleach',
  ];

  print('Wishlist IDs: $wishlistIds');
  print('Story Titles: $storyTitles\n');

  final normalizedWishlist = wishlistIds.toSet();
  
  for (var title in storyTitles) {
    final normalized = _normalizeId(title);
    final titleMatch = wishlistIds.contains(title);
    final normalizedMatch = normalizedWishlist.contains(normalized);
    final shouldMatch = titleMatch || normalizedMatch;
    
    print('Story: "$title"');
    print('  Normalized: "$normalized"');
    print('  Title Match: $titleMatch');
    print('  Normalized Match: $normalizedMatch');
    print('  Result: ${shouldMatch ? "✅ MATCH" : "❌ NO MATCH"}\n');
  }
}

String _normalizeId(String text) {
  // Map Vietnamese characters to ASCII equivalents
  const vietnameseMap = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'đ': 'd',
  };

  String normalized = text.trim().toLowerCase();
  
  // Replace Vietnamese characters
  vietnameseMap.forEach((key, value) {
    normalized = normalized.replaceAll(key, value);
  });
  
  // Remove special characters and replace spaces with underscores
  normalized = normalized
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), '_');
  
  return normalized;
}
