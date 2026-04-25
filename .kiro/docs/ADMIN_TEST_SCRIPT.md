# 🧪 ADMIN PANEL - TEST SCRIPT

## 📋 Checklist kiểm tra đầy đủ

### ✅ PREPARATION

- [ ] App đã build thành công
- [ ] Firebase đã config
- [ ] SQLite database có sẵn
- [ ] Có tài khoản admin@gmail.com

---

## 🔐 TEST 1: AUTHENTICATION

### Test Case 1.1: Login Admin
**Steps:**
1. Mở app
2. Tap "Đã có tài khoản?"
3. Nhập email: `admin@gmail.com`
4. Nhập password
5. Tap "Đăng nhập"

**Expected:**
- ✅ Chuyển đến Admin Dashboard (không phải Main Screen)
- ✅ Hiển thị welcome card với email admin

**Status:** [ ] Pass [ ] Fail

---

### Test Case 1.2: Login Regular User
**Steps:**
1. Logout admin
2. Login với user thường

**Expected:**
- ✅ Chuyển đến Main Screen (không phải Admin Dashboard)
- ✅ Không có quyền truy cập admin panel

**Status:** [ ] Pass [ ] Fail

---

## 📊 TEST 2: DASHBOARD

### Test Case 2.1: View Statistics
**Steps:**
1. Login admin
2. Xem Dashboard

**Expected:**
- ✅ Welcome card hiển thị đúng email
- ✅ Stat cards hiển thị số liệu:
  - Users: > 0
  - Stories: > 0
  - Comments: >= 0
- ✅ Management cards hiển thị đầy đủ

**Status:** [ ] Pass [ ] Fail

---

### Test Case 2.2: Pull to Refresh
**Steps:**
1. Ở Dashboard
2. Kéo xuống để refresh

**Expected:**
- ✅ Loading indicator hiển thị
- ✅ Stats được cập nhật
- ✅ Không có lỗi

**Status:** [ ] Pass [ ] Fail

---

### Test Case 2.3: Dark Mode
**Steps:**
1. Ở Dashboard
2. Vào Settings → Toggle Dark mode
3. Quay lại Dashboard

**Expected:**
- ✅ Background đổi màu tối
- ✅ Text đổi màu sáng
- ✅ Cards đổi màu phù hợp
- ✅ Gradient vẫn đẹp

**Status:** [ ] Pass [ ] Fail

---

## 📚 TEST 3: STORY MANAGEMENT

### Test Case 3.1: View Story List
**Steps:**
1. Dashboard → Tap "Quản lý truyện"

**Expected:**
- ✅ Danh sách truyện hiển thị
- ✅ **Ảnh truyện hiển thị chính xác** (QUAN TRỌNG!)
- ✅ Tên truyện, tác giả, thể loại đầy đủ
- ✅ Badge số chương hiển thị
- ✅ Badge trạng thái hiển thị

**Status:** [ ] Pass [ ] Fail

---

### Test Case 3.2: Image Loading
**Steps:**
1. Ở Story List
2. Scroll qua nhiều truyện
3. Quan sát ảnh load

**Expected:**
- ✅ Ảnh load async (không block UI)
- ✅ Loading indicator khi đang load
- ✅ Ảnh hiển thị đúng sau khi load
- ✅ Fallback icon nếu ảnh lỗi

**Status:** [ ] Pass [ ] Fail

---

### Test Case 3.3: Story Actions Menu
**Steps:**
1. Ở Story List
2. Tap menu (⋮) của một truyện
3. Xem các options

**Expected:**
- ✅ Menu hiển thị 3 options:
  - Xem chi tiết
  - Chỉnh sửa
  - Xóa
- ✅ Icon và text rõ ràng

**Status:** [ ] Pass [ ] Fail

---

### Test Case 3.4: View Story Detail
**Steps:**
1. Tap menu → "Xem chi tiết"

**Expected:**
- ✅ Toast message hiển thị
- ⚠️ (Chưa implement màn hình chi tiết)

**Status:** [ ] Pass [ ] Fail

---

### Test Case 3.5: Delete Story (Confirm Dialog)
**Steps:**
1. Tap menu → "Xóa"
2. Xem dialog

**Expected:**
- ✅ Dialog xác nhận hiển thị
- ✅ Có nút "Hủy" và "Xóa"
- ✅ Nút "Xóa" màu đỏ
- ✅ Tap "Hủy" → Dialog đóng

**Status:** [ ] Pass [ ] Fail

---

### Test Case 3.6: Empty State
**Steps:**
1. (Giả sử database trống)

**Expected:**
- ✅ Message "Chưa có truyện" hiển thị
- ✅ Không crash

**Status:** [ ] Pass [ ] Fail

---

## 👥 TEST 4: USER MANAGEMENT

### Test Case 4.1: View User List
**Steps:**
1. Dashboard → Tap "Quản lý người dùng"

**Expected:**
- ✅ Danh sách user hiển thị
- ✅ Search bar ở trên
- ✅ Admin users ở đầu (sorted)
- ✅ Current user có badge "Bạn"
- ✅ Admin có badge "ADMIN" màu đỏ
- ✅ User có badge "USER" màu xám

**Status:** [ ] Pass [ ] Fail

---

### Test Case 4.2: Search User
**Steps:**
1. Ở User List
2. Nhập email vào search bar
3. Xem kết quả filter

**Expected:**
- ✅ Danh sách filter realtime
- ✅ Chỉ hiển thị user match
- ✅ Xóa search → hiển thị lại tất cả

**Status:** [ ] Pass [ ] Fail

---

### Test Case 4.3: Grant Admin Permission
**Steps:**
1. Tìm user thường (không phải admin)
2. Tap nút "Cấp quyền"

**Expected:**
- ✅ Badge đổi từ "USER" → "ADMIN"
- ✅ Badge đổi màu xám → đỏ
- ✅ Nút đổi từ "Cấp quyền" → "Thu hồi"
- ✅ Toast message "Đã cấp quyền admin cho..."
- ✅ User được sort lên đầu

**Status:** [ ] Pass [ ] Fail

---

### Test Case 4.4: Revoke Admin Permission
**Steps:**
1. Tìm admin user (không phải mình)
2. Tap nút "Thu hồi"

**Expected:**
- ✅ Badge đổi từ "ADMIN" → "USER"
- ✅ Badge đổi màu đỏ → xám
- ✅ Nút đổi từ "Thu hồi" → "Cấp quyền"
- ✅ Toast message "Đã thu hồi quyền admin của..."
- ✅ User được sort xuống

**Status:** [ ] Pass [ ] Fail

---

### Test Case 4.5: Self-Revoke Protection
**Steps:**
1. Tìm current user (có badge "Bạn")
2. Tap nút "Thu hồi"

**Expected:**
- ✅ Toast error "Không thể thay đổi quyền của chính mình!"
- ✅ Quyền không bị thay đổi
- ✅ Badge vẫn là "ADMIN"

**Status:** [ ] Pass [ ] Fail

---

### Test Case 4.6: Realtime Update
**Steps:**
1. Mở app trên 2 devices
2. Device 1: Cấp quyền admin cho user
3. Device 2: Xem user list

**Expected:**
- ✅ Device 2 tự động cập nhật
- ✅ Badge user đổi realtime
- ✅ Không cần refresh

**Status:** [ ] Pass [ ] Fail

---

## 🎨 TEST 5: UI/UX

### Test Case 5.1: Dark Mode Consistency
**Steps:**
1. Toggle dark mode
2. Kiểm tra tất cả màn hình admin

**Expected:**
- ✅ Dashboard: Background, cards, text đúng màu
- ✅ Story List: Cards, images, badges đúng màu
- ✅ User List: Cards, avatars, badges đúng màu
- ✅ Không có text/icon bị mất (màu trùng background)

**Status:** [ ] Pass [ ] Fail

---

### Test Case 5.2: Loading States
**Steps:**
1. Kiểm tra loading ở:
   - Dashboard stats
   - Story list
   - User list
   - Image loading

**Expected:**
- ✅ CircularProgressIndicator hiển thị
- ✅ Không block UI
- ✅ Smooth transition khi load xong

**Status:** [ ] Pass [ ] Fail

---

### Test Case 5.3: Error Handling
**Steps:**
1. Tắt internet
2. Pull to refresh Dashboard
3. Xem error handling

**Expected:**
- ✅ Không crash
- ✅ Loading state kết thúc
- ✅ Hiển thị data cũ (nếu có)

**Status:** [ ] Pass [ ] Fail

---

### Test Case 5.4: Responsive Layout
**Steps:**
1. Test trên devices khác nhau:
   - Small phone
   - Large phone
   - Tablet

**Expected:**
- ✅ Layout không bị vỡ
- ✅ Text không bị cắt
- ✅ Images scale đúng
- ✅ Buttons accessible

**Status:** [ ] Pass [ ] Fail

---

## 🔄 TEST 6: NAVIGATION

### Test Case 6.1: Navigation Flow
**Steps:**
1. Dashboard → Story List → Back
2. Dashboard → User List → Back
3. Logout → Login

**Expected:**
- ✅ Navigation smooth
- ✅ Back button hoạt động
- ✅ State được preserve (nếu cần)
- ✅ Logout về Welcome Screen

**Status:** [ ] Pass [ ] Fail

---

### Test Case 6.2: Deep Link (nếu có)
**Steps:**
1. Mở link trực tiếp đến admin panel

**Expected:**
- ✅ Redirect đến login nếu chưa login
- ✅ Redirect đến main nếu không phải admin
- ✅ Hiển thị admin panel nếu là admin

**Status:** [ ] Pass [ ] Fail

---

## 🚀 TEST 7: PERFORMANCE

### Test Case 7.1: Load Time
**Steps:**
1. Đo thời gian load:
   - Dashboard stats
   - Story list (100+ items)
   - User list (10+ items)

**Expected:**
- ✅ Dashboard: < 2s
- ✅ Story list: < 3s
- ✅ User list: < 1s (realtime)

**Status:** [ ] Pass [ ] Fail

---

### Test Case 7.2: Memory Usage
**Steps:**
1. Mở admin panel
2. Navigate qua tất cả màn hình
3. Kiểm tra memory

**Expected:**
- ✅ Không memory leak
- ✅ Images được dispose đúng
- ✅ Streams được close đúng

**Status:** [ ] Pass [ ] Fail

---

### Test Case 7.3: Scroll Performance
**Steps:**
1. Scroll nhanh qua story list (100+ items)
2. Scroll nhanh qua user list

**Expected:**
- ✅ Smooth 60fps
- ✅ Images load async
- ✅ Không lag/stutter

**Status:** [ ] Pass [ ] Fail

---

## 📱 TEST 8: EDGE CASES

### Test Case 8.1: Empty Database
**Steps:**
1. Database không có truyện

**Expected:**
- ✅ Story list: "Chưa có truyện"
- ✅ Dashboard stats: 0
- ✅ Không crash

**Status:** [ ] Pass [ ] Fail

---

### Test Case 8.2: No Internet
**Steps:**
1. Tắt internet
2. Mở admin panel

**Expected:**
- ✅ Story list: Load từ SQLite (offline)
- ✅ User list: Không load (cần Firebase)
- ✅ Dashboard: Partial data
- ✅ Không crash

**Status:** [ ] Pass [ ] Fail

---

### Test Case 8.3: Long Text
**Steps:**
1. Truyện có tên rất dài
2. User có email rất dài

**Expected:**
- ✅ Text được ellipsis (...)
- ✅ Layout không vỡ
- ✅ Vẫn readable

**Status:** [ ] Pass [ ] Fail

---

### Test Case 8.4: Special Characters
**Steps:**
1. Truyện có tên với ký tự đặc biệt
2. Search với ký tự đặc biệt

**Expected:**
- ✅ Hiển thị đúng
- ✅ Search hoạt động
- ✅ Không crash

**Status:** [ ] Pass [ ] Fail

---

## 📊 TEST SUMMARY

### Overall Results

| Category | Total | Pass | Fail | Skip |
|----------|-------|------|------|------|
| Authentication | 2 | | | |
| Dashboard | 3 | | | |
| Story Management | 6 | | | |
| User Management | 6 | | | |
| UI/UX | 4 | | | |
| Navigation | 2 | | | |
| Performance | 3 | | | |
| Edge Cases | 4 | | | |
| **TOTAL** | **30** | | | |

### Critical Issues Found
1. 
2. 
3. 

### Minor Issues Found
1. 
2. 
3. 

### Recommendations
1. 
2. 
3. 

---

## ✅ SIGN OFF

**Tester:** ___________________  
**Date:** ___________________  
**Version:** 1.0.0  
**Status:** [ ] Approved [ ] Rejected  

**Notes:**
```
(Ghi chú thêm ở đây)
```

---

**Last Updated**: 2026-04-23  
**Test Environment**: Flutter 3.10.1, Android/iOS
