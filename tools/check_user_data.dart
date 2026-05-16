import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script để check dữ liệu user trên Firestore
/// Chạy: dart tools/check_user_data.dart YOUR_USER_ID

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: dart tools/check_user_data.dart YOUR_USER_ID');
    return;
  }

  final userId = args[0];
  
  print('🔍 Checking Firestore data for user: $userId\n');

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBss02_ZJSBzJAo-qSD6C0n-n4uNX8zDTU",
      authDomain: "manga-e245c.firebaseapp.com",
      projectId: "manga-e245c",
      storageBucket: "manga-e245c.firebasestorage.app",
      messagingSenderId: "455786635149",
      appId: "1:455786635149:web:YOUR_WEB_APP_ID",
    ),
  );

  final firestore = FirebaseFirestore.instance;

  try {
    // 1. Check wishlist
    print('❤️ WISHLIST:');
    final wishlistSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .get();
    
    print('   Total: ${wishlistSnapshot.docs.length} items');
    for (var doc in wishlistSnapshot.docs) {
      print('   - Doc ID: "${doc.id}"');
      print('     Data: ${doc.data()}');
    }
    print('');

    // 2. Check purchased
    print('🛒 PURCHASED:');
    final purchasedSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('purchased')
        .get();
    
    print('   Total: ${purchasedSnapshot.docs.length} items');
    for (var doc in purchasedSnapshot.docs) {
      print('   - Doc ID: "${doc.id}"');
      print('     Data: ${doc.data()}');
    }
    print('');

    // 3. Check reading_progress
    print('📖 READING PROGRESS:');
    final readingSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('reading_progress')
        .get();
    
    print('   Total: ${readingSnapshot.docs.length} items');
    for (var doc in readingSnapshot.docs) {
      print('   - Doc ID: "${doc.id}"');
      print('     Data: ${doc.data()}');
    }
    print('');

    // 4. Check stories collection (first 10)
    print('📚 STORIES (first 10):');
    final storiesSnapshot = await firestore
        .collection('stories')
        .limit(10)
        .get();
    
    print('   Total: ${storiesSnapshot.docs.length}+ stories');
    for (var doc in storiesSnapshot.docs) {
      final data = doc.data();
      print('   - Doc ID: "${doc.id}"');
      print('     Title: "${data['title']}"');
    }
    print('');

    // 5. Compare IDs
    print('🔍 COMPARISON:');
    if (wishlistSnapshot.docs.isNotEmpty && storiesSnapshot.docs.isNotEmpty) {
      final wishlistId = wishlistSnapshot.docs.first.id;
      final storyId = storiesSnapshot.docs.first.id;
      final storyTitle = storiesSnapshot.docs.first.data()['title'];
      
      print('   Wishlist Doc ID format: "$wishlistId"');
      print('   Story Doc ID format: "$storyId"');
      print('   Story Title format: "$storyTitle"');
      print('');
      print('   Match? ${wishlistId == storyId || wishlistId == storyTitle}');
    }

  } catch (e) {
    print('❌ Error: $e');
  }
}
