# 📚 App Truyện - Ứng dụng đọc truyện Flutter

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.1-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase)
![Dart](https://img.shields.io/badge/Dart-3.10.1-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-Private-red)

**Ứng dụng đọc truyện đa thể loại với hệ thống quản lý nội dung và thanh toán tích hợp**

[Tính năng](#-tính-năng) • [Cài đặt](#-cài-đặt) • [Cấu trúc](#-cấu-trúc-project) • [Hướng dẫn](#-hướng-dẫn-sử-dụng)

</div>

---

## 📖 Giới thiệu

**App Truyện** là ứng dụng đọc truyện đa nền tảng được xây dựng bằng Flutter, tích hợp Firebase và hệ thống thanh toán. Ứng dụng hỗ trợ 25+ thể loại truyện với hơn 1000+ đầu truyện, cung cấp trải nghiệm đọc mượt mà và quản lý nội dung chuyên nghiệp.

### 🎯 Mục tiêu

- ✅ Cung cấp nền tảng đọc truyện miễn phí và trả phí
- ✅ Hệ thống quản lý nội dung cho admin
- ✅ Tích hợp thanh toán và nạp xu
- ✅ Hỗ trợ đa ngôn ngữ (Tiếng Việt, English)
- ✅ Trải nghiệm người dùng tối ưu với Dark/Light mode

---

## ✨ Tính năng

### 👤 Người dùng

#### 📚 Đọc truyện
- 🔍 Tìm kiếm và lọc theo 25+ thể loại
- 📖 Đọc truyện với giao diện tối ưu
- � Lưu tiến độ đọc tự động
- ⭐ Đánh giá và bình luận
- 🔖 Thêm vào danh sách yêu thích
- 📊 Xem lịch sử đọc

#### 💰 Hệ thống xu
- 💳 Nạp xu qua VietQR
- 🛒 Mua chương truyện trả phí
- 📜 Xem lịch sử giao dịch
- 🎁 Nhận xu thưởng từ sự kiện

#### 👥 Tài khoản
- � Đăng ký/Đăng nhập với Email + OTP
- 👤 Quản lý thông tin cá nhân
- 🎨 Chọn avatar từ 10+ mẫu
- 🌙 Chuyển đổi Dark/Light mode
- 🌐 Đổi ngôn ngữ (VI/EN)

### 🔧 Admin

#### 📝 Quản lý truyện
- ➕ Thêm/Sửa/Xóa truyện
- � Quản lý chương truyện
- 🖼️ Upload ảnh bìa qua Cloudinary
- 🏷️ Phân loại theo thể loại
- 💵 Đặt giá cho chương trả phí

#### 👥 Quản lý người dùng
- 📊 Xem danh sách user
- 🔒 Cấp/Thu hồi quyền admin
- 📈 Thống kê người dùng
- 🚫 Khóa/Mở khóa tài khoản

#### 💳 Quản lý nạp xu
- 📋 Xem danh sách yêu cầu nạp xu
- ✅ Duyệt/Từ chối yêu cầu
- 📧 Nhận email thông báo tự động
- 📊 Thống kê doanh thu

#### 📊 Thống kê
- 📈 Thống kê truyện phổ biến
- 👥 Thống kê người dùng
- 💰 Thống kê doanh thu
- 📊 Báo cáo tổng quan

---

## 🛠️ Công nghệ sử dụng

### Frontend
- **Flutter 3.10.1** - Framework đa nền tảng
- **Dart 3.10.1** - Ngôn ngữ lập trình
- **Provider** - State management
- **Cached Network Image** - Cache ảnh

### Backend & Database
- **Firebase Authentication** - Xác thực người dùng
- **Cloud Firestore** - Database NoSQL
- **SQLite** - Local database
- **Cloudinary** - Lưu trữ ảnh

### Services
- **EmailJS** - Gửi email thông báo
- **VietQR** - Tạo mã QR thanh toán
- **HTTP** - API calls

### Tools
- **Git** - Version control
- **Firebase CLI** - Deploy Firestore rules
- **Flutter Launcher Icons** - Tạo app icon

---

## � Cấu trúc Project

```
apptruyen/
├── lib/
│   ├── config/              # Cấu hình app
│   │   └── admin_config.dart
│   ├── data/                # Data layer
│   ├── models/              # Data models
│   │   ├── story.dart
│   │   ├── chapter.dart
│   │   └── user.dart
│   ├── screens/             # UI Screens
│   │   ├── auth/           # Đăng nhập/Đăng ký
│   │   ├── home/           # Màn hình chính
│   │   └── admin/          # Màn hình admin
│   ├── services/            # Business logic
│   │   ├── firebase_service.dart
│   │   ├── email_service.dart
│   │   ├── admin_management_service.dart
│   │   └── payment_service.dart
│   ├── utils/               # Utilities
│   │   ├── app_colors.dart
│   │   ├── app_text.dart
│   │   └── database_migration.dart
│   ├── widgets/             # Reusable widgets
│   └── main.dart            # Entry point
├── assets/                  # Assets
│   ├── images/             # Ảnh app
│   └── avatars/            # Avatar mẫu
├── database/                # SQLite database
│   ├── truyen.db
│   └── images/             # Ảnh truyện local
├── tools/                   # Scripts & tools
│   ├── migrate_db.dart
│   └── check_admin_firestore.dart
├── firestore.rules          # Firestore security rules
├── pubspec.yaml             # Dependencies
└── README.md                # File này
```

---

## � Cài đặt

### Yêu cầu

- Flutter SDK 3.10.1 trở lên
- Dart SDK 3.10.1 trở lên
- Android Studio / VS Code
- Firebase CLI (cho deploy rules)
- Git

### Bước 1: Clone project

```bash
git clone <repository-url>
cd apptruyen
```

### Bước 2: Cài đặt dependencies

```bash
flutter pub get
```

### Bước 3: Cấu hình Firebase

1. Tạo project trên [Firebase Console](https://console.firebase.google.com/)
2. Thêm app Android/iOS
3. Download `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)
4. Đặt vào thư mục tương ứng:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### Bước 4: Cấu hình EmailJS

1. Đăng ký tại [EmailJS](https://www.emailjs.com/)
2. Tạo Email Service và Template
3. Cập nhật trong `lib/services/email_service.dart`:

```dart
static const String _topupServiceId = 'YOUR_SERVICE_ID';
static const String _topupTemplateId = 'YOUR_TEMPLATE_ID';
static const String _topupPublicKey = 'YOUR_PUBLIC_KEY';
```

### Bước 5: Cấu hình Cloudinary

1. Đăng ký tại [Cloudinary](https://cloudinary.com/)
2. Cập nhật trong `lib/services/cloudinary_service.dart`:

```dart
static const String _cloudName = 'YOUR_CLOUD_NAME';
static const String _uploadPreset = 'YOUR_UPLOAD_PRESET';
```

### Bước 6: Deploy Firestore Rules

```
Cập nhật lên firestore rules từ file firestore.rules

```

### Bước 7: Chạy app

```bash
flutter run
```

---

## 🔐 Cấu hình Admin

### Thêm Super Admin

Mở file `lib/config/admin_config.dart`:

```dart
static const List<String> superAdminEmails = [
  'admin@gmail.com',     
];
```

### Cấp quyền admin cho user

**Cách 1: Firebase Console**
1. Vào Firestore → Collection `users`
2. Tìm user cần cấp quyền
3. Sửa field `isAdmin` = `true`

**Cách 2: Trong app**
1. Đăng nhập bằng super admin
2. Vào màn hình "Quản lý người dùng"
3. Toggle switch bên cạnh user

---

## 📧 Hệ thống Email

### Cấu hình EmailJS Template

**Template cho OTP:**
- Service ID: `service_ocbbgnb`
- Template ID: `template_n7a03nh`
- Variables: `{{to_email}}`, `{{user_name}}`, `{{otp_code}}`

**Template cho thông báo nạp xu:**
- Service ID: `service_ocbbgnb`
- Template ID: `template_x8vstnj`
- Variables: `{{to_email_admin}}`, `{{user_name}}`, `{{email}}`, `{{coin}}`, `{{transaction_id}}`

### Gửi email thông báo

Khi user nạp xu, email tự động gửi đến **TẤT CẢ admin có `isAdmin = true`** trong Firestore.

---

## 💳 Hệ thống thanh toán

### VietQR

App sử dụng VietQR API để tạo mã QR thanh toán:

```dart
final qrUrl = PaymentService().taoUrlVietQR(
  soTienVND: 100000,
  tenNguoiDung: 'Nguyen Van A',
  email: 'user@gmail.com',
  soXu: 100,
);
```

### Quy trình nạp xu

1. User chọn gói nạp xu
2. Hiển thị mã QR VietQR
3. User quét mã và chuyển khoản
4. User xác nhận đã thanh toán
5. Tạo request trong Firestore
6. Gửi email thông báo cho admin
7. Admin duyệt request
8. Xu được cộng vào tài khoản user

---

## 🎨 Themes & Localization

### Dark/Light Mode

```dart
// Toggle theme
ThemeService().toggleTheme();

// Check current theme
bool isDark = ThemeService().isDark;
```

### Đa ngôn ngữ

```dart
// Change language
LanguageService().setLanguage('vi'); // hoặc 'en'

// Get text
String text = AppText.get('key', lang);
```

---

---

## 📊 Database

### Firestore Collections

- **users** - Thông tin người dùng
- **stories** - Danh sách truyện
- **chapters** - Chương truyện (subcollection)
- **topup_requests** - Yêu cầu nạp xu
- **transactions** - Lịch sử giao dịch
- **notifications** - Thông báo

### SQLite (Local)

- **truyen** - Cache truyện offline
- **chuong** - Cache chương offline

---

## 🔒 Security

### Firestore Rules

- User chỉ đọc/ghi dữ liệu của mình
- Admin có quyền đọc/ghi tất cả
- Validate dữ liệu trước khi ghi
- Giới hạn thời gian truy cập (đến 2030)

### Authentication

- Email + OTP verification
- Password hashing tự động (Firebase)
- Session management

---

## 📱 Platforms

- ✅ Android
---

## 🐛 Troubleshooting

### Lỗi: `permission-denied`

→ Firestore Rules chưa được deploy
→ Chạy: `firebase deploy --only firestore:rules`

### Lỗi: Không gửi được email

→ Kiểm tra EmailJS Service ID, Template ID, Public Key
→ Kiểm tra EmailJS Dashboard

### Lỗi: Không hiển thị ảnh

→ Kiểm tra Cloudinary configuration
→ Kiểm tra internet connection

---

## � Tài liệu

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [EmailJS Documentation](https://www.emailjs.com/docs/)
- [Cloudinary Documentation](https://cloudinary.com/documentation)

### Tài liệu nội bộ

- `SIMPLE_ADMIN_EMAIL_GUIDE.md` - Hướng dẫn hệ thống email
- `FIRESTORE_RULES_CHANGES.md` - Chi tiết Firestore Rules
- `DEPLOY_CHECKLIST.md` - Checklist deploy
- `FINAL_ADMIN_EMAIL_SETUP.md` - Setup admin email

---

## � Team

- **Developer**: [NHOM 35]
- **Designer**: [NHOM 35]
- **Project Manager **: [NGUYEN THE CHUONG - PHONG NHAT HUY]

---

## 🎉 Changelog

### Version 1.0.0 (2024)

#### ✨ Features
- ✅ Hệ thống đọc truyện đa thể loại
- ✅ Tích hợp Firebase Authentication
- ✅ Hệ thống nạp xu qua VietQR
- ✅ Email thông báo tự động
- ✅ Admin panel quản lý nội dung
- ✅ Dark/Light mode
- ✅ Đa ngôn ngữ (VI/EN)

#### � Bug Fixes
- ✅ Fix lỗi permission-denied khi admin đọc topup_requests
- ✅ Fix lỗi không gửi được email cho admin
- ✅ Fix lỗi cache ảnh
- ✅ Tối ưu performance

#### � Improvements
- ✅ Cải thiện UI/UX
- ✅ Tối ưu database queries
- ✅ Giảm thời gian startup
- ✅ Cải thiện error handling

---

<div align="center">

**Made with ❤️ using Flutter**

⭐ Star this repo if you like it!

</div>
