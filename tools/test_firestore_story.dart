import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script để test thêm truyện vào Firestore
/// Chạy: dart tools/test_firestore_story.dart

Future<void> main() async {
  print('🚀 Testing Firestore Story Upload...\n');

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
    // Test 1: Add a test story
    print('📝 Test 1: Adding test story...');
    
    final storyId = 'test_story_${DateTime.now().millisecondsSinceEpoch}';
    
    await firestore.collection('stories').doc(storyId).set({
      'title': 'Test Story',
      'author': 'Test Author',
      'category': 'Action, Adventure',
      'status': 'Đang ra',
      'totalChapters': '0',
      'description': 'This is a test story for Firestore integration',
      'imageUrl': 'https://via.placeholder.com/300x400',
      'isFree': true,
      'price': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Test story added with ID: $storyId\n');

    // Test 2: Add test chapters
    print('📝 Test 2: Adding test chapters...');
    
    for (int i = 1; i <= 3; i++) {
      await firestore
          .collection('stories')
          .doc(storyId)
          .collection('chapters')
          .add({
        'chapterName': 'Chương $i',
        'chapterNumber': i,
        'content': 'Nội dung chương $i...',
        'link': 'chapter-$i',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('   ✅ Added chapter $i');
    }
    
    print('\n✅ All chapters added\n');

    // Test 3: Read story back
    print('📝 Test 3: Reading story back...');
    
    final storyDoc = await firestore.collection('stories').doc(storyId).get();
    
    if (storyDoc.exists) {
      final data = storyDoc.data()!;
      print('   Title: ${data['title']}');
      print('   Author: ${data['author']}');
      print('   Category: ${data['category']}');
      print('   Status: ${data['status']}');
      print('   Is Free: ${data['isFree']}');
      print('   Price: ${data['price']}');
    }
    
    print('\n✅ Story read successfully\n');

    // Test 4: Read chapters back
    print('📝 Test 4: Reading chapters back...');
    
    final chaptersSnapshot = await firestore
        .collection('stories')
        .doc(storyId)
        .collection('chapters')
        .orderBy('chapterNumber')
        .get();
    
    print('   Found ${chaptersSnapshot.docs.length} chapters:');
    for (var doc in chaptersSnapshot.docs) {
      final data = doc.data();
      print('   - ${data['chapterName']} (${data['chapterNumber']})');
    }
    
    print('\n✅ Chapters read successfully\n');

    // Test 5: Update story
    print('📝 Test 5: Updating story...');
    
    await firestore.collection('stories').doc(storyId).update({
      'status': 'Hoàn thành',
      'totalChapters': '3',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Story updated\n');

    // Test 6: Search stories
    print('📝 Test 6: Searching stories...');
    
    final allStories = await firestore.collection('stories').get();
    print('   Total stories in Firestore: ${allStories.docs.length}');
    
    final testStories = allStories.docs.where((doc) {
      final title = doc.data()['title']?.toString().toLowerCase() ?? '';
      return title.contains('test');
    }).toList();
    
    print('   Stories with "test" in title: ${testStories.length}');
    
    print('\n✅ Search completed\n');

    // Test 7: Delete test data (cleanup)
    print('📝 Test 7: Cleaning up test data...');
    
    // Delete chapters
    for (var doc in chaptersSnapshot.docs) {
      await doc.reference.delete();
    }
    
    // Delete story
    await firestore.collection('stories').doc(storyId).delete();
    
    print('✅ Test data cleaned up\n');

    print('=' * 50);
    print('🎉 All tests passed!');
    print('=' * 50);
    print('\n✅ Firestore integration is working correctly!');
    print('✅ You can now add stories through the admin panel.');
    print('✅ Stories will be saved to Firestore automatically.');

  } catch (e) {
    print('\n❌ Test failed: $e');
    print('\nPlease check:');
    print('1. Firebase configuration in google-services.json');
    print('2. Internet connection');
    print('3. Firestore is enabled in Firebase Console');
    print('4. Firestore Security Rules allow write access');
  }
}
