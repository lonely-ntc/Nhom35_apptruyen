# Hướng Dẫn Thêm Truyện Mới

## Tổng Quan

Tính năng thêm truyện mới đã được cập nhật để tự động:
- ✅ Lưu thông tin truyện vào SQLite database
- ✅ Lưu hình ảnh vào thư mục documents của app (có thể ghi được)
- ✅ Tự động phân loại ảnh theo thể loại
- ✅ Hỗ trợ cả ảnh từ assets và ảnh mới thêm

## Cách Sử Dụng

### 1. Truy Cập Màn Hình Thêm Truyện

- Vào màn hình **Quản lý truyện** (Admin Story Screen)
- Nhấn nút **+** ở góc trên bên phải
- Màn hình thêm truyện sẽ hiển thị

### 2. Điền Thông Tin Truyện

#### Thông tin bắt buộc (*)
- **Tên truyện**: Nhập tên truyện (bắt buộc)
- **Tác giả**: Nhập tên tác giả (bắt buộc)
- **Thể loại**: Chọn ít nhất 1 thể loại (bắt buộc)
  - Có thể chọn nhiều thể loại
  - Thể loại đầu tiên sẽ được dùng để phân loại ảnh
- **Trạng thái**: Chọn trạng thái (Đang ra / Hoàn thành / Tạm dừng)
- **Ảnh truyện**: Chọn ảnh từ thiết bị (bắt buộc)

#### Thông tin tùy chọn
- **Mô tả**: Nhập mô tả chi tiết về truyện
- **Giá truyện**: 
  - Mặc định: Miễn phí
  - Có thể chuyển sang truyện trả phí và nhập giá

### 3. Chọn Ảnh Truyện

- Nhấn vào khung "Nhấn để chọn ảnh"
- Chọn ảnh từ thư viện ảnh của thiết bị
- Ảnh sẽ được hiển thị preview
- Có thể xóa và chọn lại ảnh khác

**Khuyến nghị kích thước ảnh**: 600x800px

### 4. Lưu Truyện

- Nhấn nút **"Thêm truyện"**
- Hệ thống sẽ:
  1. Validate thông tin
  2. Lưu ảnh vào thư mục documents
  3. Lưu thông tin vào database
  4. Gửi thông báo cho người dùng
  5. Quay lại màn hình danh sách

## Cơ Chế Lưu Trữ

### Lưu Ảnh

Ảnh được lưu vào thư mục documents của app theo cấu trúc:
```
<app_documents>/story_images/<the_loai>/<ten_truyen>.jpg
```

Ví dụ:
- Truyện "Chuyển Sinh Thành Nữ Vương" thuộc thể loại "Bach Hop"
- Ảnh sẽ được lưu tại: `story_images/bach_hop/chuyen_sinh_thanh_nu_vuong.jpg`

### Normalize Tên File

Tên file ảnh được chuẩn hóa:
- Chuyển về chữ thường
- Bỏ dấu tiếng Việt
- Thay khoảng trắng bằng dấu gạch dưới
- Loại bỏ ký tự đặc biệt

Ví dụ:
- "Chuyển Sinh Thành Nữ Vương" → `chuyen_sinh_thanh_nu_vuong`
- "Đế Tướng Lương Khuynh Quốc" → `de_tuong_luong_khuynh_quoc`

### Lưu Database

Thông tin được lưu vào 2 bảng:

**Bảng `truyen`:**
- ten_truyen
- tac_gia
- the_loai
- trang_thai
- so_chuong (mặc định: "0")
- mo_ta
- is_free (1 = miễn phí, 0 = trả phí)
- price (giá truyện)

**Bảng `anh_truyen`:**
- ten_truyen
- the_loai
- duong_dan_anh (đường dẫn file://)

## Hiển Thị Ảnh

Hệ thống hỗ trợ 3 loại đường dẫn ảnh:

1. **Ảnh online**: `http://` hoặc `https://`
   - Sử dụng NetworkImage

2. **Ảnh local (mới thêm)**: `file://`
   - Sử dụng FileImage
   - Ảnh được lưu trong documents

3. **Ảnh assets (có sẵn)**: `database/images/...`
   - Sử dụng AssetImage
   - Ảnh có sẵn trong project

## Thể Loại Hỗ Trợ

Danh sách thể loại được định nghĩa trong `lib/data/category_data.dart`:

- Bach Hop
- Cổ Đại
- Cung Đấu
- Đam Mỹ
- Di Giới
- Di Năng
- Đô Thị
- Hệ Thống
- Hiện Đại
- Huyền Huyễn
- Khác
- Khoa Huyễn
- Kiếm Hiệp
- Lịch Sử
- Linh Dị
- Ngôn Tình
- Nữ Cường
- Quân Sự
- Quan Trường
- Tiên Hiệp
- Tiểu Thuyết
- Trinh Thám
- Trọng Sinh
- Truyện Teen
- Vong Du
- Xuyên Không
- Xuyên Nhanh

## Lưu Ý Quan Trọng

### ✅ Ưu Điểm
- Không cần restart app sau khi thêm truyện
- Ảnh được lưu an toàn trong documents
- Hỗ trợ nhiều thể loại cho một truyện
- Tự động gửi thông báo cho người dùng

### ⚠️ Lưu Ý
- Ảnh mới thêm chỉ tồn tại trên thiết bị hiện tại
- Nếu xóa app, ảnh sẽ bị mất
- Nên backup database và ảnh định kỳ
- Thể loại đầu tiên được chọn sẽ quyết định thư mục lưu ảnh

### 🔧 Xử Lý Lỗi
- Nếu không chọn ảnh → Hiển thị cảnh báo
- Nếu không chọn thể loại → Hiển thị cảnh báo
- Nếu lưu thất bại → Hiển thị thông báo lỗi
- Ảnh bị lỗi → Hiển thị icon broken_image

## Cập Nhật Kỹ Thuật

### Files Đã Sửa

1. **lib/screens/admin/admin_add_story_screen.dart**
   - Thêm import `path_provider`
   - Sửa logic lưu ảnh vào documents
   - Lưu đường dẫn `file://` vào database

2. **lib/utils/image_helper.dart**
   - Thêm hỗ trợ đường dẫn `file://`
   - Thêm method `isLocalFile()`
   - Thêm method `getImageProvider()` để tự động chọn ImageProvider phù hợp

3. **lib/screens/admin/admin_story_screen.dart**
   - Cập nhật sử dụng `getImageProvider()`

4. **lib/screens/admin/admin_story_detail_screen.dart**
   - Cập nhật sử dụng `getImageProvider()`

5. **pubspec.yaml**
   - Thêm dependency `path_provider: ^2.1.1`

### Cách Hoạt Động

```dart
// 1. Lấy thư mục documents
final appDir = await getApplicationDocumentsDirectory();

// 2. Tạo thư mục theo thể loại
final targetDir = Directory('${appDir.path}/story_images/$categoryFolder');
await targetDir.create(recursive: true);

// 3. Copy ảnh vào documents
final targetPath = '${targetDir.path}/$imageName.jpg';
await selectedImage.copy(targetPath);

// 4. Lưu đường dẫn file:// vào database
final imagePath = 'file://$targetPath';
```

## Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra log console để xem lỗi chi tiết
2. Đảm bảo đã cấp quyền truy cập ảnh cho app
3. Kiểm tra dung lượng lưu trữ còn trống
4. Thử restart app nếu ảnh không hiển thị

## Tính Năng Tương Lai

- [ ] Đồng bộ ảnh lên cloud storage
- [ ] Nén ảnh tự động để tiết kiệm dung lượng
- [ ] Thêm nhiều ảnh cho một truyện
- [ ] Import truyện từ file Excel/CSV
- [ ] Backup/Restore database và ảnh
