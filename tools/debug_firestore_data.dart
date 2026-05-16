import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script để debug dữ liệu Firestore
/// Chạy: dart tools/debug_firestore_data.dart YOUR_USER_ID

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: dart tools/debug_firestore_data.dart YOUR_USER_ID');
    print('Example: dart tools/debug_firestore_data.dart abc123xyz');
    return;
  }

  final userId = args[0];
  
  print('🔍 Debugging Firestore data for user: $userId\n');

  // Initialize Firebase
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
    // 1. Check user document
    print('📄 Checking user document...');
    final userDoc = await firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      print('❌ User document not found!');
      return;
    }
    
    final userData = userDoc.data()!;
    print('✅ User document exists');
    print('   Email: ${userData['email']}');
    print('   IsAdmin: ${userData['isAdmin']}');
    
    // Check old structure (arrays)
    if (userData.containsKey('wishlist')) {
      final wishlist = userData['wishlist'];
      print('   Wishlist (array): ${wishlist is List ? wishlist.length : 0} items');
      if (wishlist is List && wishlist.isNotEmpty) {
        print('   First 3: ${wishlist.take(3).toList()}');
      }
    }
    
    if (userData.containsKey('purchased')) {
      final purchased = userData['purchased'];
      print('   Purchased (array): ${purchased is List ? purchased.length : 0} items');
      if (purchased is List && purchased.isNotEmpty) {
        print('   First 3: ${purchased.take(3).toList()}');
      }
    }
    
    if (userData.containsKey('readingProgress')) {
      final reading = userData['readingProgress'];
      print('   Reading (map): ${reading is Map ? reading.length : 0} items');
      if (reading is Map && reading.isNotEmpty) {
        final first3 = reading.entries.take(3).map((e) => '${e.key}: ${e.value}').toList();
        print('   First 3: $first3');
      }
    }
    
    print('');

    // 2. Check wishlist subcollection
    print('❤️ Checking wishlist subcollection...');
    final wishlistSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .get();
    
    print('   Found ${wishlistSnapshot.docs.length} items');
    if (wishlistSnapshot.docs.isNotEmpty) {
      print('   Documents:');
      for (var doc in wishlistSnapshot.docs.take(5)) {
        final data = doc.data();
        print('   - ID: ${doc.id}');
        print('     Data: $data');
      }
    }
    print('');

    // 3. Check purchased subcollection
    print('🛒 Checking purchased subcollection...');
    final purchasedSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('purchased')
        .get();
    
    print('   Found ${purchasedSnapshot.docs.length} items');
    if (purchasedSnapshot.docs.isNotEmpty) {
      print('   Documents:');
      for (var doc in purchasedSnapshot.docs.take(5)) {
        final data = doc.data();
        print('   - ID: ${doc.id}');
        print('     Data: $data');
      }
    }
    print('');

    // 4. Check reading_progress subcollection
    print('📖 Checking reading_progress subcollection...');
    final readingSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('reading_progress')
        .get();
    
    print('   Found ${readingSnapshot.docs.length} items');
    if (readingSnapshot.docs.isNotEmpty) {
      print('   Documents:');
      for (var doc in readingSnapshot.docs.take(5)) {
        final data = doc.data();
        print('   - ID: ${doc.id}');
        print('     Data: $data');
      }
    }
    print('');

    // 5. Check stories collection
    print('📚 Checking stories collection...');
    final storiesSnapshot = await firestore
        .collection('stories')
        .limit(5)
        .get();
    
    print('   Found ${storiesSnapshot.docs.length} stories (showing first 5)');
    if (storiesSnapshot.docs.isNotEmpty) {
      print('   Stories:');
      for (var doc in storiesSnapshot.docs) {
        final data = doc.data();
        print('   - ID: ${doc.id}');
        print('     Title: ${data['title']}');
        print('     Author: ${data['author']}');
        print('     ImageUrl: ${data['imageUrl']}');
      }
    }
    print('');

    // Summary
    print('=' * 60);
    print('📊 SUMMARY');
    print('=' * 60);
    print('User Document:');
    print('  - Wishlist (array): ${userData.containsKey('wishlist') && userData['wishlist'] is List ? (userData['wishlist'] as List).length : 0}');
    print('  - Purchased (array): ${userData.containsKey('purchased') && userData['purchased'] is List ? (userData['purchased'] as List).length : 0}');
    print('  - Reading (map): ${userData.containsKey('readingProgress') && userData['readingProgress'] is Map ? (userData['readingProgress'] as Map).length : 0}');
    print('');
    print('Subcollections:');
    print('  - Wishlist: ${wishlistSnapshot.docs.length}');
    print('  - Purchased: ${purchasedSnapshot.docs.length}');
    print('  - Reading Progress: ${readingSnapshot.docs.length}');
    print('');
    print('Stories Collection: ${storiesSnapshot.docs.length}+ stories');
    print('=' * 60);

    // Recommendations
    print('');
    print('💡 RECOMMENDATIONS:');
    if (wishlistSnapshot.docs.isEmpty && userData.containsKey('wishlist') && (userData['wishlist'] as List).isNotEmpty) {
      print('⚠️ Wishlist data is in old format (array)');
      print('   Consider migrating to subcollection');
    }
    if (purchasedSnapshot.docs.isEmpty && userData.containsKey('purchased') && (userData['purchased'] as List).isNotEmpty) {
      print('⚠️ Purchased data is in old format (array)');
      print('   Consider migrating to subcollection');
    }
    if (readingSnapshot.docs.isEmpty && userData.containsKey('readingProgress') && (userData['readingProgress'] as Map).isNotEmpty) {
      print('⚠️ Reading progress is in old format (map)');
      print('   Consider migrating to subcollection');
    }

  } catch (e) {
    print('❌ Error: $e');
  }
}
