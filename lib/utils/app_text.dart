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
      "see_more": "Đọc thêm",

      /// WISHLIST
      "wishlist_empty": "Không có truyện",
      "reading": "Đang đọc",
      "following": "Truyện theo dõi",
      "search_hint": "Tìm truyện...",
      "chapter": "Chương",

      "exp": "Kinh nghiệm",
      "read": "Đã đọc",
      "history": "Lịch sử",
      "comment": "Bình luận",
      "change_password": "Đổi mật khẩu",
      "logout": "Đăng xuất",
      "logout_confirm": "Bạn có chắc muốn đăng xuất không?",
      "cancel": "Huỷ",

      "search_empty": "Nhập để tìm truyện",
      "no_result": "Không tìm thấy truyện",

      "read_now": "Đọc ngay",
      "author": "Tác giả",
      "category": "Thể loại",
      "description": "Cốt truyện",
      "no_description": "Không có mô tả",
      "rate_story": "Đánh giá truyện này",
      "write_comment": "Viết bình luận...",
      "chapter_list": "Danh sách chương",
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

      "wishlist_empty": "No stories",
      "reading": "Reading",
      "following": "Following",
      "search_hint": "Search story...",
      "chapter": "Chapter",

      "exp": "Experience",
      "read": "Read",
      "history": "History",
      "comment": "Comments",
      "change_password": "Change password",
      "logout": "Logout",
      "logout_confirm": "Are you sure you want to logout?",
      "cancel": "Cancel",

      "search_empty": "Type to search",
      "no_result": "No results found",

      "read_now": "Read now",
      "author": "Author",
      "category": "Category",
      "description": "Description",
      "no_description": "No description",
      "rate_story": "Rate this story",
      "write_comment": "Write a comment...",
      "chapter_list": "Chapter list",
    }
  };

  /// GET TEXT (SAFE + DEBUG)
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