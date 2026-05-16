import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../utils/image_helper.dart';

/// 🚀 IMAGE CACHE SERVICE
/// Pre-load và cache images để tăng performance
class ImageCacheService {
  static final ImageCacheService instance = ImageCacheService._init();
  ImageCacheService._init();

  final Map<String, ImageProvider> _imageCache = {};
  bool _isPreloading = false;

  /// 🔥 PRE-LOAD IMAGES cho danh sách stories
  /// Chỉ pre-load 10 ảnh đầu tiên để không tốn quá nhiều memory
  Future<void> preloadStoryImages(
    BuildContext context,
    List<Story> stories, {
    int limit = 10,
  }) async {
    if (_isPreloading) return;
    _isPreloading = true;

    try {
      final storiesToPreload = stories.take(limit).toList();
      print('🖼️ Pre-loading ${storiesToPreload.length} images...');

      for (var story in storiesToPreload) {
        try {
          final imagePath = await ImageHelper.getImageFromStory(
            title: story.title,
            category: story.category,
            pathFromDb: story.image,
          );

          if (_imageCache.containsKey(story.title)) continue;

          final imageProvider = ImageHelper.isNetwork(imagePath)
              ? NetworkImage(imagePath)
              : AssetImage(imagePath) as ImageProvider;

          // Pre-cache image
          await precacheImage(imageProvider, context);
          _imageCache[story.title] = imageProvider;

          print('✅ Cached: ${story.title}');
        } catch (e) {
          print('⚠️ Failed to cache ${story.title}: $e');
        }
      }

      print('✅ Pre-loaded ${_imageCache.length} images');
    } catch (e) {
      print('❌ preloadStoryImages error: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// 🔍 GET CACHED IMAGE
  ImageProvider? getCachedImage(String storyTitle) {
    return _imageCache[storyTitle];
  }

  /// 🗑️ CLEAR CACHE
  void clearCache() {
    _imageCache.clear();
    print('🗑️ Image cache cleared');
  }

  /// 📊 GET CACHE SIZE
  int get cacheSize => _imageCache.length;
}
