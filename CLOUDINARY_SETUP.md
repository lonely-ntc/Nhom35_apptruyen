# ☁️ Cloudinary Setup Guide

## 📋 Tổng quan

Cloudinary được tích hợp để upload và quản lý ảnh truyện. Khi admin thêm truyện mới:
- ✅ Ảnh được upload lên Cloudinary
- ✅ URL từ Cloudinary được lưu vào SQLite (cột `duong_dan_anh`)
- ✅ Nội dung truyện được lưu trực tiếp vào SQLite

## 🚀 Bước 1: Tạo tài khoản Cloudinary

### 1.1. Đăng ký miễn phí
1. Truy cập: https://cloudinary.com/users/register/free
2. Đăng ký với email hoặc Google
3. Xác nhận email

### 1.2. Lấy thông tin cấu hình
Sau khi đăng nhập, vào **Dashboard**:

```
Dashboard URL: https://console.cloudinary.com/console
```

Bạn sẽ thấy:
- **Cloud Name**: `dxyz123abc` (ví dụ)
- **API Key**: `123456789012345`
- **API Secret**: `abcdefghijklmnopqrstuvwxyz`

## 🔧 Bước 2: Tạo Upload Preset

### 2.1. Vào Settings
1. Click vào **Settings** (⚙️ icon) ở góc trên bên phải
2. Chọn tab **Upload**
3. Scroll xuống phần **Upload presets**

### 2.2. Tạo preset mới
1. Click **Add upload preset**
2. Điền thông tin:
   - **Preset name**: `story_images`
   - **Signing Mode**: **Unsigned** (quan trọng!)
   - **Folder**: `story_images` (tùy chọn)
   - **Access Mode**: **Public**
3. Click **Save**

### 2.3. Lưu ý
- ✅ **Signing Mode** phải là **Unsigned** để upload từ app
- ✅ **Preset name** sẽ dùng trong code

## 📝 Bước 3: Cấu hình trong code

### 3.1. Mở file `lib/services/cloudinary_service.dart`

Tìm dòng:
```dart
static const String _cloudName = 'YOUR_CLOUD_NAME';
static const String _uploadPreset = 'YOUR_UPLOAD_PRESET';
```

### 3.2. Thay thế bằng thông tin của bạn

```dart
static const String _cloudName = 'dxyz123abc'; // Cloud Name từ Dashboard
static const String _uploadPreset = 'story_images'; // Preset name vừa tạo
```

**Ví dụ:**
```dart
// File: lib/services/cloudinary_service.dart
class CloudinaryService {
  static final CloudinaryService instance = CloudinaryService._();
  CloudinaryService._();

  // 🔥 CLOUDINARY CONFIG
  static const String _cloudName = 'manga-cloud-2024'; // ← Thay đổi
  static const String _uploadPreset = 'story_images';  // ← Thay đổi
  
  // ... rest of code
}
```

## 🎯 Bước 4: Cài đặt dependencies

```bash
flutter pub get
```

Package `cloudinary_public` đã được thêm vào `pubspec.yaml`:
```yaml
dependencies:
  cloudinary_public: ^0.21.0
  http: ^1.2.0
```

## ✅ Bước 5: Test upload

### 5.1. Chạy app
```bash
flutter run
```

### 5.2. Test thêm truyện
1. Đăng nhập với tài khoản admin
2. Vào **Admin** > **Quản lý truyện**
3. Click **Thêm truyện mới**
4. Điền thông tin và chọn ảnh
5. Click **Thêm truyện**

### 5.3. Kiểm tra
- ✅ Ảnh được upload lên Cloudinary
- ✅ URL được lưu vào SQLite
- ✅ Ảnh hiển thị trong app

### 5.4. Xem ảnh trên Cloudinary
1. Vào Dashboard: https://console.cloudinary.com/console
2. Click **Media Library**
3. Xem ảnh trong folder `story_images/`

## 📊 Cấu trúc dữ liệu

### SQLite (truyen.db)
```sql
-- Bảng truyện
CREATE TABLE truyen (
  ten_truyen TEXT PRIMARY KEY,
  tac_gia TEXT,
  the_loai TEXT,
  mo_ta TEXT,
  trang_thai TEXT,
  so_chuong TEXT,
  is_free INTEGER DEFAULT 1,
  price REAL DEFAULT 0.0
);

-- Bảng ảnh (lưu URL Cloudinary)
CREATE TABLE anh_truyen (
  id INTEGER PRIMARY KEY,
  ten_truyen TEXT,
  the_loai TEXT,
  duong_dan_anh TEXT  -- ← Cloudinary URL ở đây
);
```

### Ví dụ URL Cloudinary
```
https://res.cloudinary.com/manga-cloud-2024/image/upload/v1234567890/story_images/bach_hop/truyen_abc_1234567890.jpg
```

## 🔄 Workflow

```
1. Admin chọn ảnh từ device
   ↓
2. Upload lên Cloudinary
   ├─ Folder: story_images/{category}/
   ├─ Public ID: {category}_{title}_{timestamp}
   └─ Format: jpg, png, webp
   ↓
3. Nhận URL từ Cloudinary
   ↓
4. Lưu vào SQLite
   ├─ Bảng truyen: thông tin truyện
   └─ Bảng anh_truyen: URL Cloudinary
   ↓
5. App hiển thị ảnh từ Cloudinary
```

## 🎨 Tính năng Cloudinary

### 1. Transformations
Tự động resize, crop, optimize ảnh:

```dart
// Trong CloudinaryService
final url = CloudinaryService.instance.getTransformedUrl(
  originalUrl,
  width: 600,
  height: 800,
  crop: 'fill',
  quality: 'auto',
);
```

Kết quả:
```
https://res.cloudinary.com/manga-cloud-2024/image/upload/w_600,h_800,c_fill,q_auto/v1234567890/story_images/truyen.jpg
```

### 2. Tổ chức theo thể loại
Ảnh được tự động tổ chức theo folder:
```
story_images/
├── bach_hop/
├── dam_my/
├── ngon_tinh/
└── ...
```

### 3. Tên file duy nhất
Format: `{category}_{title}_{timestamp}.jpg`

Ví dụ:
```
bach_hop_truyen_abc_1234567890.jpg
dam_my_chuyen_tinh_yeu_1234567891.jpg
```

## 💰 Giới hạn Free Plan

Cloudinary Free Plan:
- ✅ 25 GB storage
- ✅ 25 GB bandwidth/tháng
- ✅ Unlimited transformations
- ✅ 10,000 images

**Đủ cho:**
- ~25,000 ảnh (1MB/ảnh)
- ~25,000 lượt xem/tháng

## 🔒 Bảo mật

### Upload Preset (Unsigned)
- ✅ Không cần API Secret trong app
- ✅ An toàn cho mobile app
- ⚠️ Giới hạn upload size và format trong preset

### Cấu hình Preset
Trong Cloudinary Dashboard > Settings > Upload > Preset:
```
- Max file size: 10 MB
- Allowed formats: jpg, png, webp
- Folder: story_images
- Access mode: Public
```

## 🐛 Troubleshooting

### Lỗi: Upload failed
```
❌ Cloudinary upload error: Invalid credentials
```

**Giải pháp:**
1. Kiểm tra `_cloudName` đúng chưa
2. Kiểm tra `_uploadPreset` đúng chưa
3. Kiểm tra preset là **Unsigned**

### Lỗi: Preset not found
```
❌ Upload preset not found
```

**Giải pháp:**
1. Vào Cloudinary Dashboard
2. Settings > Upload > Upload presets
3. Tạo preset mới với tên `story_images`
4. Đảm bảo **Signing Mode** = **Unsigned**

### Lỗi: Network error
```
❌ Failed to upload: Network error
```

**Giải pháp:**
1. Kiểm tra internet connection
2. Kiểm tra firewall/proxy
3. Thử lại sau vài phút

### Ảnh không hiển thị
```
❌ Image not loading
```

**Giải pháp:**
1. Kiểm tra URL trong SQLite có đúng không
2. Mở URL trong browser để test
3. Kiểm tra ImageHelper có xử lý URL Cloudinary không

## 📚 Tài liệu thêm

- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Upload Presets](https://cloudinary.com/documentation/upload_presets)
- [Image Transformations](https://cloudinary.com/documentation/image_transformations)
- [Flutter Package](https://pub.dev/packages/cloudinary_public)

## 🎯 Checklist

- [ ] Tạo tài khoản Cloudinary
- [ ] Lấy Cloud Name
- [ ] Tạo Upload Preset (unsigned)
- [ ] Cập nhật `cloudinary_service.dart`
- [ ] Chạy `flutter pub get`
- [ ] Test upload ảnh
- [ ] Kiểm tra ảnh trên Cloudinary Dashboard
- [ ] Kiểm tra URL trong SQLite
- [ ] Verify ảnh hiển thị trong app

## 💡 Tips

1. **Optimize images trước khi upload**
   - Resize về 600x800px
   - Compress quality 85%
   - Đã được xử lý trong `image_picker`

2. **Sử dụng transformations**
   - Thumbnail: `w_200,h_300,c_fill`
   - Full size: `w_600,h_800,c_fill`
   - Auto quality: `q_auto`

3. **Backup URLs**
   - Export SQLite database thường xuyên
   - Backup Cloudinary account

4. **Monitor usage**
   - Vào Dashboard > Reports
   - Xem bandwidth và storage usage
   - Upgrade plan nếu cần

---

**Hoàn thành setup! 🎉**

Bây giờ khi admin thêm truyện mới:
1. Ảnh tự động upload lên Cloudinary
2. URL được lưu vào SQLite
3. App load ảnh từ Cloudinary
4. Nhanh, ổn định, và scalable!
