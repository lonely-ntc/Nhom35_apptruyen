import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/admin_config.dart';

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

  // ================= AUTH =================

  Future<void> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    final doc = await _db.collection("users").doc(uid).get();

    /// 👉 Kiểm tra xem user có phải admin không (từ AdminConfig hoặc Firestore admins collection)
    final isAdminUser = AdminConfig.isAdminEmail(email) || 
                        await _checkAdminFromFirestore(email);

    /// 👉 Nếu user chưa tồn tại trong Firestore
    if (!doc.exists) {
      await _db.collection("users").doc(uid).set({
        "email": email,
        "isAdmin": isAdminUser,
        "wishlist": [],
        "purchased": [],
        "readingProgress": {},
      });
    } else {
      /// 👉 Cập nhật isAdmin nếu đã thay đổi
      final currentData = doc.data() as Map<String, dynamic>;
      if (currentData["isAdmin"] != isAdminUser) {
        await _db.collection("users").doc(uid).update({
          "isAdmin": isAdminUser,
        });
      }
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

  /// 🔥 Kiểm tra admin từ Firestore admins collection
  Future<bool> _checkAdminFromFirestore(String email) async {
    try {
      final doc = await _db.collection('admins').doc(email.toLowerCase().trim()).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking admin from Firestore: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    currentUser = null;
    notifyListeners();
  }

  bool get isLoggedIn => currentUser != null;

  // ================= ADMIN =================

  bool get isAdmin => currentUser?.isAdmin ?? false;

  bool get isSuperAdmin => currentUser != null && AdminConfig.isAdminEmail(currentUser!.email);

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

  // ================= 🔥 GET STATS STREAM (REALTIME) =================

  /// 🔥 Stream thống kê - Lắng nghe realtime từ 3 subcollections
  Stream<Map<String, int>> getStatsStream(String userId) {
    // Merge 3 subcollection streams: emit mỗi khi bất kỳ subcollection nào thay đổi
    final wishlistSnaps = _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots();

    final purchasedSnaps = _db
        .collection('users')
        .doc(userId)
        .collection('purchased')
        .snapshots();

    final readingSnaps = _db
        .collection('users')
        .doc(userId)
        .collection('reading_progress')
        .snapshots();

    // Dùng async* để merge 3 streams
    return _mergeStatsStreams(userId, wishlistSnaps, purchasedSnaps, readingSnaps);
  }

  Stream<Map<String, int>> _mergeStatsStreams(
    String userId,
    Stream wishlistSnaps,
    Stream purchasedSnaps,
    Stream readingSnaps,
  ) {
    // Lắng nghe wishlist stream, mỗi lần có thay đổi thì fetch cả 3
    return wishlistSnaps.asyncMap((_) async {
      try {
        final results = await Future.wait([
          _db.collection('users').doc(userId).collection('wishlist').get(),
          _db.collection('users').doc(userId).collection('purchased').get(),
          _db.collection('users').doc(userId).collection('reading_progress').get(),
        ]);
        return {
          'wishlist': results[0].docs.length,
          'purchased': results[1].docs.length,
          'read': results[2].docs.length,
        };
      } catch (e) {
        debugPrint('❌ Error getting stats: $e');
        return {'read': 0, 'purchased': 0, 'wishlist': 0};
      }
    });
  }
}