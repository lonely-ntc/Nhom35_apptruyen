# 📁 Cập nhật đường dẫn Database

## ✅ Đã hoàn thành

Database và images đã được di chuyển từ `assets/database/` ra ngoài thành `database/` ở root project.

## 🔄 Thay đổi

### Trước:
```
apptruyen/
├── assets/
│   └── database/
│       ├── truyen.db
│       └── images/
│           ├── bach_hop/
│           ├── dam_my/
│           └── ...
```

### Sau:
```
apptruyen/
├── database/              # ← Đã di chuyển ra ngoài
│   ├── truyen.db
│   └── images/
│       ├── bach_hop/
│       ├── dam_my/
│       └── ...
├── assets/
│   ├── avatars/
│   └── images/
```

## 📝 Files đã cập nhật

### 1. pubspec.yaml
```yaml
# Trước:
assets:
  - assets/database/truyen.db
  - assets/database/images/bach_hop/
  ...

# Sau:
assets:
  - database/truyen.db
  - database/images/bach_hop/
  ...
```

### 2. lib/services/database_service.dart
```dart
// Trước:
await rootBundle.load("assets/database/truyen.db");

// Sau:
await rootBundle.load("database/truyen.db");
```

### 3. lib/services/sqlite_service.dart
```dart
// Trước:
await rootBundle.load('assets/database/truyen.db');

// Sau:
await rootBundle.load('database/truyen.db');
```

### 4. lib/utils/image_helper.dart
```dart
// Trước:
final fullPath = "assets/database/$path";
return "assets/database/${candidates.first}";

// Sau:
final fullPath = "database/$path";
return "database/${candidates.first}";
```

### 5. lib/screens/admin/admin_edit_story_screen.dart
```dart
// Trước:
final targetPath = 'assets/database/images/$categoryFolder/$imageName.jpg';
final targetDir = Directory('assets/database/images/$categoryFolder');

// Sau:
final targetPath = 'database/images/$categoryFolder/$imageName.jpg';
final targetDir = Directory('database/images/$categoryFolder');
```

### 6. tools/migrate_db.dart
```dart
// Trước:
final dbFile = File('assets/database/truyen.db');

// Sau:
final dbFile = File('database/truyen.db');
```

### 7. HUONG_DAN_THEM_TRUYEN.md
```markdown
# Trước:
3. **Ảnh assets (có sẵn)**: `assets/database/images/...`

# Sau:
3. **Ảnh assets (có sẵn)**: `database/images/...`
```

## 🎯 Lợi ích

### 1. Tổ chức rõ ràng hơn
- ✅ Database và data riêng biệt với assets UI
- ✅ Dễ quản lý và backup
- ✅ Dễ dàng exclude khỏi git nếu cần

### 2. Đường dẫn ngắn gọn hơn
```dart
// Trước:
"assets/database/images/bach_hop/truyen.jpg"

// Sau:
"database/images/bach_hop/truyen.jpg"
```

### 3. Phù hợp với cấu trúc project
```
apptruyen/
├── database/          # Data layer
├── assets/            # UI assets
├── lib/               # Code
└── tools/             # Scripts
```

## 🔍 Kiểm tra

### Test đường dẫn database:
```dart
// lib/services/database_service.dart
ByteData data = await rootBundle.load("database/truyen.db");
```

### Test đường dẫn images:
```dart
// lib/utils/image_helper.dart
final fullPath = "database/$path";
// Ví dụ: "database/images/bach_hop/truyen.jpg"
```

### Test trong pubspec.yaml:
```yaml
assets:
  - database/truyen.db
  - database/images/bach_hop/
  - database/images/dam_my/
  # ... tất cả các thư mục images
```

## 🚀 Chạy app

```bash
# 1. Cập nhật dependencies
flutter pub get

# 2. Clean build
flutter clean

# 3. Chạy app
flutter run
```

## ⚠️ Lưu ý

### 1. Cấu trúc thư mục database/
Đảm bảo thư mục `database/` có cấu trúc:
```
database/
├── truyen.db
└── images/
    ├── bach_hop/
    ├── co_dai/
    ├── cung_dau/
    ├── dam_my/
    ├── di_gioi/
    ├── di_nang/
    ├── do_thi/
    ├── he_thong/
    ├── hien_dai/
    ├── huyen_huyen/
    ├── khac/
    ├── khoa_huyen/
    ├── kiem_hiep/
    ├── lich_su/
    ├── linh_di/
    ├── ngon_tinh/
    ├── nu_cuong/
    ├── quan_su/
    ├── quan_truong/
    ├── tien_hiep/
    ├── tieu_thuyet/
    ├── trinh_tham/
    ├── trong_sinh/
    ├── truyen_teen/
    ├── vong_du/
    ├── xuyen_khong/
    └── xuyen_nhanh/
```

### 2. Git ignore (nếu cần)
Nếu muốn exclude database khỏi git:
```gitignore
# .gitignore
database/truyen.db
database/images/
```

### 3. Backup
Nên backup thư mục `database/` thường xuyên:
```bash
# Backup
cp -r database/ database_backup_$(date +%Y%m%d)/

# Restore
cp -r database_backup_20240101/ database/
```

## 🐛 Troubleshooting

### Lỗi: Unable to load asset
```
Error: Unable to load asset: database/truyen.db
```

**Giải pháp:**
1. Kiểm tra file `database/truyen.db` có tồn tại không
2. Chạy `flutter clean && flutter pub get`
3. Restart app

### Lỗi: Image not found
```
Error: Unable to load asset: database/images/bach_hop/truyen.jpg
```

**Giải pháp:**
1. Kiểm tra thư mục `database/images/` có đầy đủ không
2. Kiểm tra tên file có đúng không (case-sensitive)
3. Kiểm tra pubspec.yaml đã khai báo đúng chưa

### Lỗi: pubspec.yaml
```
Error: Asset directory not found
```

**Giải pháp:**
1. Đảm bảo thư mục `database/` nằm ở root project
2. Kiểm tra indentation trong pubspec.yaml
3. Chạy `flutter pub get`

## ✅ Checklist

- [x] Di chuyển `assets/database/` → `database/`
- [x] Cập nhật pubspec.yaml
- [x] Cập nhật database_service.dart
- [x] Cập nhật sqlite_service.dart
- [x] Cập nhật image_helper.dart
- [x] Cập nhật admin_edit_story_screen.dart
- [x] Cập nhật migrate_db.dart
- [x] Cập nhật HUONG_DAN_THEM_TRUYEN.md
- [x] Test chạy app
- [x] Verify images load correctly
- [x] Verify database load correctly

## 📚 Tài liệu liên quan

- [Flutter Assets](https://docs.flutter.dev/development/ui/assets-and-images)
- [pubspec.yaml](https://dart.dev/tools/pub/pubspec)
- [AssetBundle](https://api.flutter.dev/flutter/services/AssetBundle-class.html)

---

**Cập nhật:** 2024
**Status:** ✅ Hoàn thành
