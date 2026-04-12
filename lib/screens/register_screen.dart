import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isRemember = true;
  bool isHidePassword = true;
  bool isHideConfirm = true;
  bool isLoading = false;

  /// 🔥 REGISTER + FIREBASE
  Future<void> registerUser() async {
    /// 🔹 Validate
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _showMessage("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showMessage("Mật khẩu không khớp");
      return;
    }

    try {
      setState(() => isLoading = true);

      /// 🔹 1. Tạo tài khoản Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      /// 🔹 2. Lưu Firestore (FIX null an toàn)
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'createdAt': Timestamp.now(),
        });
      }

      /// 🔥 Thành công → show dialog
      _showSuccessDialog();

    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = "Email đã tồn tại";
          break;
        case 'weak-password':
          message = "Mật khẩu quá yếu";
          break;
        case 'invalid-email':
          message = "Email không hợp lệ";
          break;
        default:
          message = e.message ?? "Lỗi không xác định";
      }

      _showMessage(message);
    } catch (e) {
      _showMessage("Lỗi hệ thống");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    /// 🔥 FIX MEMORY LEAK (quan trọng)
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),

              const SizedBox(height: 10),

              const Text(
                "Tạo tài khoản 🔐",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "Nhập tên tài khoản, email & mật khẩu.",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 25),

              /// Username
              const Text("Tài khoản"),
              const SizedBox(height: 8),
              TextField(
                controller: usernameController,
                decoration: _inputStyle("Nhập tên tài khoản"),
              ),

              const SizedBox(height: 20),

              /// Email
              const Text("Email"),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: _inputStyle(
                  "Nhập email",
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 20),

              /// Password
              const Text("Mật khẩu"),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: isHidePassword,
                decoration: _inputStyle(
                  "Nhập mật khẩu",
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(isHidePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        isHidePassword = !isHidePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Confirm Password
              const Text("Nhập lại mật khẩu"),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPasswordController,
                obscureText: isHideConfirm,
                decoration: _inputStyle(
                  "Nhập lại mật khẩu",
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(isHideConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        isHideConfirm = !isHideConfirm;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Checkbox(
                    value: isRemember,
                    onChanged: (value) {
                      setState(() {
                        isRemember = value!;
                      });
                    },
                  ),
                  const Text("Nhớ mật khẩu"),
                ],
              ),

              const SizedBox(height: 20),

              CustomButton(
                text: "Tiếp tục",
                isLoading: isLoading,
                onPressed: registerUser,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 Style input dùng lại (clean code)
  InputDecoration _inputStyle(String hint,
      {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// 🔥 Dialog thành công
 void _showSuccessDialog() {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: "Success",
    transitionDuration: const Duration(milliseconds: 300),

    /// 🔥 ANIMATION (ZOOM + FADE)
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },

    /// 🔹 UI
    pageBuilder: (_, __, ___) {
      return Center(
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🔵 ICON
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔹 TITLE
                const Text(
                  "Đăng ký thành công 🎉",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                /// 🔹 DESC
                const Text(
                  "Tài khoản của bạn đã được tạo thành công.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 25),

                /// 🔘 BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // đóng dialog
                      Navigator.pop(context); // về login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Tiếp tục"),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}
}