import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static Future<void> thongBaoChoAdmin({
    required String tenNguoiDung,
    required String emailKhachHang, 
    required String soXuNap,
  }) async {
    String adminEmail = 'huyphongg305@gmail.com';
    // ĐIỀN LẠI MÃ 16 CHỮ CÁI CỦA ÔNG VÀO ĐÂY NHÉ:
    String appPassword = 'bxwe uzcy zfbc yvbo'; 

    final smtpServer = gmail(adminEmail, appPassword);

    final message = Message()
      ..from = Address(adminEmail, 'Hệ thống App Truyện')
      ..recipients.add(adminEmail)
      ..subject = '🔔 YÊU CẦU NẠP XU MỚI'
      ..text = '''
Dưới đây là thông tin khách nạp tiền:

- Tên người dùng: $tenNguoiDung
- Mail người dùng: $emailKhachHang
- Số xu nạp: $soXuNap xu

Vui lòng kiểm tra tài khoản ngân hàng và duyệt trong App!
      ''';

    try {
      await send(message, smtpServer);
      print('Đã gửi email thông báo cho Admin thành công!');
    } catch (e) {
      print('Lỗi gửi mail: $e');
    }
  }
}