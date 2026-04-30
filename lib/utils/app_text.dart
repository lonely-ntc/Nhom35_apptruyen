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

      /// EXPLORE
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
      "favorite_stories": "Truyện yêu thích",
      "no_favorite": "Chưa có truyện yêu thích",
      "add_favorite_hint": "Thêm truyện vào yêu thích để đọc sau",
      "no_reading": "Chưa có truyện đang đọc",
      "start_reading_hint": "Bắt đầu đọc truyện để theo dõi tiến độ",
      "app_name": "COMIC MANGA",
      "your_library": "Thư viện của bạn",

      /// PROFILE
      "exp": "Kinh nghiệm",
      "read": "Đã đọc",
      "history": "Lịch sử",
      "comment": "Bình luận",
      "change_password": "Đổi mật khẩu",
      "logout": "Đăng xuất",
      "logout_confirm": "Bạn có chắc muốn đăng xuất không?",
      "cancel": "Huỷ",

      /// SEARCH
      "search_empty": "Nhập để tìm truyện",
      "no_result": "Không tìm thấy truyện",

      /// STORY DETAIL
      "read_now": "Đọc ngay",
      "author": "Tác giả",
      "story_category": "Thể loại",
      "description": "Cốt truyện",
      "no_description": "Không có mô tả",
      "rate_story": "Đánh giá truyện này",
      "write_comment": "Viết bình luận...",
      "chapter_list": "Danh sách chương",

      /// ADMIN
      "manage_stories": "Quản lý truyện",
      "confirm_delete": "Xác nhận xóa",
      "delete_story_confirm": "Bạn có chắc muốn xóa truyện",

      /// NOTIFICATION
      "notifications": "Thông báo",
      "mark_all_read": "Đọc tất cả",
      "marked_all_read": "Đã đánh dấu tất cả là đã đọc",
      "no_notifications": "Không có thông báo",
      "notification_hint": "Bạn sẽ nhận được thông báo về\ntruyện mới và cập nhật ở đây",
      "delete": "Xóa",
      "deleted_notification": "Đã xóa thông báo",
      "just_now": "Vừa xong",
      "days_ago": "ngày trước",
      "hours_ago": "giờ trước",
      "minutes_ago": "phút trước",

      /// PURCHASE
      "free": "MIỄN PHÍ",
      "buy_story": "Mua truyện",
      "buy_now": "Mua ngay",
      "price": "Giá:",
      "you_will_receive": "Bạn sẽ nhận được +1000 EXP",

      /// SNACKBAR MESSAGES
      "password_changed_success": "Đổi mật khẩu thành công",
      "wrong_old_password": "Sai mật khẩu cũ",
      "error_occurred": "Có lỗi xảy ra",
      "rated_success": "Đánh giá thành công",
      "comment_sent": "Đã gửi bình luận",
      "added_to_wishlist": "Đã thêm vào yêu thích",
      "removed_from_wishlist": "Đã xóa khỏi yêu thích",
      "purchase_success": "Mua truyện thành công! +1000 EXP",
      "purchase_error": "Lỗi",
      "name_required": "Tên hiển thị không được để trống",
      "profile_updated": "Cập nhật thông tin thành công",
      "select_at_least_3": "Vui lòng chọn ít nhất 3 thể loại",
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

      /// EXPLORE
      "explore_title": "Explore",
      "all_story": "All stories",
      "trending": "Trending",
      "see_more": "See more",

      /// WISHLIST
      "wishlist_empty": "No stories",
      "reading": "Reading",
      "following": "Following",
      "search_hint": "Search story...",
      "chapter": "Chapter",
      "favorite_stories": "Favorite Stories",
      "no_favorite": "No favorite stories yet",
      "add_favorite_hint": "Add stories to favorites to read later",
      "no_reading": "No reading stories yet",
      "start_reading_hint": "Start reading stories to track progress",
      "app_name": "COMIC MANGA",
      "your_library": "Your Library",

      /// PROFILE
      "exp": "Experience",
      "read": "Read",
      "history": "History",
      "comment": "Comments",
      "change_password": "Change password",
      "logout": "Logout",
      "logout_confirm": "Are you sure you want to logout?",
      "cancel": "Cancel",

      /// SEARCH
      "search_empty": "Type to search",
      "no_result": "No results found",

      /// STORY DETAIL
      "read_now": "Read now",
      "author": "Author",
      "story_category": "Category",
      "description": "Description",
      "no_description": "No description",
      "rate_story": "Rate this story",
      "write_comment": "Write a comment...",
      "chapter_list": "Chapter list",

      /// ADMIN
      "manage_stories": "Manage Stories",
      "confirm_delete": "Confirm Delete",
      "delete_story_confirm": "Are you sure you want to delete story",

      /// NOTIFICATION
      "notifications": "Notifications",
      "mark_all_read": "Mark all read",
      "marked_all_read": "Marked all as read",
      "no_notifications": "No notifications",
      "notification_hint": "You will receive notifications about\nnew stories and updates here",
      "delete": "Delete",
      "deleted_notification": "Notification deleted",
      "just_now": "Just now",
      "days_ago": "days ago",
      "hours_ago": "hours ago",
      "minutes_ago": "minutes ago",

      /// PURCHASE
      "free": "FREE",
      "buy_story": "Buy Story",
      "buy_now": "Buy Now",
      "price": "Price:",
      "you_will_receive": "You will receive +1000 EXP",

      /// SNACKBAR MESSAGES
      "password_changed_success": "Password changed successfully",
      "wrong_old_password": "Wrong old password",
      "error_occurred": "An error occurred",
      "rated_success": "Rating successful",
      "comment_sent": "Comment sent",
      "added_to_wishlist": "Added to wishlist",
      "removed_from_wishlist": "Removed from wishlist",
      "purchase_success": "Purchase successful! +1000 EXP",
      "purchase_error": "Error",
      "name_required": "Display name is required",
      "profile_updated": "Profile updated successfully",
      "select_at_least_3": "Please select at least 3 categories",
    }
  };

  /// GET TEXT (SAFE + DEBUG)
  static String get(String key, String lang) {
    /// 1. lấy theo ngôn ngữ hiện tại
    if (data[lang] != null && data[lang]![key] != null) {
      return data[lang]![key]!;
    }

    /// 2. fallback về tiếng Việt
    if (data[defaultLang] != null && data[defaultLang]![key] != null) {
      return data[defaultLang]![key]!;
    }

    /// 3. debug nếu thiếu key
    print("❌ Missing key: $key");

    return key;
  }
}