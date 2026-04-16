import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  Future<String> getAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "assets/avatars/avatar1.png";

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("avatar_${user.uid}") ??
        "assets/avatars/avatar1.png";
  }

  Future<void> saveAvatar(String avatar) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("avatar_${user.uid}", avatar);
  }

  Future<void> saveGender(String gender) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("gender_${user.uid}", gender);
  }
}