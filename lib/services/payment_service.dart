import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Hàm tạo link ảnh QR code từ VietQR (Form mới: Email + Tên + Số xu)
  String taoUrlVietQR({
    required int soTienVND,
    required String tenNguoiDung,
    required String email,
    required int soXu,
  }) {
    String bankId = "MB"; 
    String accountNo = "0327520891"; 
    String accountName = "PHONG NHAT HUY"; 

    // Tạo lời nhắn: Email + Tên + Số xu (Bỏ dấu để QR dễ đọc hơn)
    String content = "$email $tenNguoiDung $soXu xu";
    
    // Encode URL để xử lý khoảng trắng và ký tự đặc biệt
    String encodedContent = Uri.encodeComponent(content);

    return "https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=$soTienVND&addInfo=$encodedContent&accountName=${accountName.replaceAll(' ', '%20')}";
  }

  // 2. HÀM DÀNH CHO ADMIN: Cộng xu sau khi Admin bấm nút "Duyệt"
  Future<bool> xacNhanThanhToanThanhCong({
    required int soTienVND,
    int bonusXu = 0,
    String? userId, 
  }) async {
    try {
      String? uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) return false;

      int soXuDuocCong = soTienVND ~/ 1000;
      int totalXu = soXuDuocCong + bonusXu;

      await _firestore.collection('users').doc(uid).update({
        'coin_balance': FieldValue.increment(totalXu),
      });

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

      return true; 
    } catch (e) {
      print("Lỗi khi duyệt cộng xu: $e");
      return false;
    }
  }
}