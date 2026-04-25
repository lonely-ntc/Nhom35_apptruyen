# 🏗️ ADMIN PANEL ARCHITECTURE

## 📐 System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    ADMIN PANEL                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         LOGIN (admin@gmail.com)                 │   │
│  └──────────────────┬──────────────────────────────┘   │
│                     │                                   │
│                     ▼                                   │
│  ┌─────────────────────────────────────────────────┐   │
│  │           ADMIN DASHBOARD                       │   │
│  │  ┌─────────────────────────────────────────┐   │   │
│  │  │  Welcome Card (Gradient)                │   │   │
│  │  │  - Admin email                          │   │   │
│  │  │  - Logout button                        │   │   │
│  │  └─────────────────────────────────────────┘   │   │
│  │                                                 │   │
│  │  ┌─────────────────────────────────────────┐   │   │
│  │  │  Statistics (Realtime)                  │   │   │
│  │  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐  │   │   │
│  │  │  │Users │ │Stories│ │Comments│ │Ratings│  │   │   │
│  │  │  │  15  │ │  250  │ │  100+  │ │ N/A  │  │   │   │
│  │  │  └──────┘ └──────┘ └──────┘ └──────┘  │   │   │
│  │  └─────────────────────────────────────────┘   │   │
│  │                                                 │   │
│  │  ┌─────────────────────────────────────────┐   │   │
│  │  │  Management                             │   │   │
│  │  │  ┌─────────────────────────────────┐   │   │   │
│  │  │  │ 👥 Quản lý người dùng          │───┼───┼───┐
│  │  │  └─────────────────────────────────┘   │   │   │
│  │  │  ┌─────────────────────────────────┐   │   │   │
│  │  │  │ 📚 Quản lý truyện              │───┼───┼───┐
│  │  │  └─────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
│                     │                     │             │
│                     │                     │             │
│         ┌───────────┘                     └──────────┐  │
│         ▼                                            ▼  │
│  ┌──────────────────┐                    ┌─────────────────┐
│  │  USER MANAGEMENT │                    │ STORY MANAGEMENT│
│  ├──────────────────┤                    ├─────────────────┤
│  │                  │                    │                 │
│  │ [🔍 Search Bar]  │                    │ [+ Add Story]   │
│  │                  │                    │                 │
│  │ ┌──────────────┐ │                    │ ┌─────────────┐ │
│  │ │ [👤] Admin   │ │                    │ │[IMG] Story 1│ │
│  │ │ email@...    │ │                    │ │ Title       │ │
│  │ │ [ADMIN][Bạn] │ │                    │ │ Author      │ │
│  │ │   [Thu hồi]  │ │                    │ │ [50ch][✓]  │ │
│  │ └──────────────┘ │                    │ │        [⋮]  │ │
│  │                  │                    │ └─────────────┘ │
│  │ ┌──────────────┐ │                    │                 │
│  │ │ [👤] User    │ │                    │ ┌─────────────┐ │
│  │ │ user@...     │ │                    │ │[IMG] Story 2│ │
│  │ │ [USER]       │ │                    │ │ ...         │ │
│  │ │  [Cấp quyền] │ │                    │ └─────────────┘ │
│  │ └──────────────┘ │                    │                 │
│  │                  │                    │ Actions Menu:   │
│  │ Features:        │                    │ - View Detail   │
│  │ ✅ Search        │                    │ - Edit          │
│  │ ✅ Sort          │                    │ - Delete        │
│  │ ✅ Realtime      │                    │                 │
│  │ ✅ Protection    │                    │ Features:       │
│  │                  │                    │ ✅ Image Load   │
│  └──────────────────┘                    │ ✅ Badges       │
│                                          │ ✅ Actions      │
│                                          └─────────────────┘
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow

### 1. Authentication Flow
```
User Input (Email/Password)
    ↓
Firebase Auth
    ↓
Check isAdmin in Firestore
    ↓
Route to Admin Dashboard or Main Screen
```

### 2. Dashboard Statistics Flow
```
Dashboard Init
    ↓
Parallel Fetch:
    ├─→ Firestore.collection('users').get()
    ├─→ DatabaseService.getStories()
    └─→ Firestore.collection('stories/{id}/comments').get()
    ↓
Aggregate Data
    ↓
Update UI (setState)
```

### 3. Story Image Loading Flow
```
Story Card Build
    ↓
FutureBuilder<String>
    ↓
ImageHelper.getImageFromStory()
    ├─→ Check if URL (http/https)
    ├─→ Check assets path
    └─→ Normalize path
    ↓
Return image path
    ↓
Image Widget
    ├─→ NetworkImage (if URL)
    └─→ AssetImage (if local)
    ↓
Error? → Fallback Placeholder
```

### 4. User Management Flow
```
User Screen Init
    ↓
StreamBuilder<QuerySnapshot>
    ↓
Firestore.collection('users').snapshots()
    ↓
Filter by Search Query
    ↓
Sort (Admin first)
    ↓
Build User Cards
    ↓
User Action (Toggle Admin)
    ↓
Validate (not self)
    ↓
Update Firestore
    ↓
Realtime Update UI
```

---

## 🗂️ File Structure

```
lib/
├── screens/
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart    ← Main dashboard
│   │   ├── admin_story_screen.dart        ← Story management
│   │   └── admin_user_screen.dart         ← User management
│   ├── home/
│   │   └── ...                            ← User screens
│   └── ...
├── services/
│   ├── database_service.dart              ← SQLite + Firebase
│   ├── user_service.dart                  ← User state
│   ├── firebase_service.dart              ← Firebase ops
│   └── ...
├── models/
│   ├── story_model.dart                   ← Story data
│   └── ...
├── utils/
│   ├── image_helper.dart                  ← Image loading
│   └── ...
└── widgets/
    └── ...                                ← Reusable widgets
```

---

## 🔌 Service Integration

### DatabaseService
```dart
class DatabaseService {
  // SQLite Operations
  Future<List<Story>> getStories()
  Future<List<Map>> getChapters(String title)
  
  // Firebase Operations
  Future<void> toggleWishlist(userId, storyId)
  Future<void> addComment(...)
  Future<void> rateStory(...)
  
  // Streams
  Stream<List<String>> getWishlist(userId)
  Stream<Map<String, int>> getReadingList(userId)
  Stream<List<Map>> getComments(storyId)
}
```

### UserService
```dart
class UserService extends ChangeNotifier {
  AppUser? currentUser
  
  // Auth
  Future<void> login(email, password)
  Future<void> logout()
  
  // Admin
  bool get isAdmin
  bool get isSuperAdmin
  Future<void> setAdmin(uid, isAdmin)
  
  // User Data
  Future<void> toggleWishlist(storyId)
  Future<void> saveReadingProgress(...)
}
```

### ImageHelper
```dart
class ImageHelper {
  // Main function
  static Future<String> getImageFromStory({
    required String title,
    required String category,
    required String pathFromDb,
  })
  
  // Utilities
  static bool isNetwork(String path)
  static String fallbackImage()
}
```

---

## 🎨 UI Components

### Reusable Components

#### 1. Stat Card
```dart
Widget _buildStatCard({
  required IconData icon,
  required String title,
  required String value,
  required Color color,
})
```
**Used in**: Dashboard statistics

#### 2. Management Card
```dart
Widget _buildManagementCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
})
```
**Used in**: Dashboard navigation

#### 3. Story Card
```dart
Widget _buildStoryItem(Story story, ThemeData theme)
```
**Used in**: Story list with image, info, badges, actions

#### 4. User Card
```dart
Widget _buildUserCard({
  required String uid,
  required String email,
  required bool isAdmin,
  required bool isCurrentUser,
})
```
**Used in**: User list with avatar, role, actions

---

## 🔐 Security & Permissions

### Permission Levels

```
┌─────────────────────────────────────┐
│         SUPER ADMIN                 │
│    (admin@gmail.com)                │
│  ✅ All permissions                 │
│  ✅ Grant/Revoke admin              │
│  ✅ Manage all users                │
│  ✅ Manage all stories              │
└─────────────────────────────────────┘
            ↓
┌─────────────────────────────────────┐
│         ADMIN                       │
│    (isAdmin = true)                 │
│  ✅ View dashboard                  │
│  ✅ View users (read-only)          │
│  ✅ Manage stories                  │
│  ❌ Grant/Revoke admin              │
└─────────────────────────────────────┘
            ↓
┌─────────────────────────────────────┐
│         USER                        │
│    (isAdmin = false)                │
│  ❌ Access admin panel              │
│  ✅ Use app normally                │
└─────────────────────────────────────┘
```

### Validation Rules

```dart
// Cannot self-revoke admin
if (uid == currentUser.uid) {
  return error("Cannot change own permissions");
}

// Only super admin can grant/revoke
if (!isSuperAdmin) {
  return error("Permission denied");
}

// Admin check on route
if (!isAdmin) {
  return redirect(MainScreen);
}
```

---

## 📊 Database Schema

### Firebase Firestore
```
users/
  {userId}/
    - email: string
    - isAdmin: boolean
    - wishlist/
        {storyId}/
          - storyId: string
          - createdAt: timestamp
    - purchased/
        {storyId}/
          - title: string
          - image: string
          - time: string
          - lastChapter: number
    - reading_progress/
        {storyId}/
          - storyId: string
          - chapter: number
          - updatedAt: timestamp
    - comments/
        {commentId}/
          - storyId: string
          - content: string
          - createdAt: timestamp

stories/
  {storyId}/
    - ratings/
        {userId}/
          - rating: number (1-5)
    - comments/
        {commentId}/
          - userId: string
          - userName: string
          - avatar: string
          - content: string
          - createdAt: timestamp
```

### SQLite (Local)
```sql
-- Bảng truyện
CREATE TABLE truyen (
  ten_truyen TEXT PRIMARY KEY,
  tac_gia TEXT,
  the_loai TEXT,
  trang_thai TEXT,
  so_chuong TEXT,
  mo_ta TEXT
);

-- Bảng ảnh
CREATE TABLE anh_truyen (
  ten_truyen TEXT,
  the_loai TEXT,
  duong_dan_anh TEXT,
  FOREIGN KEY (ten_truyen) REFERENCES truyen(ten_truyen)
);

-- Bảng chương
CREATE TABLE chuong (
  ten_truyen TEXT,
  ten_chuong TEXT,
  link TEXT PRIMARY KEY,
  noi_dung TEXT,
  FOREIGN KEY (ten_truyen) REFERENCES truyen(ten_truyen)
);
```

---

## 🚀 Performance Optimization

### Current Optimizations
1. **Async Image Loading**: FutureBuilder không block UI
2. **Realtime Updates**: StreamBuilder cho user list
3. **Lazy Loading**: Chỉ load khi cần
4. **Caching**: SharedPreferences cho settings

### Future Optimizations
1. **Pagination**: Load stories/users theo batch
2. **Image Caching**: Cache ảnh đã load
3. **Debounce Search**: Giảm số lần query
4. **Cloud Functions**: Tính toán statistics server-side

---

## 🧪 Testing Strategy

### Unit Tests
- [ ] ImageHelper path normalization
- [ ] User permission validation
- [ ] Story model serialization

### Widget Tests
- [ ] Stat card rendering
- [ ] User card actions
- [ ] Story card image loading

### Integration Tests
- [ ] Login flow
- [ ] Grant/revoke admin
- [ ] Story CRUD operations

---

## 📈 Monitoring & Analytics

### Metrics to Track
- Admin login frequency
- User management actions
- Story views/edits
- Error rates
- Load times

### Logging
```dart
// Current: print statements
print("🔥 SAVE COMMENT: userId=$userId");

// Future: Proper logging service
Logger.info("User $userId added comment to $storyId");
```

---

**Last Updated**: 2026-04-23  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
