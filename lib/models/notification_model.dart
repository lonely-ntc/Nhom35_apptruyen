class AppNotification {
  final String title;     // ten_chuong
  final String message;   // ten_truyen
  final String time;      // hiển thị (tạm)
  final bool isRead;
  final String type;      // chapter

  AppNotification({
    required this.title,
    required this.message,
    this.time = "Mới cập nhật",
    this.isRead = false,
    this.type = "chapter",
  });

  /// 🔥 MAP từ bảng CHUONG
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      title: map['ten_chuong']?.toString() ?? "",
      message: map['ten_truyen']?.toString() ?? "",
      time: "Mới cập nhật",
      isRead: false,
      type: "chapter",
    );
  }

  /// 🔥 nếu sau này lưu DB (optional)
  Map<String, dynamic> toMap() {
    return {
      'ten_chuong': title,
      'ten_truyen': message,
      'time': time,
      'isRead': isRead ? 1 : 0,
      'type': type,
    };
  }
}