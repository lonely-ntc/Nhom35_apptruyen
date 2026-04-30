# 📚 App Truyện Flutter

Ứng dụng đọc truyện tranh với đầy đủ tính năng quản lý và trải nghiệm người dùng.

## 🚀 Tính năng chính

### Người dùng
- 📚 Đọc truyện với giao diện hiện đại
- 🔍 Tìm kiếm và lọc truyện theo thể loại, giá
- ❤️ Yêu thích và theo dõi truyện
- 💬 Bình luận và đánh giá
- 🛒 Mua truyện trả phí
- 🎨 Chế độ sáng/tối
- 🔔 Thông báo cập nhật truyện mới
- 📊 Hệ thống kinh nghiệm và cấp độ
- 👤 Quản lý tài khoản cá nhân

### Quản trị viên
- ➕ Thêm/sửa/xóa truyện
- 📖 Quản lý chương truyện
- 👥 Quản lý người dùng
- 📊 Thống kê và báo cáo

## 🛠️ Công nghệ

- **Framework:** Flutter 3.10+
- **Backend:** Firebase (Auth, Firestore, Storage)
- **Database:** SQLite (local cache)
- **State Management:** Provider
- **UI:** Material Design 3

## 📦 Cài đặt

### 1. Clone repository:
```bash
git clone <repository-url>
cd apptruyen
```

### 2. Cài đặt dependencies:
```bash
flutter pub get
```

### 3. Cấu hình Firebase:
- File `google-services.json` đã có sẵn trong `android/app/`
- Project ID: `manga-e245c`

### 4. Chạy ứng dụng:
```bash
flutter run
```

## 🏗️ Build

### Android APK:
```bash
flutter build apk --release
```

### Android App Bundle (Google Play):
```bash
flutter build appbundle --release
```

## 🗂️ Cấu trúc thư mục

```
lib/
├── models/          # Data models
│   ├── story_model.dart
│   └── experience_model.dart
├── screens/         # UI screens
│   ├── admin/      # Admin screens (quản lý truyện, users)
│   ├── auth/       # Authentication screens
│   └── home/       # User screens (đọc truyện, profile)
├── services/        # Business logic & API
│   ├── database_service.dart
│   ├── firebase_service.dart
│   ├── story_management_service.dart
│   └── user_service.dart
├── utils/           # Utilities & helpers
│   ├── app_colors.dart
│   ├── app_text.dart
│   └── image_helper.dart
└── widgets/         # Reusable widgets

assets/
├── avatars/         # User avatars
├── database/        # SQLite database
│   ├── truyen.db
│   └── images/     # Story images by category
└── images/          # App images
```

## 👤 Tài khoản mặc định

### Admin
- Email: `admin@gmail.com`
- Password: `admin123`

### Test User
- Tạo tài khoản mới qua màn hình đăng ký

## 📊 Database Schema

### SQLite (Local):
```sql
-- Bảng truyện
truyen (
  ten_truyen TEXT PRIMARY KEY,
  tac_gia TEXT,
  the_loai TEXT,
  mo_ta TEXT,
  trang_thai TEXT,
  so_chuong TEXT,
  is_free INTEGER DEFAULT 1,
  price REAL DEFAULT 0.0
)

-- Bảng chương
chuong (
  id INTEGER PRIMARY KEY,
  ten_truyen TEXT,
  ten_chuong TEXT,
  noi_dung TEXT,
  link TEXT
)

-- Bảng ảnh
anh_truyen (
  id INTEGER PRIMARY KEY,
  ten_truyen TEXT,
  the_loai TEXT,
  duong_dan_anh TEXT
)
```

### Firestore (Cloud):
```
users/
  {userId}/
    - email, name, avatar
    - level, experience, coins
    - wishlist/
    - purchased/
    - reading_progress/
    - comments/

stories/
  {storyId}/
    - comments/
    - ratings/
```

## 🎯 Tính năng chi tiết

### User Features:
- ✅ Đọc truyện offline (SQLite)
- ✅ Tìm kiếm và lọc theo thể loại
- ✅ Wishlist (yêu thích)
- ✅ Following (theo dõi)
- ✅ Reading progress (lưu tiến độ đọc)
- ✅ Comments và Ratings
- ✅ Mua truyện trả phí (coins system)
- ✅ Level và Experience system
- ✅ Profile management

### Admin Features:
- ✅ Quản lý truyện (CRUD)
- ✅ Quản lý chương
- ✅ Quản lý người dùng
- ✅ Thống kê dashboard
- ✅ Upload/Edit ảnh bìa

## 🔄 Migration & Tools

### Migrate database:
```bash
dart tools/migrate_db.dart
```

### Migrate to Firestore (optional):
```bash
dart tools/migrate_to_firestore.dart
```

## 🎨 Themes

App hỗ trợ 2 theme:
- 🌞 Light Mode
- 🌙 Dark Mode

Tự động theo hệ thống hoặc chuyển đổi thủ công trong Settings.

## 🌐 Ngôn ngữ

Hỗ trợ đa ngôn ngữ:
- 🇻🇳 Tiếng Việt
- 🇬🇧 English

## 📝 Ghi chú

- Database SQLite được tự động migrate khi khởi động app
- Hỗ trợ dark mode tự động theo hệ thống
- Tất cả ảnh được cache để tối ưu hiệu suất
- Offline-first: Đọc truyện không cần internet
- User data sync với Firebase Firestore

## 🐛 Troubleshooting

### App không chạy:
```bash
flutter clean
flutter pub get
flutter run
```

### Lỗi database:
```bash
# Xóa app khỏi emulator và cài lại
flutter clean
flutter run
```

### Emulator không khởi động:
```bash
flutter emulators
flutter emulators --launch <emulator_id>
```

## 🚀 Roadmap

### Phase 1 (Completed) ✅
- [x] Mobile app với SQLite
- [x] Admin screens trong app
- [x] Authentication với Firebase
- [x] CRUD operations
- [x] User experience system
- [x] Comments & Ratings

### Phase 2 (In Progress) 🚧
- [ ] Push notifications
- [ ] Advanced search
- [ ] Recommendation system
- [ ] Social features

### Phase 3 (Planned) 📋
- [ ] Payment integration
- [ ] Multi-language support
- [ ] Analytics dashboard
- [ ] Cloud backup

## 📞 Support

- Issues: [GitHub Issues](https://github.com/...)
- Email: support@manga.com

## 📄 License

MIT License

---

**Made with ❤️ using Flutter**
