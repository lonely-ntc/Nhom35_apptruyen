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

  // 2. Hàm TỰ ĐỘNG CỘNG XU SAU KHI THANH TOÁN
  Future<bool> xacNhanThanhToanThanhCong({required int soTienVND}) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      // Quy đổi tiền ra xu: 100đ = 1 xu (Nạp 50.000đ -> 500 xu)
      int soXuDuocCong = soTienVND ~/ 100; 

      // 1. Cộng xu vào tài khoản User
      await _firestore.collection('users').doc(uid).update({
        'coin_balance': FieldValue.increment(soXuDuocCong),
      });

      // 2. Lưu lại hóa đơn vào bảng transactions
      await _firestore.collection('transactions').add({
        'uid': uid,
        'amount_vnd': soTienVND,
        'coin_added': soXuDuocCong,
        'type': 'nap_xu',
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