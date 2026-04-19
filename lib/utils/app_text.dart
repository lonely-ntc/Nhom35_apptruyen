class AppText {
  static const String defaultLang = "vi";

  static Map<String, Map<String, String>> data = {
    "vi": {
      /// NAV
      "home": "Trang chủ",
      "explore": "Khám phá",
      "wishlist": "Yêu thích",
      "purchased": "Đã mua",
      "profile": "Tài khoản",

      /// SETTINGS
      "settings": "Cài đặt",
      "language": "Ngôn ngữ",
      "dark_mode": "Chế độ tối",
      "notification": "Thông báo",
      "about": "Giới thiệu",
      "privacy": "Chính sách bảo mật",
      "terms": "Điều khoản sử dụng",

      /// AUTH
      "login": "Đăng nhập",
      "register": "Đăng ký",

      /// HOME
      "popular": "Truyện phổ biến",
      "category": "Thể loại",
      "new_update": "Truyện mới cập nhật",
      "no_data": "Không có dữ liệu",

      /// ===== EXPLORE =====
      "explore_title": "Khám phá",
      "all_story": "Tất cả truyện",
      "trending": "Thịnh hành",
      "see_more": "Đọc thêm"
    },

    "en": {
      /// NAV
      "home": "Home",
      "explore": "Explore",
      "wishlist": "Wishlist",
      "purchased": "Purchased",
      "profile": "Profile",

      /// SETTINGS
      "settings": "Settings",
      "language": "Language",
      "dark_mode": "Dark mode",
      "notification": "Notification",
      "about": "About",
      "privacy": "Privacy Policy",
      "terms": "Terms of Service",

      /// AUTH
      "login": "Login",
      "register": "Register",

      /// HOME
      "popular": "Popular",
      "category": "Category",
      "new_update": "New stories",
      "no_data": "No data",

      /// ===== EN =====
      "explore_title": "Explore",
      "all_story": "All stories",
      "trending": "Trending",
      "see_more": "See more",
    }
  };

  /// 🔥 GET TEXT (SAFE + DEBUG)
  static String get(String key, String lang) {
    /// 1. lấy theo ngôn ngữ hiện tại
    if (data[lang] != null && data[lang]![key] != null) {
      return data[lang]![key]!;
    }

    /// 2. fallback về tiếng Việt
    if (data[defaultLang]![key] != null) {
      return data[defaultLang]![key]!;
    }

    /// 3. debug nếu thiếu key
    print("❌ Missing key: $key");

    return key;
  }
}