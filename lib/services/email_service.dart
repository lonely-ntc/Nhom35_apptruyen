import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'admin_management_service.dart';

/// Service để gửi email thông báo nạp xu và OTP qua EmailJS
/// 
/// Cách setup EmailJS:
/// 1. Đăng ký tài khoản tại https://www.emailjs.com/
/// 2. Tạo Email Service (Gmail, Outlook, etc.)
/// 3. Tạo Email Template với các biến:
///    - {{user_name}}: Tên người dùng
///    - {{user_email}}: Email người dùng
///    - {{coin}}: Số xu nạp
///    - {{time}}: Thời gian yêu cầu
/// 4. Lấy Service ID, Template ID, và Public Key
/// 5. Thêm vào file .env hoặc thay trực tiếp vào code
class EmailService {
  // 🔥 CẤU HÌNH EMAILJS CHO THÔNG BÁO NẠP XU
  static const String _topupServiceId = 'service_ocbbgnb';
  static const String _topupTemplateId = 'template_x8vstnj';
  static const String _topupPublicKey = 'Bv0jSB4J8jwIW4K8H';
  
  // 🔥 CẤU HÌNH EMAILJS CHO OTP (Service riêng)
  static const String _otpServiceId = 'service_ocbbgnb';      // ← Service ID cho OTP
  static const String _otpTemplateId = 'template_n7a03nh';    // ← Template ID cho OTP
  static const String _otpPublicKey = 'Bv0jSB4J8jwIW4K8H';    // ← Public Key cho OTP
  
  // 🔥 PRIVATE KEY (Nếu bật "Use Private Key" trong EmailJS)
  // Lấy từ: https://dashboard.emailjs.com/admin/account → API Keys → Private Key
  // Nếu BẬT "Use Private Key", paste Private Key vào đây:
  static const String? _otpPrivateKey = null;  // ← Paste Private Key hoặc để null
  // Ví dụ: static const String? _otpPrivateKey = 'YOUR_PRIVATE_KEY_HERE';
  
  // Email admin nhận thông báo nạp xu (DEPRECATED - Sử dụng AdminManagementService thay thế)
  // Danh sách này chỉ dùng làm fallback nếu không lấy được từ Firestore
  static const List<String> _fallbackAdminEmails = [
    'admin@gmail.com',
    'zingme369@gmail.com',
  ];

  /// 🔥 TẠO MÃ OTP NGẪU NHIÊN 6 SỐ
  static String generateOTP() {
    final random = Random();
    final otp = random.nextInt(900000) + 100000; // Tạo số từ 100000 đến 999999
    return otp.toString();
  }

  /// 🔥 GỬI MÃ OTP QUA EMAIL
  /// 
  /// [toEmail]: Email người nhận
  /// [userName]: Tên người dùng
  /// [otpCode]: Mã OTP 6 số
  static Future<bool> guiMaOTP({
    required String toEmail,
    required String userName,
    required String otpCode,
  }) async {
    try {
      debugPrint('========================================');
      debugPrint('📧 BẮT ĐẦU GỬI OTP');
      debugPrint('========================================');
      debugPrint('📋 Thông tin:');
      debugPrint('   - Email: $toEmail');
      debugPrint('   - Tên: $userName');
      debugPrint('   - OTP: $otpCode');
      debugPrint('');
      
      // Kiểm tra cấu hình OTP
      debugPrint('🔍 Kiểm tra cấu hình...');
      debugPrint('   - Service ID: $_otpServiceId');
      debugPrint('   - Template ID: $_otpTemplateId');
      debugPrint('   - Public Key: ${_otpPublicKey.substring(0, 5)}***');
      
      if (_otpServiceId.isEmpty || _otpTemplateId.isEmpty || _otpPublicKey.isEmpty) {
        debugPrint('❌ CẤU HÌNH CHƯA ĐẦY ĐỦ!');
        return false;
      }
      debugPrint('✓ Cấu hình hợp lệ');
      debugPrint('');

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      
      // Tạo request body
      final Map<String, dynamic> requestBody = {
        'service_id': _otpServiceId,
        'template_id': _otpTemplateId,
        'template_params': {
          'to_email': toEmail,
          'to_name': userName,
          'user_name': userName,
          'otp_code': otpCode,
          'from_name': 'App Truyện',
        },
      };

      // Thêm Public Key hoặc Private Key
      if (_otpPrivateKey != null && _otpPrivateKey!.isNotEmpty) {
        // Nếu có Private Key, dùng Private Key
        requestBody['accessToken'] = _otpPrivateKey;
        debugPrint('   - Sử dụng: Private Key');
      } else {
        // Nếu không có Private Key, dùng Public Key
        requestBody['user_id'] = _otpPublicKey;
        debugPrint('   - Sử dụng: Public Key');
      }

      debugPrint('📤 Gửi request đến EmailJS...');
      debugPrint('   URL: ${url.toString()}');
      debugPrint('   Body: ${jsonEncode(requestBody)}');
      debugPrint('');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ TIMEOUT: Request quá 30 giây');
          throw Exception('Request timeout');
        },
      );

      debugPrint('📥 RESPONSE NHẬN ĐƯỢC:');
      debugPrint('   - Status Code: ${response.statusCode}');
      debugPrint('   - Headers: ${response.headers}');
      debugPrint('   - Body: ${response.body}');
      debugPrint('');

      if (response.statusCode == 200) {
        debugPrint('========================================');
        debugPrint('✅ GỬI OTP THÀNH CÔNG!');
        debugPrint('   Email: $toEmail');
        debugPrint('   OTP: $otpCode');
        debugPrint('========================================');
        return true;
      } else {
        debugPrint('========================================');
        debugPrint('❌ GỬI OTP THẤT BẠI!');
        debugPrint('   Status: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        debugPrint('========================================');
        
        // Parse error message
        try {
          final errorData = jsonDecode(response.body);
          debugPrint('📋 Chi tiết lỗi:');
          debugPrint('   $errorData');
        } catch (e) {
          debugPrint('   Không thể parse error response');
        }
        
        debugPrint('');
        debugPrint('💡 HƯỚNG DẪN FIX:');
        if (response.statusCode == 404) {
          debugPrint('   → Template ID hoặc Service ID sai');
          debugPrint('   → Kiểm tra lại trên EmailJS Dashboard');
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          debugPrint('   → Public Key sai hoặc không có quyền');
          debugPrint('   → Kiểm tra lại Public Key');
        } else if (response.statusCode == 400) {
          debugPrint('   → Template thiếu biến hoặc dữ liệu sai');
          debugPrint('   → Kiểm tra template có: to_email, user_name, otp_code');
        }
        debugPrint('========================================');
        
        return false;
      }
    } on http.ClientException catch (e) {
      debugPrint('========================================');
      debugPrint('❌ LỖI KẾT NỐI MẠNG');
      debugPrint('   $e');
      debugPrint('   → Kiểm tra internet connection');
      debugPrint('========================================');
      return false;
    } on FormatException catch (e) {
      debugPrint('========================================');
      debugPrint('❌ LỖI FORMAT DỮ LIỆU');
      debugPrint('   $e');
      debugPrint('========================================');
      return false;
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('❌ LỖI KHÔNG XÁC ĐỊNH');
      debugPrint('   Error: $e');
      debugPrint('   Stack: $stackTrace');
      debugPrint('========================================');
      return false;
    }
  }

  /// Gửi thông báo nạp xu cho admin
  /// 
  /// [tenNguoiDung]: Tên người dùng yêu cầu nạp xu
  /// [emailKhachHang]: Email của người dùng
  /// [soXuNap]: Số xu muốn nạp
  /// [transactionId]: Mã giao dịch (optional)
  /// [bankInfo]: Thông tin chuyển khoản (optional)
  /// 
  /// 🔥 GỬI CHO TẤT CẢ ADMIN ĐƯỢC CẤP QUYỀN NHẬN THÔNG BÁO
  /// Mỗi admin chỉ nhận 1 email duy nhất
  static Future<bool> thongBaoChoAdmin({
    required String tenNguoiDung,
    required String emailKhachHang,
    required String soXuNap,
    String? transactionId,
    String? bankInfo,
  }) async {
    try {
      debugPrint('========================================');
      debugPrint('📧 BẮT ĐẦU GỬI THÔNG BÁO NẠP XU CHO ADMIN');
      debugPrint('========================================');
      
      // Kiểm tra cấu hình
      if (_topupServiceId == 'YOUR_SERVICE_ID' || 
          _topupTemplateId == 'YOUR_TEMPLATE_ID' || 
          _topupPublicKey == 'YOUR_PUBLIC_KEY') {
        debugPrint('⚠️ EmailJS chưa được cấu hình. Vui lòng cập nhật Service ID, Template ID và Public Key');
        return false;
      }

      // 🔥 LẤY DANH SÁCH ADMIN TỪ FIRESTORE
      final adminService = AdminManagementService();
      List<String> adminEmails = await adminService.getAdminEmailsForTopupNotification();
      
      // Nếu không lấy được từ Firestore, dùng fallback
      if (adminEmails.isEmpty) {
        debugPrint('⚠️ Không lấy được admin từ Firestore, dùng fallback list');
        adminEmails = _fallbackAdminEmails;
      }

      // Loại bỏ email trùng lặp
      adminEmails = adminEmails.map((e) => e.toLowerCase().trim()).toSet().toList();

      debugPrint('📋 Danh sách admin nhận thông báo (${adminEmails.length} admin):');
      for (var email in adminEmails) {
        debugPrint('   - $email');
      }
      debugPrint('');

      // 🔥 GỬI EMAIL CHO TỪNG ADMIN (Mỗi admin chỉ nhận 1 email)
      int successCount = 0;
      int failCount = 0;
      final List<String> successEmails = [];
      final List<String> failedEmails = [];

      for (String adminEmail in adminEmails) {
        debugPrint('📤 Đang gửi email cho: $adminEmail');
        
        final success = await _sendEmailToAdmin(
          toEmail: adminEmail,
          userName: tenNguoiDung,
          userEmail: emailKhachHang,
          coinAmount: soXuNap,
          transactionId: transactionId ?? 'N/A',
          bankInfo: bankInfo ?? 'Chưa cung cấp',
        );
        
        if (success) {
          successCount++;
          successEmails.add(adminEmail);
          debugPrint('✅ Gửi thành công cho: $adminEmail');
        } else {
          failCount++;
          failedEmails.add(adminEmail);
          debugPrint('❌ Gửi thất bại cho: $adminEmail');
        }
        
        // Delay nhỏ giữa các email để tránh spam (EmailJS rate limit)
        if (adminEmails.indexOf(adminEmail) < adminEmails.length - 1) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }

      debugPrint('');
      debugPrint('========================================');
      debugPrint('📊 KẾT QUẢ GỬI EMAIL:');
      debugPrint('   ✅ Thành công: $successCount/${adminEmails.length}');
      debugPrint('   ❌ Thất bại: $failCount/${adminEmails.length}');
      if (successEmails.isNotEmpty) {
        debugPrint('   📧 Emails thành công: ${successEmails.join(", ")}');
      }
      if (failedEmails.isNotEmpty) {
        debugPrint('   ⚠️ Emails thất bại: ${failedEmails.join(", ")}');
      }
      debugPrint('========================================');

      // Trả về true nếu ít nhất 1 email được gửi thành công
      return successCount > 0;
    } catch (e) {
      debugPrint('========================================');
      debugPrint('❌ LỖI GỬI EMAIL CHO ADMIN: $e');
      debugPrint('========================================');
      return false;
    }
  }

  /// Gửi email xác nhận nạp xu thành công cho người dùng
  /// 
  /// [toEmail]: Email người nhận
  /// [userName]: Tên người dùng
  /// [coinAmount]: Số xu đã nạp
  /// [transactionId]: Mã giao dịch
  static Future<bool> guiXacNhanNapXu({
    required String toEmail,
    required String userName,
    required String coinAmount,
    required String transactionId,
  }) async {
    try {
      if (_topupServiceId == 'YOUR_SERVICE_ID' || 
          _topupTemplateId == 'YOUR_TEMPLATE_ID' || 
          _topupPublicKey == 'YOUR_PUBLIC_KEY') {
        debugPrint('⚠️ EmailJS chưa được cấu hình');
        return false;
      }

      return await _sendEmail(
        toEmail: toEmail,
        userName: userName,
        userEmail: toEmail,
        coinAmount: coinAmount,
        transactionId: transactionId,
        bankInfo: 'Đã xác nhận',
        isConfirmation: true,
      );
    } catch (e) {
      debugPrint('❌ Lỗi gửi email xác nhận: $e');
      return false;
    }
  }

  /// Hàm private để gửi email thông báo nạp xu cho admin qua EmailJS API
  static Future<bool> _sendEmailToAdmin({
    required String toEmail,
    required String userName,
    required String userEmail,
    required String coinAmount,
    required String transactionId,
    required String bankInfo,
  }) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      
      // Lấy thời gian hiện tại
      final now = DateTime.now();
      final time = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _topupServiceId,
          'template_id': _topupTemplateId,
          'user_id': _topupPublicKey,
          'template_params': {
            // 🔥 Email admin nhận thông báo (theo template EmailJS)
            'to_email_admin': toEmail,
            'to_email': toEmail,  // Fallback
            
            // 🔥 Thông tin người dùng nạp xu
            'user_name': userName,
            'email': userEmail,  // Email khách hàng
            'user_email': userEmail,  // Fallback
            
            // 🔥 Thông tin giao dịch
            'coin': coinAmount,
            'time': time,
            'transaction_id': transactionId,
            'bank_info': bankInfo,
            
            // 🔥 Metadata
            'from_name': 'App Truyện - Hệ thống nạp xu',
            'subject': '🔔 Yêu cầu nạp xu mới từ $userName',
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ TIMEOUT: Request gửi email quá 30 giây');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Email đã được gửi thành công đến admin: $toEmail');
        return true;
      } else {
        debugPrint('❌ Lỗi gửi email đến admin $toEmail: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception khi gửi email đến admin $toEmail: $e');
      return false;
    }
  }

  /// Hàm private để gửi email xác nhận nạp xu cho người dùng qua EmailJS API
  static Future<bool> _sendEmail({
    required String toEmail,
    required String userName,
    required String userEmail,
    required String coinAmount,
    required String transactionId,
    required String bankInfo,
    bool isConfirmation = false,
  }) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      
      // Lấy thời gian hiện tại
      final now = DateTime.now();
      final time = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _topupServiceId,
          'template_id': _topupTemplateId,
          'user_id': _topupPublicKey,
          'template_params': {
            'to_email': toEmail,
            'user_name': userName,
            'user_email': userEmail,
            'email': userEmail,
            'coin': coinAmount,
            'time': time,
            'transaction_id': transactionId,
            'bank_info': bankInfo,
            'is_confirmation': isConfirmation,
            'subject': isConfirmation 
                ? '✅ Xác nhận nạp xu thành công' 
                : '🔔 Yêu cầu nạp xu mới',
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Email nạp xu đã được gửi thành công đến: $toEmail');
        return true;
      } else {
        debugPrint('❌ Lỗi gửi email nạp xu: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception khi gửi email nạp xu: $e');
      return false;
    }
  }

  /// Test gửi email (dùng để kiểm tra cấu hình)
  static Future<void> testEmail() async {
    debugPrint('🧪 Đang test gửi email...');
    
    final result = await thongBaoChoAdmin(
      tenNguoiDung: 'Test User',
      emailKhachHang: 'test@example.com',
      soXuNap: '1000',
      transactionId: 'TEST123',
      bankInfo: 'Test Bank Transfer',
    );

    if (result) {
      debugPrint('✅ Test email thành công!');
    } else {
      debugPrint('❌ Test email thất bại!');
    }
  }

  /// 🧪 Test gửi OTP (dùng để kiểm tra cấu hình OTP)
  static Future<void> testOTP({String? testEmail}) async {
    debugPrint('🧪 ========================================');
    debugPrint('🧪 BẮT ĐẦU TEST GỬI OTP');
    debugPrint('🧪 ========================================');
    
    final email = testEmail ?? 'test@example.com';
    final otp = generateOTP();
    
    debugPrint('📋 Thông tin test:');
    debugPrint('   - Email: $email');
    debugPrint('   - OTP: $otp');
    debugPrint('   - Service ID: $_otpServiceId');
    debugPrint('   - Template ID: $_otpTemplateId');
    
    final result = await guiMaOTP(
      toEmail: email,
      userName: 'Test User',
      otpCode: otp,
    );

    debugPrint('🧪 ========================================');
    if (result) {
      debugPrint('✅ TEST OTP THÀNH CÔNG!');
      debugPrint('   Kiểm tra email: $email');
    } else {
      debugPrint('❌ TEST OTP THẤT BẠI!');
      debugPrint('   Vui lòng kiểm tra:');
      debugPrint('   1. Service ID có đúng không?');
      debugPrint('   2. Template ID có đúng không?');
      debugPrint('   3. Public Key có đúng không?');
      debugPrint('   4. Template có các biến: to_email, user_name, otp_code?');
      debugPrint('   5. Internet connection có ổn định không?');
    }
    debugPrint('🧪 ========================================');
  }
}
