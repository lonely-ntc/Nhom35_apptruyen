import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/custom_button.dart';
import 'register_screen.dart';
import '../screens/main/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Đăng nhập thất bại";

      if (e.code == 'user-not-found') {
        message = "Không tìm thấy tài khoản";
      } else if (e.code == 'wrong-password') {
        message = "Sai mật khẩu";
      } else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      /// 🔥 FIX DARK MODE
      backgroundColor: theme.scaffoldBackgroundColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// 🔹 LOGO
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.cardColor, // 🔥 FIX
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/images/app_icon.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 Title
              Text(
                "Chào mừng trở lại!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                "Đăng nhập để tiếp tục đọc truyện",
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),

              const SizedBox(height: 30),

              /// 🔹 Email
              Text(
                "Email",
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: emailController,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: "Nhập email của bạn",
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: theme.iconTheme.color,
                  ),
                  filled: true,
                  fillColor: theme.cardColor, // 🔥 FIX
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 Password
              Text(
                "Mật khẩu",
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: "Nhập mật khẩu của bạn",
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: theme.iconTheme.color,
                  ),
                  filled: true,
                  fillColor: theme.cardColor, // 🔥 FIX
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// 🔥 LOGIN BUTTON
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: "Đăng nhập",

                      /// 🔥 FIX màu theo theme
                      color: theme.colorScheme.primary,
                      onPressed: login,
                    ),

              const SizedBox(height: 30),

              /// 🔥 REGISTER
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Chưa có tài khoản? ",
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      children: [
                        TextSpan(
                          text: "Đăng ký",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}