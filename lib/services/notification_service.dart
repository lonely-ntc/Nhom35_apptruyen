import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 NOTIFICATION TYPES
  static const String TYPE_NEW_STORY = 'new_story';
  static const String TYPE_NEW_CHAPTER = 'new_chapter';
  static const String TYPE_PURCHASE = 'purchase';

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
        message: 'Bạn đã mua "$storyTitle" với giá ${price.toStringAsFixed(0)} đ',
        storyTitle: storyTitle,
      );
    } catch (e) {
      print('❌ notifyPurchase error: $e');
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
