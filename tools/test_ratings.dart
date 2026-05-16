import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🧪 TEST SCRIPT - Kiểm tra dữ liệu ratings trong Firestore
/// 
/// Chạy script này để xem tất cả ratings đã được lưu trong Firestore
/// 
/// Usage:
/// dart run tools/test_ratings.dart

void main() async {
  print('🔍 Testing Firestore Ratings...\n');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized\n');

    final firestore = FirebaseFirestore.instance;

    // Lấy tất cả stories
    print('📚 Fetching all stories...');
    final storiesSnapshot = await firestore.collection('stories').get();
    
    print('Found ${storiesSnapshot.docs.length} story documents\n');

    if (storiesSnapshot.docs.isEmpty) {
      print('⚠️ No story documents found in Firestore');
      print('💡 Ratings are stored in: stories/{storyId}/ratings/{userId}');
      return;
    }

    // Kiểm tra ratings cho mỗi story
    int totalStoriesWithRatings = 0;
    int totalRatings = 0;

    for (var storyDoc in storiesSnapshot.docs) {
      final storyId = storyDoc.id;
      
      // Lấy ratings cho story này
      final ratingsSnapshot = await firestore
          .collection('stories')
          .doc(storyId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        totalStoriesWithRatings++;
        totalRatings += ratingsSnapshot.docs.length;

        print('📖 Story: "$storyId"');
        print('   Ratings: ${ratingsSnapshot.docs.length}');

        // Tính average
        int totalRating = 0;
        for (var ratingDoc in ratingsSnapshot.docs) {
          final rating = ratingDoc.data()['rating'] as int? ?? 0;
          totalRating += rating;
          print('   - User ${ratingDoc.id}: $rating ⭐');
        }

        final average = totalRating / ratingsSnapshot.docs.length;
        print('   Average: ${average.toStringAsFixed(2)} ⭐');
        print('');
      }
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 SUMMARY:');
    print('   Total stories: ${storiesSnapshot.docs.length}');
    print('   Stories with ratings: $totalStoriesWithRatings');
    print('   Total ratings: $totalRatings');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (totalRatings == 0) {
      print('\n⚠️ NO RATINGS FOUND!');
      print('💡 Make sure users have rated stories in the app');
      print('💡 Ratings should be saved to: stories/{storyId}/ratings/{userId}');
    }

  } catch (e) {
    print('❌ Error: $e');
  }
}
