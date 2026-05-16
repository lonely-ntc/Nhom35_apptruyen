import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/email_service.dart';
import 'select_preferences_screen.dart';

class VerifyOTPScreen extends StatefulWidget {
  final String email;
  final String userName;
  final String correctOTP;

  const VerifyOTPScreen({
    super.key,
    required this.email,
    required this.userName,
    required this.correctOTP,
  });

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  
  final List<FocusNode> focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool isVerifying = false;
  bool isResending = false;
  int countdown = 300; // 5 phút = 300 giây
  Timer? timer;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  @override
  void dispose() {
    timer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void startCountdown() {
    timer?.cancel();
    setState(() {
      countdown = 300;
    });
    
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get countdownText {
    final minutes = countdown ~/ 60;
    final seconds = countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> verifyOTP() async {
    final enteredOTP = otpControllers.map((c) => c.text).join();
    
    if (enteredOTP.length != 6) {
      setState(() {
        errorMessage = 'Vui lòng nhập đầy đủ 6 số';
      });
      return;
    }

    setState(() {
      isVerifying = true;
      errorMessage = null;
    });

    // Giả lập delay kiểm tra
    await Future.delayed(const Duration(milliseconds: 500));

    if (enteredOTP == widget.correctOTP) {
      // OTP đúng
      if (!mounted) return;
      
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Xác thực thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Chuyển sang màn hình chọn sở thích
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SelectPreferencesScreen(),
        ),
      );
    } else {
      // OTP sai
      setState(() {
        isVerifying = false;
        errorMessage = '❌ Mã OTP không đúng. Vui lòng thử lại.';
      });
      
      // Xóa các ô nhập
      for (var controller in otpControllers) {
        controller.clear();
      }
      focusNodes[0].requestFocus();
    }
  }

  Future<void> resendOTP() async {
    if (isResending || countdown > 0) return;

    setState(() {
      isResending = true;
      errorMessage = null;
    });

    // Tạo OTP mới
    final newOTP = EmailService.generateOTP();
    
    // Gửi email
    final success = await EmailService.guiMaOTP(
      toEmail: widget.email,
      userName: widget.userName,
      otpCode: newOTP,
    );

    if (success) {
      // Cập nhật OTP mới (cần truyền lại qua constructor hoặc callback)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã gửi lại mã OTP mới!'),
          backgroundColor: Colors.green,
        ),
      );
      
      startCountdown();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không thể gửi lại OTP. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isResending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  size: 60,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 30),

              // Title
              Text(
                '🔐 Xác Thực OTP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Đây là mã xác thực đăng ký tài khoản của bạn:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),

              const SizedBox(height: 8),

              // Email
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: otpControllers[index],
                      focusNode: focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: theme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: errorMessage != null 
                                ? Colors.red 
                                : Colors.orange.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: errorMessage != null 
                                ? Colors.red 
                                : Colors.orange.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.orange,
                            width: 2,
                          ),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          focusNodes[index - 1].requestFocus();
                        }
                        
                        // Auto verify khi nhập đủ 6 số
                        if (index == 5 && value.isNotEmpty) {
                          verifyOTP();
                        }
                        
                        setState(() {
                          errorMessage = null;
                        });
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Error Message
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isVerifying ? null : verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.orange.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Xác thực',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              // Countdown & Resend
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 20,
                          color: countdown > 0 ? Colors.orange : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          countdown > 0 
                              ? 'Mã OTP có hiệu lực trong $countdownText'
                              : 'Mã OTP đã hết hạn',
                          style: TextStyle(
                            fontSize: 13,
                            color: countdown > 0 
                                ? theme.textTheme.bodySmall?.color 
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: (countdown == 0 && !isResending) ? resendOTP : null,
                      child: isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              countdown > 0 
                                  ? 'Gửi lại mã ($countdownText)'
                                  : 'Gửi lại mã OTP',
                              style: TextStyle(
                                color: countdown == 0 
                                    ? Colors.orange 
                                    : theme.textTheme.bodySmall?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
