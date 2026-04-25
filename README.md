# Comic Manga - Flutter App

Ứng dụng đọc truyện tranh với đầy đủ tính năng quản lý và trải nghiệm người dùng.

## 🚀 Tính năng chính

### Người dùng
- 📚 Đọc truyện với giao diện hiện đại
- 🔍 Tìm kiếm và lọc truyện theo thể loại, giá
- ❤️ Yêu thích và theo dõi truyện
- � Bình luận và đánh giá
- 🛒 Mua truyện trả phí
- 🎨 Chế độ sáng/tối
- 🤖 Trợ lý AI chatbot
- 🔔 Thông báo cập nhật truyện mới
- 📊 Hệ thống kinh nghiệm và cấp độ
- 👤 Quản lý tài khoản cá nhân

### Quản trị viên
- ➕ Thêm/sửa/xóa truyện
- 📖 Quản lý chương truyện
- 👥 Quản lý người dùng
- 📊 Thống kê và báo cáo

## 🛠️ Công nghệ

- **Framework:** Flutter 3.x
- **Backend:** Firebase (Auth, Firestore, Storage)
- **Database:** SQLite (local cache)
- **State Management:** Provider
- **UI:** Material Design 3

## � Cài đặt

1. Clone repository:
```bash
git clone <repository-url>
cd apptruyen
```

2. Cài đặt dependencies:
```bash
flutter pub get
```

3. Cấu hình Firebase:
   - Thêm `google-services.json` vào `android/app/`

4. Chạy ứng dụng:
```bash
flutter run
```

## � Build

### Android
```bash
flutter build apk --release
```

## 🗂️ Cấu trúc thư mục

```
lib/
├── models/          # Data models
├── screens/         # UI screens
│   ├── admin/      # Admin screens
│   ├── auth/       # Authentication screens
│   └── home/       # User screens
├── services/        # Business logic & API
├── utils/           # Utilities & helpers
└── widgets/         # Reusable widgets

assets/
├── avatars/         # User avatars
├── database/        # SQLite database
├── fonts/           # Custom fonts
└── images/          # App images
```

## � Tài khoản mặc định

### Admin
- Email: `admin@gmail.com`
- Password: `admin123`


## 📝 Ghi chú

- Database SQLite được tự động migrate khi khởi động app
- Hỗ trợ dark mode tự động theo hệ thống
- Tất cả ảnh được cache để tối ưu hiệu suất



