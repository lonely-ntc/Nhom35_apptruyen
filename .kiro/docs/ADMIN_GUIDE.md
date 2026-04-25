# 📚 HƯỚNG DẪN SỬ DỤNG ADMIN PANEL

## 🔐 Đăng nhập Admin

### Super Admin Account:
```
Email: admin@gmail.com
Password: (mật khẩu bạn đã đăng ký)
```

**Lưu ý**: Chỉ tài khoản `admin@gmail.com` mới có quyền cấp/thu hồi admin cho user khác.

---

## 📊 Admin Dashboard

### Thống kê hiển thị:
- **Người dùng**: Tổng số user đã đăng ký
- **Truyện**: Tổng số truyện trong database
- **Bình luận**: Số lượng comment (estimate từ 10 truyện đầu)
- **Đánh giá**: Placeholder (chưa implement)

### Làm mới dữ liệu:
- Kéo xuống (pull to refresh) để cập nhật thống kê

---

## 👥 Quản lý Người dùng

### Tìm kiếm:
1. Nhập email vào search bar
2. Danh sách tự động filter

### Phân quyền Admin:
1. Tìm user cần cấp quyền
2. Tap nút **"Cấp quyền"** (màu xanh)
3. User sẽ có badge **ADMIN** màu đỏ
4. Để thu hồi, tap **"Thu hồi"** (màu cam)

### Lưu ý:
- ⚠️ Không thể tự thu hồi quyền của chính mình
- ✅ Admin được sort lên đầu danh sách
- ✅ User hiện tại có badge **"Bạn"**

---

## 📚 Quản lý Truyện

### Xem danh sách:
- Hiển thị tất cả truyện với:
  - Ảnh bìa
  - Tên truyện
  - Tác giả
  - Thể loại
  - Số chương
  - Trạng thái (Hoàn thành/Đang ra)

### Actions (Menu 3 chấm):

#### 1. Xem chi tiết
- Xem thông tin đầy đủ của truyện
- *Hiện tại: Chỉ hiển thị toast*

#### 2. Chỉnh sửa
- Sửa thông tin truyện
- *Hiện tại: Đang phát triển*

#### 3. Xóa
- Xóa truyện khỏi database
- Có dialog xác nhận
- *Hiện tại: Đang phát triển*

---

## 🎨 Giao diện

### Dark Mode:
- Admin panel tự động theo theme của app
- Chuyển đổi trong Settings

### Màu sắc:
- 🔵 **Xanh**: User, Primary actions
- 🟠 **Cam**: Stories, Warning
- 🔴 **Đỏ**: Admin, Delete
- 🟢 **Xanh lá**: Success, Comments

---

## 🔧 Xử lý lỗi

### Ảnh không hiển thị:
- Hệ thống tự động fallback về icon placeholder
- Kiểm tra path ảnh trong database

### Không load được dữ liệu:
1. Kiểm tra kết nối internet
2. Kiểm tra Firebase config
3. Pull to refresh để thử lại

### Không cấp được quyền admin:
- Đảm bảo đang login bằng super admin account
- Không thể cấp quyền cho chính mình

---

## 📱 Workflow Admin

### Quy trình quản lý user:
```
1. Login admin → Dashboard
2. Tap "Quản lý người dùng"
3. Search user (nếu cần)
4. Cấp/Thu hồi quyền
5. Xác nhận bằng toast message
```

### Quy trình quản lý truyện:
```
1. Login admin → Dashboard
2. Tap "Quản lý truyện"
3. Xem danh sách
4. Tap menu (⋮) → Chọn action
5. Xác nhận (nếu là delete)
```

---

## 🚀 Tính năng sắp có

### Quản lý truyện:
- [ ] Thêm truyện mới
- [ ] Upload ảnh bìa
- [ ] Chỉnh sửa thông tin
- [ ] Xóa truyện
- [ ] Quản lý chương

### Quản lý user:
- [ ] Xem chi tiết user
- [ ] Ban/Unban
- [ ] Reset password
- [ ] Xem lịch sử hoạt động

### Dashboard:
- [ ] Chart thống kê
- [ ] Top stories
- [ ] Recent activities
- [ ] Export data

---

## 💡 Tips & Tricks

### 1. Tìm kiếm nhanh:
- Gõ một phần email để filter
- Không cần gõ đầy đủ

### 2. Refresh dữ liệu:
- Pull to refresh ở Dashboard
- Dữ liệu user tự động realtime

### 3. Kiểm tra quyền:
- Badge "Bạn" = current user
- Badge "ADMIN" màu đỏ = có quyền admin

### 4. Dark mode:
- Tất cả màn hình admin support dark mode
- Chuyển đổi trong Settings → Dark mode

---

## ⚠️ Lưu ý quan trọng

### Bảo mật:
- ✅ Chỉ admin mới vào được admin panel
- ✅ Chỉ super admin mới cấp quyền
- ✅ Không thể tự thu hồi quyền

### Dữ liệu:
- ⚠️ Xóa truyện sẽ không thể khôi phục
- ⚠️ Thu hồi quyền admin ngay lập tức
- ✅ Tất cả thay đổi được sync realtime

### Performance:
- 📊 Thống kê comment chỉ đếm 10 truyện đầu
- 🔄 Pull to refresh để cập nhật
- 📱 Pagination sẽ được thêm sau

---

## 🆘 Troubleshooting

### Lỗi: "Không thể thay đổi quyền của chính mình"
- **Nguyên nhân**: Đang cố tự thu hồi quyền admin
- **Giải pháp**: Dùng tài khoản super admin khác

### Lỗi: Ảnh không hiển thị
- **Nguyên nhân**: Path ảnh trong DB không khớp
- **Giải pháp**: Hệ thống tự fallback, không ảnh hưởng chức năng

### Lỗi: Không load được thống kê
- **Nguyên nhân**: Lỗi kết nối Firebase/SQLite
- **Giải pháp**: 
  1. Kiểm tra internet
  2. Pull to refresh
  3. Restart app

---

## 📞 Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra console log (debug mode)
2. Kiểm tra Firebase console
3. Kiểm tra SQLite database

---

**Cập nhật lần cuối**: 2026-04-23  
**Version**: 1.0.0
