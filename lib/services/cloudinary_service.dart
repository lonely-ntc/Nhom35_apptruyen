import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static final CloudinaryService instance = CloudinaryService._();
  CloudinaryService._();

  // 🔥 CLOUDINARY CONFIG
  // Thay đổi các giá trị này bằng thông tin từ Cloudinary Dashboard
  static const String _cloudName = 'dcco1duqx'; // Ví dụ: 'dxyz123abc'
  static const String _uploadPreset = 'apptruyen_upload'; // Ví dụ: 'story_images'
  
  late final CloudinaryPublic _cloudinary;

  /// Initialize Cloudinary
  void init() {
    _cloudinary = CloudinaryPublic(
      _cloudName,
      _uploadPreset,
      cache: false,
    );
  }

  /// 🔥 UPLOAD IMAGE TO CLOUDINARY
  /// Returns: URL của ảnh đã upload
  Future<String?> uploadStoryImage({
    required File imageFile,
    required String storyTitle,
    required String category,
  }) async {
    try {
      debugPrint('🔄 Uploading image to Cloudinary...');

      // Tạo public_id từ tên truyện và thể loại
      final publicId = _generatePublicId(storyTitle, category);
      
      // Upload image
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'story_images/$category', // Tổ chức theo thể loại
          publicId: publicId,
        ),
      );

      final imageUrl = response.secureUrl;
      debugPrint('✅ Image uploaded successfully: $imageUrl');
      
      return imageUrl;
    } catch (e) {
      debugPrint('❌ Cloudinary upload error: $e');
      return null;
    }
  }

  /// 🔥 UPLOAD MULTIPLE IMAGES (for chapters)
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String storyTitle,
    String folder = 'story_chapters',
  }) async {
    final urls = <String>[];

    for (var i = 0; i < imageFiles.length; i++) {
      try {
        final publicId = '${_generatePublicId(storyTitle, '')}_chapter_${i + 1}';
        
        final response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFiles[i].path,
            resourceType: CloudinaryResourceType.Image,
            folder: folder,
            publicId: publicId,
          ),
        );

        urls.add(response.secureUrl);
        debugPrint('✅ Uploaded ${i + 1}/${imageFiles.length}');
      } catch (e) {
        debugPrint('❌ Error uploading image ${i + 1}: $e');
      }
    }

    return urls;
  }

  /// 🔥 DELETE IMAGE FROM CLOUDINARY
  Future<bool> deleteImage(String publicId) async {
    try {
      // Note: Deletion requires API key and secret
      // This is a placeholder - you'll need to implement server-side deletion
      // or use Cloudinary Admin API
      debugPrint('⚠️ Delete image: $publicId');
      debugPrint('⚠️ Deletion requires server-side implementation');
      return true;
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      return false;
    }
  }

  /// 🔥 GENERATE PUBLIC ID
  /// Tạo ID duy nhất từ tên truyện và thể loại
  String _generatePublicId(String storyTitle, String category) {
    final normalized = _normalize(storyTitle);
    final categoryNormalized = category.isNotEmpty ? _normalize(category) : '';
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    if (categoryNormalized.isNotEmpty) {
      return '${categoryNormalized}_${normalized}_$timestamp';
    }
    
    return '${normalized}_$timestamp';
  }

  /// 🔥 NORMALIZE TEXT
  String _normalize(String text) {
    return _removeVietnamese(text)
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// 🔥 REMOVE VIETNAMESE CHARACTERS
  String _removeVietnamese(String str) {
    const map = {
      'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'đ': 'd',
      'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    };

    String result = str.toLowerCase();
    map.forEach((k, v) {
      result = result.replaceAll(k, v);
    });

    return result;
  }

  /// 🔥 GET IMAGE URL WITH TRANSFORMATIONS
  /// Tạo URL với transformations (resize, crop, etc.)
  String getTransformedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String? crop,
    String? quality,
  }) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (crop != null) transformations.add('c_$crop');
    if (quality != null) transformations.add('q_$quality');

    if (transformations.isEmpty) return originalUrl;

    // Insert transformations into URL
    final parts = originalUrl.split('/upload/');
    if (parts.length == 2) {
      return '${parts[0]}/upload/${transformations.join(',')}/${parts[1]}';
    }

    return originalUrl;
  }

  /// 🔥 VALIDATE CLOUDINARY CONFIG
  bool isConfigured() {
    return _cloudName != 'YOUR_CLOUD_NAME' && 
           _uploadPreset != 'YOUR_UPLOAD_PRESET';
  }
}
