# 🛒 Hỗ trợ đa ngôn ngữ cho Nút Mua Truyện

## 📋 Tổng quan

Tất cả các text liên quan đến mua truyện đã được cập nhật để hỗ trợ đa ngôn ngữ (Tiếng Việt ↔ English).

## 🔧 Keys đã thêm vào app_text.dart

### Purchase Section
```dart
// Tiếng Việt
"free": "MIỄN PHÍ"
"buy_story": "Mua truyện"
"buy_now": "Mua ngay"
"price": "Giá:"
"you_will_receive": "Bạn sẽ nhận được +1000 EXP"

// English
"free": "FREE"
"buy_story": "Buy Story"
"buy_now": "Buy Now"
"price": "Price:"
"you_will_receive": "You will receive +1000 EXP"
```

## 📁 Files đã cập nhật

### 1. lib/utils/app_text.dart
**Thêm mới:**
- Section `/// PURCHASE` với 5 keys mới
- Hỗ trợ cả Tiếng Việt và English

### 2. lib/screens/home/story_detail_screen.dart
**Các thay đổi:**

#### a) Badge "MIỄN PHÍ" / "FREE"
**Trước:**
```dart
text: _isFreeStory() ? "MIỄN PHÍ" : "${_getStoryPrice()} đ"
```

**Sau:**
```dart
text: _isFreeStory() ? AppText.get("free", lang) : "${_getStoryPrice()} đ"
```

#### b) Nút "Mua truyện"
**Trước:**
```dart
text: "Mua truyện - ${_getStoryPrice()} đ"
```

**Sau:**
```dart
text: "${AppText.get("buy_story", lang)} - ${_getStoryPrice()} đ"
```

#### c) Dialog Mua Truyện
**Trước:**
```dart
const Text('Mua truyện')  // Title
const Text('Giá:')        // Price label
const Text('Bạn sẽ nhận được +1000 EXP')  // Reward text
const Text('Hủy')         // Cancel button
text: 'Mua ngay'          // Buy button
```

**Sau:**
```dart
Text(AppText.get("buy_story", lang))      // Title
Text(AppText.get("price", lang))          // Price label
Text(AppText.get("you_will_receive", lang))  // Reward text
Text(AppText.get("cancel", lang))         // Cancel button
text: AppText.get("buy_now", lang)        // Buy button
```

## 🎯 Kết quả khi chuyển sang Tiếng Anh

### Story Detail Screen
| Tiếng Việt | English |
|------------|---------|
| MIỄN PHÍ | FREE |
| Mua truyện - 10000 đ | Buy Story - 10000 đ |

### Purchase Dialog
| Tiếng Việt | English |
|------------|---------|
| Mua truyện | Buy Story |
| Giá: | Price: |
| Bạn sẽ nhận được +1000 EXP | You will receive +1000 EXP |
| Hủy | Cancel |
| Mua ngay | Buy Now |

## 💡 Cách sử dụng

```dart
// Lấy ngôn ngữ hiện tại
final lang = context.read<LanguageService>().lang;

// Sử dụng trong text
Text(AppText.get("buy_story", lang))  // "Mua truyện" hoặc "Buy Story"
Text(AppText.get("free", lang))       // "MIỄN PHÍ" hoặc "FREE"
Text(AppText.get("buy_now", lang))    // "Mua ngay" hoặc "Buy Now"
```

## ✅ Tổng kết

- ✅ **0 warnings, 0 errors**
- ✅ **5 purchase keys** đã được thêm vào app_text.dart
- ✅ **1 file** đã được cập nhật (story_detail_screen.dart)
- ✅ Tất cả text liên quan đến mua truyện đều hỗ trợ đa ngôn ngữ
- ✅ Dialog mua truyện hoàn toàn được internationalize

## 🎨 Demo UI

### Tiếng Việt
```
┌─────────────────────────────────────┐
│  🛒 Mua truyện                      │
├─────────────────────────────────────┤
│  Tên truyện: 12 Nữ Thần            │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Giá:              10000 đ     │ │
│  └───────────────────────────────┘ │
│                                     │
│  🎁 Bạn sẽ nhận được +1000 EXP     │
│                                     │
│  [ Hủy ]      [ Mua ngay ]         │
└─────────────────────────────────────┘
```

### English
```
┌─────────────────────────────────────┐
│  🛒 Buy Story                       │
├─────────────────────────────────────┤
│  Story: 12 Nữ Thần                 │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Price:            10000 đ     │ │
│  └───────────────────────────────┘ │
│                                     │
│  🎁 You will receive +1000 EXP     │
│                                     │
│  [ Cancel ]   [ Buy Now ]          │
└─────────────────────────────────────┘
```

## 📝 Lưu ý

- Giá tiền vẫn giữ nguyên format "đ" (đồng) cho cả 2 ngôn ngữ
- Badge "MIỄN PHÍ" / "FREE" tự động chuyển đổi theo ngôn ngữ
- Dialog mua truyện cần `context.read<LanguageService>().lang` để lấy ngôn ngữ hiện tại
- Nút "Hủy" / "Cancel" sử dụng key "cancel" đã có sẵn từ trước

## 🔄 Hot Restart

Sau khi cập nhật, nhớ **Hot Restart** (nhấn R) để load lại static data trong AppText!
