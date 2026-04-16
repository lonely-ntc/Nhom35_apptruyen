import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart'; // 🔥 THÊM

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final user = FirebaseAuth.instance.currentUser;

  late TextEditingController nameController;
  late TextEditingController emailController;

  String gender = "Nam";

  final List<String> avatarList = List.generate(
    10,
    (index) => "assets/avatars/avatar${index + 1}.png",
  );

  String selectedAvatar = "assets/avatars/avatar1.png";

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: user?.displayName ?? "Người dùng",
    );

    emailController = TextEditingController(
      text: user?.email ?? "",
    );

    _loadUserData();
  }

  /// 🔥 LOAD AVATAR + GENDER
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedAvatar = prefs.getString("avatar_${user?.uid}");
    final savedGender = prefs.getString("gender_${user?.uid}");

    setState(() {
      if (savedAvatar != null) selectedAvatar = savedAvatar;
      if (savedGender != null) gender = savedGender;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thông tin cá nhân")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// ===== AVATAR =====
            GestureDetector(
              onTap: _showAvatarPicker,
              child: CircleAvatar(
                radius: 45,
                backgroundImage: AssetImage(selectedAvatar),
              ),
            ),

            const SizedBox(height: 8),
            const Text("Chọn ảnh đại diện"),

            const SizedBox(height: 20),

            /// NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Tên hiển thị",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// EMAIL
            TextField(
              controller: emailController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// GENDER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: gender,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: "Nam", child: Text("Nam")),
                  DropdownMenuItem(value: "Nữ", child: Text("Nữ")),
                  DropdownMenuItem(value: "Khác", child: Text("Khác")),
                ],
                onChanged: (value) {
                  setState(() {
                    gender = value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProfile,
                child: const Text("Lưu thay đổi"),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// PICK AVATAR
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: avatarList.length,
          itemBuilder: (_, index) {
            final avatar = avatarList[index];

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedAvatar = avatar;
                });
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundImage: AssetImage(avatar),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// SAVE
  Future<void> _updateProfile() async {
    /// 🔥 SAVE QUA SERVICE (QUAN TRỌNG)
    await UserService.instance.saveAvatar(selectedAvatar);
    await UserService.instance.saveGender(gender);

    await user?.updateDisplayName(nameController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cập nhật thành công")),
    );

    Navigator.pop(context, true);
  }
}