import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Hàm nạp xu vào tài khoản
  Future<bool> napXu(int soXuNap) async {
    try {
      // Lấy ID của người dùng đang đăng nhập
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      // Cập nhật số xu (cộng dồn lên) dùng FieldValue.increment để đảm bảo chính xác
      await _firestore.collection('users').doc(uid).update({
        'coin_balance': FieldValue.increment(soXuNap),
      });

      // Lưu lại hóa đơn vào bảng Lịch sử giao dịch
      await _firestore.collection('transactions').add({
        'uid': uid,
        'amount': soXuNap,
        'type': 'nap_tien',
        'status': 'success',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true; // Báo về cho giao diện là thành công
    } catch (e) {
      print("Lỗi khi nạp xu: $e");
      return false; // Báo lỗi
    }
  }

  // 2. Hàm thanh toán / Mua chương truyện
  Future<bool> thanhToanTruyen(int giaXu, String truyenId) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      // Kiểm tra xem user có đủ xu không
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      int xuHienTai = (userDoc.data() as Map<String, dynamic>)['coin_balance'] ?? 0;

      if (xuHienTai >= giaXu) {
        // Nếu đủ xu -> Trừ xu
        await _firestore.collection('users').doc(uid).update({
          'coin_balance': FieldValue.increment(-giaXu), // Số âm để trừ đi
        });

        // Lịch sử giao dịch trừ tiền
        await _firestore.collection('transactions').add({
          'uid': uid,
          'amount': -giaXu, 
          'type': 'mua_truyen',
          'truyen_id': truyenId,
          'status': 'success',
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        return true; // Giao dịch thành công, cho phép đọc truyện
      } else {
        // Không đủ tiền
        print("Số dư không đủ");
        return false; 
      }
    } catch (e) {
      print("Lỗi thanh toán: $e");
      return false;
    }
  }
}