import 'package:flutter_test/flutter_test.dart';
import 'package:apptruyen/services/email_service.dart';

/// Test cho Email OTP Service
/// 
/// Chạy test: flutter test test/email_otp_test.dart
void main() {
  group('Email OTP Service Tests', () {
    
    test('generateOTP tạo mã 6 số', () {
      final otp = EmailService.generateOTP();
      
      // Kiểm tra độ dài
      expect(otp.length, 6);
      
      // Kiểm tra là số
      expect(int.tryParse(otp), isNotNull);
      
      // Kiểm tra trong khoảng 100000 - 999999
      final otpInt = int.parse(otp);
      expect(otpInt, greaterThanOrEqualTo(100000));
      expect(otpInt, lessThanOrEqualTo(999999));
      
      print('✅ OTP generated: $otp');
    });
    
    test('generateOTP tạo mã khác nhau', () {
      final otp1 = EmailService.generateOTP();
      final otp2 = EmailService.generateOTP();
      final otp3 = EmailService.generateOTP();
      
      // Kiểm tra 3 mã khác nhau (có thể trùng nhưng xác suất rất thấp)
      print('OTP 1: $otp1');
      print('OTP 2: $otp2');
      print('OTP 3: $otp3');
      
      // Ít nhất 2 trong 3 phải khác nhau
      expect(
        otp1 != otp2 || otp2 != otp3 || otp1 != otp3,
        true,
        reason: 'OTP should be random',
      );
    });
    
    test('Email format validation', () {
      // Valid emails
      expect(_isValidEmail('user@example.com'), true);
      expect(_isValidEmail('test.user@domain.co.uk'), true);
      expect(_isValidEmail('admin@gmail.com'), true);
      
      // Invalid emails
      expect(_isValidEmail('invalid'), false);
      expect(_isValidEmail('test@'), false);
      expect(_isValidEmail('@domain.com'), false);
      expect(_isValidEmail('test @domain.com'), false);
    });
    
    // Test gửi OTP (cần cấu hình EmailJS trước)
    test('guiMaOTP - Test gửi email (manual)', () async {
      // ⚠️ Test này cần EmailJS được cấu hình
      // Uncomment để test thực tế:
      
      /*
      final testEmail = 'your-test-email@example.com';  // ← Thay email test
      final testName = 'Test User';
      final testOTP = EmailService.generateOTP();
      
      print('📧 Gửi OTP test đến: $testEmail');
      print('🔐 OTP: $testOTP');
      
      final result = await EmailService.guiMaOTP(
        toEmail: testEmail,
        userName: testName,
        otpCode: testOTP,
      );
      
      expect(result, true, reason: 'Email should be sent successfully');
      print('✅ Email sent successfully!');
      */
      
      print('⚠️ Test gửi email bị skip (cần cấu hình EmailJS)');
    }, skip: true);
  });
}

/// Helper function để validate email
bool _isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}
