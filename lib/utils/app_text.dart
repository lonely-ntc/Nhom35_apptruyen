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
      "see_all": "Xem tất cả",
      "free_stories": "Miễn phí",
      "paid_stories": "Có phí",
      "filter": "Lọc",

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

      /// PROFILE
      "exp": "Kinh nghiệm",
      "read": "Đã đọc",
      "history": "Lịch sử giao dịch",
      "comment": "Bình luận",
      "change_password": "Đổi mật khẩu",
      "logout": "Đăng xuất",
      "logout_confirm": "Bạn có chắc muốn đăng xuất không?",
      "cancel": "Huỷ",
      "my_comments": "Bình luận của tôi",
      "personal_info": "Thông tin cá nhân",
      "favorite_stories_title": "Truyện yêu thích",

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
      "comments": "Bình luận",
      "user": "Người dùng",
      "weeks_ago": "tuần trước",
      "enter_comment": "Nhập bình luận...",

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
      "notification_just_now": "Vừa xong",
      "notification_days_ago": "ngày trước",
      "hours_ago": "giờ trước",
      "notification_minutes_ago": "phút trước",

      /// PURCHASE
      "free": "MIỄN PHÍ",
      "buy_story": "Mua truyện",
      "buy_now": "Mua ngay",
      "price": "Giá:",
      "you_will_receive": "Bạn sẽ nhận được +1000 EXP",

      /// TRANSACTION HISTORY
      "transaction_history": "Lịch sử giao dịch",
      "all_transactions": "Tất cả giao dịch",
      "topup": "Nạp tiền",
      "topup_title": "Nạp xu",
      "current_balance": "Số dư hiện tại",
      "coins": "xu",
      "topup_times": "Lần nạp",
      "total_coins_added": "Tổng xu đã nạp",
      "coins_added": "Xu đã nạp",
      "coins_spent": "Xu đã chi",
      "purchases": "Lần mua",
      "topup_history": "Lịch sử nạp xu",
      "purchase_history": "Lịch sử mua truyện",
      "purchase_story": "Mua truyện",
      "story_name": "Tên truyện",
      "success": "Thành công",
      "transactions": "giao dịch",
      "no_transactions": "Chưa có giao dịch nào",
      "tap_topup_to_start": "Nhấn nút 'Nạp tiền' để bắt đầu",
      "topup_success": "Nạp xu thành công",
      "approved": "Đã duyệt",
      "amount": "Số tiền",
      "base_coins": "Xu cơ bản",
      "bonus_coins": "Xu thưởng",
      "bonus_label": "xu bonus",
      "today": "Hôm nay",
      "yesterday": "Hôm qua",
      "just_now": "Vừa xong",
      "minutes_ago": "phút trước",
      "days_ago": "ngày trước",
      "select_package": "Chọn gói nạp",
      "topup_guide": "Hướng dẫn nạp xu",
      "select_topup_package": "Chọn gói nạp xu phù hợp",
      "scan_to_pay": "Quét mã thanh toán",
      "payment_completed": "Đã thanh toán",
      "confirm_payment": "Xác nhận thanh toán",
      "payment_confirmation_message": "Bạn đã hoàn tất thanh toán chưa?\n\nYêu cầu nạp xu sẽ được gửi đến admin để duyệt.\nXu sẽ được cộng sau khi admin xác nhận.",
      "not_yet": "Chưa",
      "topup_request_sent": "✅ Yêu cầu nạp xu đã được gửi!\nVui lòng đợi admin duyệt.",
      "loading_qr": "Đang tải mã QR...",
      "cannot_load_qr": "Không thể tải mã QR",
      "received": "Nhận được",
      "gift": "Tặng",
      
      /// SEARCH
      "search_title": "Tìm kiếm truyện",
      "search_description": "Nhập tên truyện, tác giả hoặc thể loại",
      "searching": "Đang tìm kiếm...",
      "no_results": "Không tìm thấy kết quả",
      "try_different_keyword": "Thử tìm kiếm với từ khóa khác",
      "suggestions_for_you": "Gợi ý cho bạn",

      /// PURCHASED SCREEN
      "your_library": "Thư viện của bạn",
      "stories_purchased": "truyện đã mua",
      "no_purchased_stories": "Chưa mua truyện nào",
      "explore_and_buy": "Khám phá và mua truyện yêu thích\nđể bắt đầu đọc ngay!",
      "explore_stories": "Khám phá truyện",
      "purchased_badge": "ĐÃ MUA",
      "continue_reading": "Đọc tiếp",

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
      
      /// PERSONAL INFO
      "choose_avatar": "Chọn ảnh đại diện",
      "display_name": "Tên hiển thị",
      "gender": "Giới tính",
      "male": "Nam",
      "female": "Nữ",
      "other": "Khác",
      "save_changes": "Lưu thay đổi",
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
      "see_all": "See all",
      "free_stories": "Free",
      "paid_stories": "Paid",
      "filter": "Filter",

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

      /// PROFILE
      "exp": "Experience",
      "read": "Read",
      "history": "Transaction History",
      "comment": "Comments",
      "change_password": "Change password",
      "logout": "Logout",
      "logout_confirm": "Are you sure you want to logout?",
      "cancel": "Cancel",
      "my_comments": "My Comments",
      "personal_info": "Personal Information",
      "favorite_stories_title": "Favorite Stories",

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
      "comments": "Comments",
      "user": "User",
      "weeks_ago": "weeks ago",
      "enter_comment": "Enter comment...",

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
      "notification_just_now": "Just now",
      "notification_days_ago": "days ago",
      "hours_ago": "hours ago",
      "notification_minutes_ago": "minutes ago",

      /// PURCHASE
      "free": "FREE",
      "buy_story": "Buy Story",
      "buy_now": "Buy Now",
      "price": "Price:",
      "you_will_receive": "You will receive +1000 EXP",

      /// TRANSACTION HISTORY
      "transaction_history": "Transaction History",
      "all_transactions": "All Transactions",
      "topup": "Top Up",
      "topup_title": "Top Up",
      "current_balance": "Current Balance",
      "coins": "coins",
      "topup_times": "Top-ups",
      "total_coins_added": "Total Coins Added",
      "coins_added": "Coins Added",
      "coins_spent": "Coins Spent",
      "purchases": "Purchases",
      "topup_history": "Top-up History",
      "purchase_history": "Purchase History",
      "purchase_story": "Purchase Story",
      "story_name": "Story Name",
      "success": "Success",
      "transactions": "transactions",
      "no_transactions": "No transactions yet",
      "tap_topup_to_start": "Tap 'Top Up' button to start",
      "topup_success": "Top-up Successful",
      "approved": "Approved",
      "amount": "Amount",
      "base_coins": "Base Coins",
      "bonus_coins": "Bonus Coins",
      "bonus_label": "bonus coins",
      "today": "Today",
      "yesterday": "Yesterday",
      "just_now": "Just now",
      "minutes_ago": "minutes ago",
      "days_ago": "days ago",
      "select_package": "Select Package",
      "topup_guide": "Top-up Guide",
      "select_topup_package": "Select a suitable top-up package",
      "scan_to_pay": "Scan to Pay",
      "payment_completed": "Payment Completed",
      "confirm_payment": "Confirm Payment",
      "payment_confirmation_message": "Have you completed the payment?\n\nTop-up request will be sent to admin for approval.\nCoins will be added after admin confirmation.",
      "not_yet": "Not Yet",
      "topup_request_sent": "✅ Top-up request sent!\nPlease wait for admin approval.",
      "loading_qr": "Loading QR code...",
      "cannot_load_qr": "Cannot load QR code",
      "received": "Received",
      "gift": "Gift",
      
      /// SEARCH
      "search_title": "Search Stories",
      "search_description": "Enter story name, author or genre",
      "searching": "Searching...",
      "no_results": "No results found",
      "try_different_keyword": "Try searching with different keywords",
      "suggestions_for_you": "Suggestions for You",

      /// PURCHASED SCREEN
      "your_library": "Your Library",
      "stories_purchased": "stories purchased",
      "no_purchased_stories": "No purchased stories yet",
      "explore_and_buy": "Explore and buy your favorite stories\nto start reading now!",
      "explore_stories": "Explore Stories",
      "purchased_badge": "PURCHASED",
      "continue_reading": "Continue",

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
      
      /// PERSONAL INFO
      "choose_avatar": "Choose Avatar",
      "display_name": "Display Name",
      "gender": "Gender",
      "male": "Male",
      "female": "Female",
      "other": "Other",
      "save_changes": "Save Changes",
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