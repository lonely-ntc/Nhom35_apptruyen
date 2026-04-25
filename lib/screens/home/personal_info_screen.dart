import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';

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
  bool isLoading = false;

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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Thông tin cá nhân"),
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// ===== HEADER CARD =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPurple,
                    AppColors.primaryPurple.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  /// AVATAR với border gradient
                  GestureDetector(
                    onTap: _showAvatarPicker,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.5),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundImage: AssetImage(selectedAvatar),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Chọn ảnh đại diện",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            /// ===== FORM SECTION =====
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// NAME
                  _buildLabel("Tên hiển thị", theme),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: _inputDecoration(
                      hint: "Nhập tên hiển thị",
                      icon: Icons.person_outline,
                      theme: theme,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// EMAIL
                  _buildLabel("Email", theme),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    readOnly: true,
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    decoration: _inputDecoration(
                      hint: "Email",
                      icon: Icons.email_outlined,
                      theme: theme,
                      enabled: false,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// GENDER
                  _buildLabel("Giới tính", theme),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor,
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: gender,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down,
                          color: theme.iconTheme.color),
                      dropdownColor: theme.cardColor,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 15,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Nam",
                          child: Row(
                            children: [
                              Icon(Icons.male, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text("Nam"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Nữ",
                          child: Row(
                            children: [
                              Icon(Icons.female, size: 20, color: Colors.pink),
                              SizedBox(width: 8),
                              Text("Nữ"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Khác",
                          child: Row(
                            children: [
                              Icon(Icons.transgender,
                                  size: 20, color: Colors.purple),
                              SizedBox(width: 8),
                              Text("Khác"),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          gender = value!;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Lưu thay đổi",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// BUILD LABEL
  Widget _buildLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.textTheme.bodyLarge?.color,
      ),
    );
  }

  /// INPUT DECORATION
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required ThemeData theme,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
      prefixIcon: Icon(icon,
          color: enabled
              ? theme.iconTheme.color
              : theme.textTheme.bodySmall?.color),
      filled: true,
      fillColor: enabled
          ? theme.cardColor
          : theme.cardColor.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  /// PICK AVATAR
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.photo_library,
                        color: AppColors.primaryPurple, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      "Chọn ảnh đại diện",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Avatar grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: avatarList.length,
                  itemBuilder: (_, index) {
                    final avatar = avatarList[index];
                    final isSelected = avatar == selectedAvatar;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAvatar = avatar;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryPurple
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryPurple
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(avatar),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// SAVE
  Future<void> _updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tên hiển thị không được để trống"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final displayName = nameController.text.trim();

      /// 🔥 SAVE TO SHARED PREFERENCES
      await UserService.instance.saveAvatar(selectedAvatar);
      await UserService.instance.saveGender(gender);

      /// 🔥 SAVE TO FIREBASE AUTH
      await user?.updateDisplayName(displayName);

      /// 🔥 SAVE TO FIRESTORE (for comments and other features)
      await UserService.instance.saveUserProfile(
        displayName: displayName,
        avatar: selectedAvatar,
        gender: gender,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Cập nhật thành công"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
