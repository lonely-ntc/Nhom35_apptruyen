import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experience_model.dart';

class ExperienceService extends ChangeNotifier {
  static final ExperienceService instance = ExperienceService._();
  ExperienceService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 ADD EXP
  Future<void> addExp(String userId, int amount, String reason) async {
    try {
      final userRef = _db.collection('users').doc(userId);
      final doc = await userRef.get();
      
      final currentExp = doc.data()?['exp'] ?? 0;
      final newExp = currentExp + amount;
      
      await userRef.update({'exp': newExp});
      
      // Log exp history
      await userRef.collection('exp_history').add({
        'amount': amount,
        'reason': reason,
        'timestamp': Timestamp.now(),
        'totalExp': newExp,
      });
      
      notifyListeners();
    } catch (e) {
      print('❌ addExp error: $e');
    }
  }

  /// 🔥 GET EXP
  Future<int> getExp(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data()?['exp'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// 🔥 GET EXPERIENCE MODEL
  Future<ExperienceModel> getExperienceModel(String userId) async {
    final exp = await getExp(userId);
    return ExperienceModel.fromExp(exp);
  }

  /// 🔥 STREAM EXP
  Stream<int> streamExp(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['exp'] ?? 0);
  }

  /// 🔥 EXP ACTIONS
  
  // Đọc truyện: +100 exp/10 phút
  Future<void> addReadingExp(String userId, int minutes) async {
    // Chỉ tính EXP cho mỗi 10 phút đọc
    final tenMinuteBlocks = minutes ~/ 10;
    if (tenMinuteBlocks > 0) {
      await addExp(userId, tenMinuteBlocks * 100, 'Đọc truyện ${tenMinuteBlocks * 10} phút');
    }
  }

  // Mua truyện: +1000 exp
  Future<void> addPurchaseExp(String userId, String storyTitle) async {
    await addExp(userId, 1000, 'Mua truyện: $storyTitle');
  }

  // Comment: +5 exp
  Future<void> addCommentExp(String userId) async {
    await addExp(userId, 5, 'Bình luận');
  }

  // Rating: +10 exp
  Future<void> addRatingExp(String userId) async {
    await addExp(userId, 10, 'Đánh giá truyện');
  }

  // Đăng nhập hàng ngày: +20 exp
  Future<void> addDailyLoginExp(String userId) async {
    await addExp(userId, 20, 'Đăng nhập hàng ngày');
  }
}
