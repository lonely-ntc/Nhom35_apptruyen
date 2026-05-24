import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 NOTIFICATION TYPES
  static const String TYPE_NEW_STORY = 'new_story';
  static const String TYPE_NEW_CHAPTER = 'new_chapter';
  static const String TYPE_PURCHASE = 'purchase';
  static const String TYPE_TOPUP_SUCCESS = 'topup_success';
  static const String TYPE_TOPUP_FAILED = 'topup_failed';

  /// 🔥 ADD NOTIFICATION
  Future<void> addNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? storyTitle,
    String? chapterTitle,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': type,
        'title': title,
        'message': message,
        'storyTitle': storyTitle,
        'chapterTitle': chapterTitle,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      print('✅ Notification added: $title');
    } catch (e) {
      print('❌ addNotification error: $e');
    }
  }

  /// 🔥 ADD NEW STORY NOTIFICATION (FOR ALL USERS)
  Future<void> notifyNewStory({
    required String storyTitle,
    required String author,
    required String category,
  }) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      // Add notification for each user
      for (var userDoc in usersSnapshot.docs) {
        await addNotification(
          userId: userDoc.id,
          type: TYPE_NEW_STORY,
          title: '📚 Truyện mới: $storyTitle',
          message: 'Tác giả: $author • Thể loại: $category',
          storyTitle: storyTitle,
        );
      }

      print('✅ New story notification sent to ${usersSnapshot.docs.length} users');
    } catch (e) {
      print('❌ notifyNewStory error: $e');
    }
  }

  /// 🔥 ADD NEW CHAPTER NOTIFICATION (FOR FOLLOWERS)
  Future<void> notifyNewChapter({
    required String storyTitle,
    required String chapterTitle,
  }) async {
    try {
      // Get all users who have this story in wishlist or purchased
      final usersSnapshot = await _firestore.collection('users').get();

      int notifiedCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        // Check if user has story in wishlist
        final wishlistDoc = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('wishlist')
            .doc(storyTitle)
            .get();

        // Check if user purchased the story
        final purchasedDoc = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('purchased')
            .doc(storyTitle)
            .get();

        // If user follows or purchased, send notification
        if (wishlistDoc.exists || purchasedDoc.exists) {
          await addNotification(
            userId: userDoc.id,
            type: TYPE_NEW_CHAPTER,
            title: '📖 Chương mới: $chapterTitle',
            message: 'Truyện: $storyTitle',
            storyTitle: storyTitle,
            chapterTitle: chapterTitle,
          );
          notifiedCount++;
        }
      }

      print('✅ New chapter notification sent to $notifiedCount users');
    } catch (e) {
      print('❌ notifyNewChapter error: $e');
    }
  }

  /// 🔥 ADD PURCHASE NOTIFICATION
  Future<void> notifyPurchase({
    required String userId,
    required String storyTitle,
    required double price,
  }) async {
    try {
      await addNotification(
        userId: userId,
        type: TYPE_PURCHASE,
        title: '✅ Mua truyện thành công',
        message: 'Bạn đã mua "$storyTitle" với giá ${price.toStringAsFixed(0)} xu',
        storyTitle: storyTitle,
      );
    } catch (e) {
      print('❌ notifyPurchase error: $e');
    }
  }

  /// 🔥 ADD TOPUP SUCCESS NOTIFICATION
  Future<void> notifyTopupSuccess({
    required String userId,
    required int totalCoin,
    required int amountVnd,
    int bonusCoin = 0,
  }) async {
    try {
      final bonusText =
          bonusCoin > 0 ? ' (bao gồm $bonusCoin xu thưởng)' : '';

      await addNotification(
        userId: userId,
        type: TYPE_TOPUP_SUCCESS,
        title: '💰 Nạp xu thành công',
        message:
            'Tài khoản của bạn đã được cộng $totalCoin xu$bonusText từ giao dịch ${amountVnd.toString()}đ.',
      );
    } catch (e) {
      print('❌ notifyTopupSuccess error: $e');
    }
  }

  /// 🔥 ADD TOPUP FAILED NOTIFICATION
  Future<void> notifyTopupFailed({
    required String userId,
    required int totalCoin,
    required int amountVnd,
    String reason = 'Admin chưa nhận được tiền chuyển khoản',
  }) async {
    try {
      await addNotification(
        userId: userId,
        type: TYPE_TOPUP_FAILED,
        title: '❌ Nạp xu thất bại',
        message:
            'Yêu cầu nạp $totalCoin xu (${amountVnd.toString()}đ) đã bị từ chối. Lý do: $reason.',
      );
    } catch (e) {
      print('❌ notifyTopupFailed error: $e');
    }
  }

  /// 🔥 GET NOTIFICATIONS STREAM
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// 🔥 MARK AS READ
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ markAsRead error: $e');
    }
  }

  /// 🔥 MARK ALL AS READ
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }

      print('✅ Marked ${snapshot.docs.length} notifications as read');
    } catch (e) {
      print('❌ markAllAsRead error: $e');
    }
  }

  /// 🔥 GET UNREAD COUNT
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 🔥 DELETE NOTIFICATION
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ deleteNotification error: $e');
    }
  }
}
