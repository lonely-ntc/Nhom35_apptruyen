# 🌍 Hỗ trợ đa ngôn ngữ (Language Support)

## 📋 Tổng quan

Project đã được cập nhật để hỗ trợ đa ngôn ngữ (Tiếng Việt và Tiếng Anh) thông qua file `lib/utils/app_text.dart`.

## 🔧 Cách sử dụng

### 1. Thêm key mới vào app_text.dart

```dart
static Map<String, Map<String, String>> data = {
  "vi": {
    "your_key": "Văn bản tiếng Việt",
  },
  "en": {
    "your_key": "English text",
  }
};
```

### 2. Sử dụng trong code

```dart
import '../../utils/app_text.dart';
import '../../services/language_service.dart';

// Trong widget
final lang = context.watch<LanguageService>().lang;
Text(AppText.get("your_key", lang))
```

## 📝 Danh sách key đã thêm

### Navigation
- `home` - Trang chủ / Home
- `explore` - Khám phá / Explore
- `wishlist` - Yêu thích / Wishlist
- `purchased` - Đã mua / Purchased
- `profile` - Tài khoản / Profile

### Settings
- `settings` - Cài đặt / Settings
- `language` - Ngôn ngữ / Language
- `dark_mode` - Chế độ tối / Dark mode
- `notification` - Thông báo / Notification
- `about` - Giới thiệu / About
- `privacy` - Chính sách bảo mật / Privacy Policy
- `terms` - Điều khoản sử dụng / Terms of Service

### Auth
- `login` - Đăng nhập / Login
- `register` - Đăng ký / Register

### Home
- `popular` - Truyện phổ biến / Popular
- `category` - Thể loại / Category
- `new_update` - Truyện mới cập nhật / New stories
- `no_data` - Không có dữ liệu / No data

### Explore
- `explore_title` - Khám phá / Explore
- `all_story` - Tất cả truyện / All stories
- `trending` - Thịnh hành / Trending
- `see_more` - Đọc thêm / See more

### Wishlist (MỚI)
- `wishlist_empty` - Không có truyện / No stories
- `reading` - Đang đọc / Reading
- `following` - Truyện theo dõi / Following
- `search_hint` - Tìm truyện... / Search story...
- `chapter` - Chương / Chapter
- `favorite_stories` - Truyện yêu thích / Favorite Stories
- `no_favorite` - Chưa có truyện yêu thích / No favorite stories yet
- `add_favorite_hint` - Thêm truyện vào yêu thích để đọc sau / Add stories to favorites to read later
- `no_reading` - Chưa có truyện đang đọc / No reading stories yet
- `start_reading_hint` - Bắt đầu đọc truyện để theo dõi tiến độ / Start reading stories to track progress
- `app_name` - COMIC MANGA / COMIC MANGA
- `your_library` - Thư viện của bạn / Your Library

### Profile
- `exp` - Kinh nghiệm / Experience
- `read` - Đã đọc / Read
- `history` - Lịch sử / History
- `comment` - Bình luận / Comments
- `change_password` - Đổi mật khẩu / Change password
- `logout` - Đăng xuất / Logout
- `logout_confirm` - Bạn có chắc muốn đăng xuất không? / Are you sure you want to logout?
- `cancel` - Huỷ / Cancel

### Search
- `search_empty` - Nhập để tìm truyện / Type to search
- `no_result` - Không tìm thấy truyện / No results found

### Story Detail
- `read_now` - Đọc ngay / Read now
- `author` - Tác giả / Author
- `story_category` - Thể loại / Category
- `description` - Cốt truyện / Description
- `no_description` - Không có mô tả / No description
- `rate_story` - Đánh giá truyện này / Rate this story
- `write_comment` - Viết bình luận... / Write a comment...
- `chapter_list` - Danh sách chương / Chapter list

### Admin (MỚI)
- `manage_stories` - Quản lý truyện / Manage Stories
- `confirm_delete` - Xác nhận xóa / Confirm Delete
- `delete_story_confirm` - Bạn có chắc muốn xóa truyện / Are you sure you want to delete story

### Notification (MỚI)
- `notifications` - Thông báo / Notifications
- `mark_all_read` - Đọc tất cả / Mark all read
- `marked_all_read` - Đã đánh dấu tất cả là đã đọc / Marked all as read
- `no_notifications` - Không có thông báo / No notifications
- `notification_hint` - Bạn sẽ nhận được thông báo về truyện mới và cập nhật ở đây / You will receive notifications about new stories and updates here
- `delete` - Xóa / Delete
- `deleted_notification` - Đã xóa thông báo / Notification deleted
- `just_now` - Vừa xong / Just now
- `days_ago` - ngày trước / days ago
- `hours_ago` - giờ trước / hours ago
- `minutes_ago` - phút trước / minutes ago

## 📁 Files đã cập nhật

### 1. lib/utils/app_text.dart
- ✅ Thêm 15+ key mới cho wishlist, admin, và các phần khác
- ✅ Tổ chức lại theo sections rõ ràng
- ✅ Đầy đủ translation cho cả VI và EN

### 2. lib/screens/home/wishlist_screen.dart
- ✅ Import AppText và LanguageService
- ✅ Thay thế tất cả hardcoded text bằng AppText.get()
- ✅ Header, tabs, empty states đều hỗ trợ đa ngôn ngữ

### 3. lib/screens/home/profile_screen.dart
- ✅ Cập nhật "Truyện yêu thích" thành AppText.get("favorite_stories", lang)

### 4. lib/screens/admin/admin_story_screen.dart
- ✅ Import AppText và LanguageService
- ✅ Cập nhật title, delete dialog
- ✅ Hỗ trợ đa ngôn ngữ cho admin panel

### 5. lib/screens/home/notification_screen.dart (MỚI)
- ✅ Import AppText và LanguageService
- ✅ Cập nhật title "Thông báo"
- ✅ Cập nhật "Đọc tất cả", "Đã đánh dấu tất cả là đã đọc"
- ✅ Cập nhật empty state: "Không có thông báo"
- ✅ Cập nhật time format: "Vừa xong", "ngày trước", "giờ trước", "phút trước"
- ✅ Cập nhật delete messages: "Xóa", "Đã xóa thông báo"
- ✅ Tất cả snackbar messages đều hỗ trợ đa ngôn ngữ

## 🎯 Kết quả

- ✅ **0 warnings** sau khi cập nhật
- ✅ Tất cả text quan trọng đã được chuyển sang AppText
- ✅ Dễ dàng thêm ngôn ngữ mới trong tương lai
- ✅ Code sạch hơn, dễ maintain hơn

## 🚀 Cách thêm ngôn ngữ mới

1. Thêm key ngôn ngữ mới vào `app_text.dart`:
```dart
"ja": {
  "home": "ホーム",
  "explore": "探索",
  // ... thêm các key khác
}
```

2. Cập nhật `LanguageService` để hỗ trợ ngôn ngữ mới

3. Thêm option trong Settings screen

## 📌 Lưu ý

- Luôn thêm key cho cả VI và EN
- Sử dụng snake_case cho key names
- Group keys theo chức năng (nav, settings, home, etc.)
- Test cả 2 ngôn ngữ sau khi thêm key mới
