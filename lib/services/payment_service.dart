import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Hàm tạo link ảnh QR code từ VietQR (Đã cập nhật thông tin thật)
  String taoUrlVietQR({required int soTienVND}) {
    // Thông tin tài khoản nhận tiền
    String bankId = "MB"; 
    String accountNo = "0327520891"; 
    String accountName = "PHONG NHAT HUY"; 

    String? uid = _auth.currentUser?.uid;
    String maNguoiDung = uid != null ? uid.substring(0, 6).toUpperCase() : "GUEST";
    
    // Nội dung chuyển khoản: NAPXU + 6 mã đầu của UID user
    String addInfo = "NAPXU $maNguoiDung";

    // Link API VietQR (compact2 là giao diện đẹp có logo ngân hàng)
    return "https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=$soTienVND&addInfo=$addInfo&accountName=${accountName.replaceAll(' ', '%20')}";
  }

  // 2. Hàm CỘNG XU SAU KHI ADMIN DUYỆT
  Future<bool> xacNhanThanhToanThanhCong({
    required int soTienVND,
    int bonusXu = 0,
    String? userId, // NEW: Accept userId parameter for admin approval
  }) async {
    try {
      // Use provided userId or fallback to current user
      String? uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return false;

      // Quy đổi tiền ra xu: 1000đ = 1 xu
      int soXuDuocCong = soTienVND ~/ 1000;
      
      // Cộng thêm bonus nếu có
      int totalXu = soXuDuocCong + bonusXu;

      // 1. Cộng xu vào tài khoản User
      await _firestore.collection('users').doc(uid).update({
        'coin_balance': FieldValue.increment(totalXu),
      });

      // 2. Lưu lại hóa đơn vào bảng transactions
      await _firestore.collection('transactions').add({
        'uid': uid,
        'amount_vnd': soTienVND,
        'coin_added': totalXu,
        'base_coin': soXuDuocCong,
        'bonus_coin': bonusXu,
        'type': 'topup',
        'status': 'success',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true; // Báo về cho giao diện là thành công
    } catch (e) {
      print("Lỗi khi cộng xu: $e");
      return false;
    }
  }
}