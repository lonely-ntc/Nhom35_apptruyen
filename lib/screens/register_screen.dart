import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_button.dart';
import 'auth/select_preferences_screen.dart';

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

  /// 🔥 ADMIN TỔNG
  final String superAdminEmail = "admin@gmail.com";

  Future<void> registerUser() async {
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

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        /// 🔥 ÉP FIREBASE GỬI MAIL TIẾNG VIỆT
        FirebaseAuth.instance.setLanguageCode("vi"); 
        
        /// 🔥 GỬI EMAIL XÁC THỰC
        await user.sendEmailVerification();

        ///  CHECK ADMIN
        final isAdmin = emailController.text.trim() == superAdminEmail;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'isAdmin': isAdmin,

          /// 🔥 DATA APP
          'wishlist': [],
          'purchased': [],
          'readingProgress': {},
          'favoriteCategories': [], // 🔥 NEW
          'preferencesSet': false, // 🔥 NEW
          'exp': 0, // 🔥 NEW

          'createdAt': Timestamp.now(),
        });
      }

      // 🔥 HIỆN BẢNG YÊU CẦU XÁC THỰC EMAIL THAY VÌ BÁO THÀNH CÔNG LUÔN
      _showVerificationDialog();
      
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
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Tạo tài khoản 🔐",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                "Nhập tên tài khoản, email & mật khẩu.",
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),

              const SizedBox(height: 25),

              /// Username
              Text("Tài khoản",
                  style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color)),
              const SizedBox(height: 8),
              TextField(
                controller: usernameController,
                style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color),
                decoration: _inputStyle(context, "Nhập tên tài khoản"),
              ),

              const SizedBox(height: 20),

              /// Email
              Text("Email",
                  style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color)),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color),
                decoration: _inputStyle(
                  context,
                  "Nhập email",
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 20),

              /// Password
              Text("Mật khẩu",
                  style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color)),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: isHidePassword,
                style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color),
                decoration: _inputStyle(
                  context,
                  "Nhập mật khẩu",
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      isHidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: theme.iconTheme.color,
                    ),
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
              Text("Nhập lại mật khẩu",
                  style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color)),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPasswordController,
                obscureText: isHideConfirm,
                style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color),
                decoration: _inputStyle(
                  context,
                  "Nhập lại mật khẩu",
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      isHideConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: theme.iconTheme.color,
                    ),
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
                  Text(
                    "Nhớ mật khẩu",
                    style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color),
                  ),
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

  InputDecoration _inputStyle(BuildContext context, String hint,
      {IconData? icon, Widget? suffix}) {
    final theme = Theme.of(context);

    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: theme.textTheme.bodySmall?.color),
      prefixIcon:
          icon != null ? Icon(icon, color: theme.iconTheme.color) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// 🔥 BẢNG THÔNG BÁO YÊU CẦU XÁC THỰC EMAIL
  void _showVerificationDialog() {
    final theme = Theme.of(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc phải xác thực hoặc quay lại
      barrierLabel: "Verification",
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (_, __, ___) {
        // Dùng StatefulBuilder để nút bấm có thể hiện vòng xoay loading
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isChecking = false;

            return Center(
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mark_email_unread_rounded,
                          size: 60,
                          color: Colors.orange.shade400),
                      const SizedBox(height: 20),
                      Text(
                        "Xác thực Email ✉️",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Chúng tôi đã gửi một đường link xác thực đến email của bạn.\nVui lòng kiểm tra Hộp thư đến (hoặc Thư rác) và nhấn vào link để kích hoạt tài khoản.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      /// Nút TÔI ĐÃ XÁC THỰC
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isChecking
                              ? null
                              : () async {
                                  setStateDialog(() => isChecking = true);
                                  
                                  // Tải lại thông tin User từ Firebase để cập nhật trạng thái emailVerified
                                  await FirebaseAuth.instance.currentUser?.reload();
                                  final user = FirebaseAuth.instance.currentUser;
                                  
                                  if (user != null && user.emailVerified) {
                                    if (!context.mounted) return;
                                    Navigator.pop(context); // Đóng bảng thông báo
                                    
                                    // Chuyển sang màn hình chọn sở thích như cũ
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SelectPreferencesScreen(),
                                      ),
                                    );
                                  } else {
                                    setStateDialog(() => isChecking = false);
                                    _showMessage("Tài khoản chưa được xác thực! Hãy click vào link trong email.");
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: isChecking
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Tôi đã xác thực →",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      /// Nút QUAY LẠI ĐĂNG NHẬP (Lỡ nhập sai email)
                      TextButton(
                        onPressed: () {
                          // Đăng xuất và quay lại
                          FirebaseAuth.instance.signOut();
                          Navigator.pop(context); // Đóng bảng
                          Navigator.pop(context); // Quay về trang Login
                        },
                        child: Text(
                          "Nhập sai email? Quay lại",
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }
}