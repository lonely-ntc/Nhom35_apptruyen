import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập email của bạn")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Gọi Firebase bắn email reset mật khẩu
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Đã gửi liên kết khôi phục! Vui lòng kiểm tra hộp thư."),
          backgroundColor: Colors.green,
        ),
      );
      
      // Gửi xong thì tự động lùi về trang Đăng nhập
      Navigator.pop(context); 
    } catch (e) {
      String message = "Đã xảy ra lỗi, vui lòng thử lại sau";
      if (e.toString().contains('user-not-found')) {
        message = "Không tìm thấy tài khoản với email này";
      } else if (e.toString().contains('invalid-email')) {
        message = "Email không hợp lệ";
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Quên mật khẩu?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Đừng lo! Nhập email của bạn và hệ thống sẽ gửi liên kết để đặt lại mật khẩu an toàn.",
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              
              /// EMAIL INPUT
              Text(
                "Email",
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Nhập email đã đăng ký",
                  hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                  prefixIcon: Icon(Icons.email_outlined, color: theme.iconTheme.color),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              /// XỬ LÝ GỬI
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: "Gửi liên kết khôi phục",
                      color: theme.colorScheme.primary,
                      onPressed: resetPassword,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}