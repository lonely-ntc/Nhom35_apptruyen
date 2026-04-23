import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= USER =================

  Future<void> createUser({
    required String uid,
    required String email,
    required bool isAdmin,
  }) async {
    await _db.collection("users").doc(uid).set({
      "email": email,
      "isAdmin": isAdmin,
      "wishlist": [],
      "purchased": [],
      "readingProgress": {},
    });
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _db.collection("users").doc(uid).get();
  }

  Future<void> updateUserAdmin(String uid, bool isAdmin) async {
    await _db.collection("users").doc(uid).update({
      "isAdmin": isAdmin,
    });
  }

  Future<List<QueryDocumentSnapshot>> getAllUsers() async {
    final snapshot = await _db.collection("users").get();
    return snapshot.docs;
  }
}