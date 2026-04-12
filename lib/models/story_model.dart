class Story {
  /// 🔥 từ DB
  final String title;          // ten_truyen
  final String author;         // tac_gia
  final String category;       // the_loai
  final String status;         // trang_thai
  final String totalChapters;  // so_chuong
  final String description;    // mo_ta
  final String image;          // duong_dan_anh

  /// 🔥 giữ lại cho UI cũ
  final int chapter;           // dùng tạm cho progress
  final String time;           // thời gian hiển thị

  Story({
    required this.title,
    this.author = "Unknown",
    this.category = "",
    this.status = "",
    this.totalChapters = "",
    this.description = "",
    this.image = "",

    // fallback UI
    this.chapter = 0,
    this.time = "",
  });

  /// 🔥 MAP từ SQLite
  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      title: map['ten_truyen']?.toString() ?? "",
      author: map['tac_gia']?.toString() ?? "Unknown",
      category: map['the_loai']?.toString() ?? "",
      status: map['trang_thai']?.toString() ?? "",
      totalChapters: map['so_chuong']?.toString() ?? "",
      description: map['mo_ta']?.toString() ?? "",
      image: map['duong_dan_anh']?.toString() ?? "",
    );
  }

  /// 🔥 convert ngược lại (nếu cần lưu sau này)
  Map<String, dynamic> toMap() {
    return {
      'ten_truyen': title,
      'tac_gia': author,
      'the_loai': category,
      'trang_thai': status,
      'so_chuong': totalChapters,
      'mo_ta': description,
      'duong_dan_anh': image,
    };
  }
}