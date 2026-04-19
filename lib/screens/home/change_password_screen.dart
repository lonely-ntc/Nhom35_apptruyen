import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool isLoading = false;
  bool obscure1 = true;
  bool obscure2 = true;
  bool obscure3 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đổi mật khẩu"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// ===== OLD PASSWORD =====
            TextField(
              controller: oldPassController,
              obscureText: obscure1,
              decoration: InputDecoration(
                labelText: "Mật khẩu cũ",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscure1
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      obscure1 = !obscure1;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ===== NEW PASSWORD =====
            TextField(
              controller: newPassController,
              obscureText: obscure2,
              decoration: InputDecoration(
                labelText: "Mật khẩu mới",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscure2
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      obscure2 = !obscure2;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ===== CONFIRM PASSWORD =====
            TextField(
              controller: confirmPassController,
              obscureText: obscure3,
              decoration: InputDecoration(
                labelText: "Nhập lại mật khẩu",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscure3
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      obscure3 = !obscure3;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ===== BUTTON =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _changePassword,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text("Đổi mật khẩu"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 CHANGE PASSWORD
  Future<void> _changePassword() async {
    final oldPass = oldPassController.text.trim();
    final newPass = newPassController.text.trim();
    final confirmPass = confirmPassController.text.trim();

    if (oldPass.isEmpty ||
        newPass.isEmpty ||
        confirmPass.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (newPass != confirmPass) {
      _showMsg("Mật khẩu mới không khớp");
      return;
    }

    if (newPass.length < 6) {
      _showMsg("Mật khẩu phải >= 6 ký tự");
      return;
    }

    try {
      setState(() => isLoading = true);

      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: oldPass,
      );

      /// 🔥 XÁC THỰC LẠI USER
      await user!.reauthenticateWithCredential(credential);

      /// 🔥 ĐỔI PASS
      await user!.updatePassword(newPass);

      _showMsg("Đổi mật khẩu thành công");

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showMsg("Sai mật khẩu cũ");
      } else {
        _showMsg(e.message ?? "Lỗi");
      }
    } catch (e) {
      _showMsg("Có lỗi xảy ra");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}