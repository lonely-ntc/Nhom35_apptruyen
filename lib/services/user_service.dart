import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final bool isAdmin;

  List<String> wishlist;
  List<String> purchased;
  Map<String, int> readingProgress;

  AppUser({
    required this.uid,
    required this.email,
    required this.isAdmin,
    required this.wishlist,
    required this.purchased,
    required this.readingProgress,
  });
}

class UserService extends ChangeNotifier {
  UserService._();
  static final instance = UserService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? currentUser;

  /// 🔥 ADMIN TỔNG
  final String superAdminEmail = "admin@gmail.com";

  // ================= AUTH =================

  Future<void> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final doc = await _db.collection("users").doc(uid).get();

    /// 👉 Nếu user chưa tồn tại trong Firestore
    if (!doc.exists) {
      final isAdmin = email == superAdminEmail;

      await _db.collection("users").doc(uid).set({
        "email": email,
        "isAdmin": isAdmin,
        "wishlist": [],
        "purchased": [],
        "readingProgress": {},
      });
    }

    final data =
        (await _db.collection("users").doc(uid).get()).data() as Map<String, dynamic>;

    currentUser = AppUser(
      uid: uid,
      email: data["email"],
      isAdmin: data["isAdmin"] ?? false,
      wishlist: List<String>.from(data["wishlist"] ?? []),
      purchased: List<String>.from(data["purchased"] ?? []),
      readingProgress: Map<String, int>.from(data["readingProgress"] ?? {}),
    );

    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    currentUser = null;
    notifyListeners();
  }

  bool get isLoggedIn => currentUser != null;

  // ================= ADMIN =================

  bool get isAdmin => currentUser?.isAdmin ?? false;

  bool get isSuperAdmin => currentUser?.email == superAdminEmail;

  Future<void> setAdmin(String uid, bool isAdmin) async {
    if (!isSuperAdmin) return;

    await _db.collection("users").doc(uid).update({
      "isAdmin": isAdmin,
    });
  }

  // ================= AVATAR =================

  Future<String> getAvatar() async {
    final user = _auth.currentUser;
    if (user == null) return "assets/avatars/avatar1.png";

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("avatar_${user.uid}") ??
        "assets/avatars/avatar1.png";
  }

  Future<void> saveAvatar(String avatar) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("avatar_${user.uid}", avatar);
  }

  // ================= GENDER =================

  Future<void> saveGender(String gender) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("gender_${user.uid}", gender);
  }

  Future<String> getGender() async {
    final user = _auth.currentUser;
    if (user == null) return "unknown";

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("gender_${user.uid}") ?? "unknown";
  }

  // ================= USER PROFILE (FIRESTORE) =================

  /// Save user profile to Firestore
  Future<void> saveUserProfile({
    required String displayName,
    required String avatar,
    required String gender,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection("users").doc(user.uid).set({
      "displayName": displayName,
      "avatar": avatar,
      "gender": gender,
      "email": user.email,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection("users").doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ getUserProfile error: $e');
      return null;
    }
  }

  /// Get display name from Firestore (for comments)
  Future<String> getDisplayName(String uid) async {
    try {
      final profile = await getUserProfile(uid);
      return profile?['displayName'] ?? "Người dùng";
    } catch (e) {
      debugPrint('❌ getDisplayName error: $e');
      return "Người dùng";
    }
  }

  // ================= WISHLIST =================

  Future<void> toggleWishlist(String storyId) async {
    if (currentUser == null) return;

    if (currentUser!.wishlist.contains(storyId)) {
      currentUser!.wishlist.remove(storyId);
    } else {
      currentUser!.wishlist.add(storyId);
    }

    await _db.collection("users").doc(currentUser!.uid).update({
      "wishlist": currentUser!.wishlist,
    });

    notifyListeners();
  }

  bool isInWishlist(String storyId) {
    if (currentUser == null) return false;
    return currentUser!.wishlist.contains(storyId);
  }

  // ================= PURCHASE =================

  Future<void> purchaseStory(String storyId) async {
    if (currentUser == null) return;

    if (!currentUser!.purchased.contains(storyId)) {
      currentUser!.purchased.add(storyId);

      await _db.collection("users").doc(currentUser!.uid).update({
        "purchased": currentUser!.purchased,
      });

      notifyListeners();
    }
  }

  bool isPurchased(String storyId) {
    if (currentUser == null) return false;
    return currentUser!.purchased.contains(storyId);
  }

  // ================= READING PROGRESS =================

  Future<void> saveReadingProgress(String storyId, int chapterIndex) async {
    if (currentUser == null) return;

    currentUser!.readingProgress[storyId] = chapterIndex;

    await _db.collection("users").doc(currentUser!.uid).update({
      "readingProgress": currentUser!.readingProgress,
    });

    notifyListeners();
  }

  int getReadingProgress(String storyId) {
    if (currentUser == null) return 0;
    return currentUser!.readingProgress[storyId] ?? 0;
  }

  // ================= GET ALL USERS (ADMIN) =================

  Future<List<QueryDocumentSnapshot>> getAllUsers() async {
    final snapshot = await _db.collection("users").get();
    return snapshot.docs;
  }

  // ================= 🔥 GET STATS STREAM =================
  
  /// Stream thống kê thực từ Firebase
  /// - Đã đọc: Số truyện có reading_progress
  /// - Đã mua: Số truyện trong purchased collection
  /// - Yêu thích: Số truyện trong wishlist collection
  Stream<Map<String, int>> getStatsStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().asyncMap((userDoc) async {
      // Get reading progress count
      final readingProgressSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('reading_progress')
          .get();
      final readCount = readingProgressSnapshot.docs.length;

      // Get purchased count
      final purchasedSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('purchased')
          .get();
      final purchasedCount = purchasedSnapshot.docs.length;

      // Get wishlist count
      final wishlistSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();
      final wishlistCount = wishlistSnapshot.docs.length;

      return {
        'read': readCount,
        'purchased': purchasedCount,
        'wishlist': wishlistCount,
      };
    });
  }
}