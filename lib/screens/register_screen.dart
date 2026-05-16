import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/admin_config.dart';
import '../services/email_service.dart';
import 'auth/verify_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isRemember = true;
  bool isHidePassword = true;
  bool isHideConfirm = true;
  bool isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    // Validate input
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

    // Validate password strength
    if (passwordController.text.length < 6) {
      _showMessage("Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text.trim())) {
      _showMessage("Email không hợp lệ");
      return;
    }

    try {
      setState(() => isLoading = true);

      final email = emailController.text.trim().toLowerCase();

      // 🔥 KIỂM TRA EMAIL ĐÃ TỒN TẠI QUA FIREBASE AUTH (sign-in methods)
      final signInMethods = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        _showMessage(
            "Email này đã được đăng ký. Vui lòng dùng email khác hoặc đăng nhập.");
        setState(() => isLoading = false);
        return;
      }

      // 🔥 TẠO TÀI KHOẢN FIREBASE AUTH
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        /// 🔥 CẬP NHẬT DISPLAY NAME
        await user.updateDisplayName(usernameController.text.trim());
        
        ///  🔥 CHECK ADMIN - Kiểm tra email có trong danh sách admin không
        final isAdmin = AdminConfig.isAdminEmail(email);

        /// 🔥 TẠO MÃ OTP 6 SỐ
        final otpCode = EmailService.generateOTP();
        debugPrint('🔐 OTP Code: $otpCode'); // Debug only
        debugPrint('📧 Gửi OTP đến email: $email'); // Debug
        
        /// 🔥 GỬI MÃ OTP QUA EMAIL NGƯỜI DÙNG ĐĂNG KÝ
        final emailSent = await EmailService.guiMaOTP(
          toEmail: email,  // ← Email người dùng vừa nhập khi đăng ký
          userName: usernameController.text.trim(),
          otpCode: otpCode,
        );

        if (!emailSent) {
          _showMessage('❌ Không thể gửi mã OTP đến $email. Vui lòng kiểm tra email và thử lại.');
          setState(() => isLoading = false);
          return;
        }
        
        debugPrint('✅ Đã gửi OTP thành công đến: $email');

        /// 🔥 LƯU THÔNG TIN VÀO FIRESTORE (chưa verified)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'username': usernameController.text.trim(),
          'email': email,
          'isAdmin': isAdmin,
          'emailVerified': false, // 🔥 Chưa xác thực
          
          /// 🔥 THÔNG TIN CÁ NHÂN
          'displayName': usernameController.text.trim(),
          'avatar': 'assets/avatars/avatar1.png',
          'gender': 'Khác',
          'phoneNumber': '',
          'dateOfBirth': null,

          /// 🔥 DATA APP
          'wishlist': [],
          'purchased': [],
          'readingProgress': {},
          'favoriteCategories': [],
          'preferencesSet': false,
          'exp': 0,
          'level': 1,
          'coin_balance': 0,
          
          /// 🔥 THỐNG KÊ
          'totalStoriesRead': 0,
          'totalChaptersRead': 0,
          'totalCommentsPosted': 0,
          'totalTopupAmount': 0,
          'totalTopupTimes': 0,
          
          /// 🔥 TIMESTAMPS
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: false));

        if (!mounted) return;
        
        // 🔥 CHUYỂN SANG MÀN HÌNH NHẬP OTP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOTPScreen(
              email: email,
              userName: usernameController.text.trim(),
              correctOTP: otpCode,
            ),
          ),
        );
      }
      
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = "Email đã được đăng ký. Vui lòng sử dụng email khác hoặc đăng nhập.";
          break;
        case 'weak-password':
          message = "Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn.";
          break;
        case 'invalid-email':
          message = "Email không hợp lệ. Vui lòng kiểm tra lại.";
          break;
        case 'operation-not-allowed':
          message = "Đăng ký bằng email/mật khẩu chưa được kích hoạt.";
          break;
        case 'network-request-failed':
          message = "Lỗi kết nối mạng. Vui lòng kiểm tra internet.";
          break;
        default:
          message = "Lỗi đăng ký: ${e.message ?? 'Không xác định'}";
      }

      _showMessage(message);
    } catch (e) {
      _showMessage("Lỗi hệ thống: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFFFF6B6B),
                    const Color(0xFFFF8E53),
                    const Color(0xFFFFA726),
                  ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  /// HEADER
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Tạo tài khoản mới",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// FORM
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),

                            /// WELCOME TEXT
                            Text(
                              "Chào mừng! 🎉",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Tạo tài khoản để bắt đầu hành trình đọc truyện",
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),

                            const SizedBox(height: 30),

                            /// USERNAME
                            _buildLabel("Tên tài khoản", theme),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: usernameController,
                              hint: "Nhập tên tài khoản",
                              icon: Icons.person_outline,
                              theme: theme,
                            ),

                            const SizedBox(height: 20),

                            /// EMAIL
                            _buildLabel("Email", theme),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: emailController,
                              hint: "example@email.com",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              theme: theme,
                            ),

                            const SizedBox(height: 20),

                            /// PASSWORD
                            _buildLabel("Mật khẩu", theme),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: passwordController,
                              hint: "Nhập mật khẩu (tối thiểu 6 ký tự)",
                              icon: Icons.lock_outline,
                              obscureText: isHidePassword,
                              theme: theme,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isHidePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: theme.iconTheme.color,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isHidePassword = !isHidePassword;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// CONFIRM PASSWORD
                            _buildLabel("Xác nhận mật khẩu", theme),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: confirmPasswordController,
                              hint: "Nhập lại mật khẩu",
                              icon: Icons.lock_outline,
                              obscureText: isHideConfirm,
                              theme: theme,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isHideConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: theme.iconTheme.color,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isHideConfirm = !isHideConfirm;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// TERMS CHECKBOX
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: isRemember,
                                    onChanged: (value) {
                                      setState(() {
                                        isRemember = value!;
                                      });
                                    },
                                    activeColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Tôi đồng ý với Điều khoản & Chính sách",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            /// REGISTER BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : registerUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  disabledBackgroundColor: Colors.orange.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        "Đăng ký",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// LOGIN LINK
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: RichText(
                                  text: TextSpan(
                                    text: "Đã có tài khoản? ",
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontSize: 14,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: "Đăng nhập",
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.textTheme.bodyMedium?.color,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.textTheme.bodySmall?.color,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.orange,
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.orange,
            width: 2,
          ),
        ),
      ),
    );
  }
}
