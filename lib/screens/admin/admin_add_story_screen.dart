import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../services/story_management_service.dart';
import '../../services/notification_service.dart';
import '../../data/category_data.dart';
import '../../widgets/custom_button.dart';

class AdminAddStoryScreen extends StatefulWidget {
  const AdminAddStoryScreen({super.key});

  @override
  State<AdminAddStoryScreen> createState() => _AdminAddStoryScreenState();
}

class _AdminAddStoryScreenState extends State<AdminAddStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storyService = StoryManagementService.instance;

  // Controllers
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Dropdowns
  List<String> _selectedCategories = [];
  String _selectedStatus = 'Đang ra';
  bool _isFree = true;
  double _price = 0.0;

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 🔥 PICK IMAGE FROM DEVICE
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  Future<void> _saveStory() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate categories
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng chọn ít nhất một thể loại!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate image
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng chọn ảnh truyện!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tạo image path từ tên truyện
      final storyTitle = _titleController.text.trim();
      final primaryCategory = _selectedCategories.first;
      final categoryFolder = _normalizeCategory(primaryCategory);
      final imageName = _normalizeImageName(storyTitle);
      final categoryString = _selectedCategories.join(', ');
      
      // Copy image to assets folder
      final targetPath = 'assets/database/images/$categoryFolder/$imageName.jpg';
      final targetDir = Directory('assets/database/images/$categoryFolder');
      
      // Create directory if not exists
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      // Copy file
      final targetFile = File(targetPath);
      await _selectedImage!.copy(targetFile.path);
      
      final imagePath = 'images/$categoryFolder/$imageName.jpg';

      final success = await _storyService.addStory(
        title: storyTitle,
        author: _authorController.text.trim(),
        category: categoryString,
        status: _selectedStatus,
        totalChapters: '0',
        description: _descriptionController.text.trim(),
        imagePath: imagePath,
        isFree: _isFree,
        price: _price,
      );

      if (!mounted) return;

      if (success) {
        // 🔥 SEND NOTIFICATION TO ALL USERS
        await NotificationService.instance.notifyNewStory(
          storyTitle: storyTitle,
          author: _authorController.text.trim(),
          category: categoryString,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Thêm truyện thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Thêm truyện thất bại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  String _normalizeImageName(String title) {
    return title
        .toLowerCase()
        .replaceAll('đ', 'd')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('ắ', 'a')
        .replaceAll('ằ', 'a')
        .replaceAll('ẳ', 'a')
        .replaceAll('ẵ', 'a')
        .replaceAll('ặ', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ấ', 'a')
        .replaceAll('ầ', 'a')
        .replaceAll('ẩ', 'a')
        .replaceAll('ẫ', 'a')
        .replaceAll('ậ', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ẻ', 'e')
        .replaceAll('ẽ', 'e')
        .replaceAll('ẹ', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ế', 'e')
        .replaceAll('ề', 'e')
        .replaceAll('ể', 'e')
        .replaceAll('ễ', 'e')
        .replaceAll('ệ', 'e')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ỏ', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ọ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ố', 'o')
        .replaceAll('ồ', 'o')
        .replaceAll('ổ', 'o')
        .replaceAll('ỗ', 'o')
        .replaceAll('ộ', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ớ', 'o')
        .replaceAll('ờ', 'o')
        .replaceAll('ở', 'o')
        .replaceAll('ỡ', 'o')
        .replaceAll('ợ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ủ', 'u')
        .replaceAll('ũ', 'u')
        .replaceAll('ụ', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ứ', 'u')
        .replaceAll('ừ', 'u')
        .replaceAll('ử', 'u')
        .replaceAll('ữ', 'u')
        .replaceAll('ự', 'u')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ỉ', 'i')
        .replaceAll('ĩ', 'i')
        .replaceAll('ị', 'i')
        .replaceAll('ý', 'y')
        .replaceAll('ỳ', 'y')
        .replaceAll('ỷ', 'y')
        .replaceAll('ỹ', 'y')
        .replaceAll('ỵ', 'y')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w]'), '');
  }

  String _normalizeCategory(String category) {
    return category
        .toLowerCase()
        .replaceAll('đ', 'd')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ý', 'y')
        .replaceAll('ỳ', 'y')
        .replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thêm truyện mới'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.white, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thêm truyện mới',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Điền đầy đủ thông tin bên dưới',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// TÊN TRUYỆN
              _buildLabel('Tên truyện *', theme),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: _inputDecoration('Nhập tên truyện', theme),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên truyện';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// TÁC GIẢ
              _buildLabel('Tác giả *', theme),
              TextFormField(
                controller: _authorController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: _inputDecoration('Nhập tên tác giả', theme),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên tác giả';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// THỂ LOẠI & TRẠNG THÁI
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Thể loại *', theme),
                        GestureDetector(
                          onTap: () => _showCategoryPicker(theme),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _selectedCategories.isEmpty
                                      ? Text(
                                          'Chọn thể loại',
                                          style: TextStyle(
                                            color: theme.textTheme.bodySmall?.color,
                                          ),
                                        )
                                      : Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: _selectedCategories
                                              .map(
                                                (cat) => Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: theme.colorScheme.primary
                                                          .withOpacity(0.4),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    cat,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: theme.colorScheme.primary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Trạng thái *', theme),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          dropdownColor: theme.cardColor,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          decoration: _inputDecoration('', theme),
                          items: ['Đang ra', 'Hoàn thành', 'Tạm dừng'].map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStatus = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// MÔ TẢ
              _buildLabel('Mô tả', theme),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: _inputDecoration('Nhập mô tả truyện', theme),
                maxLines: 5,
              ),

              const SizedBox(height: 16),

              /// CHỌN ẢNH
              _buildLabel('Ảnh truyện *', theme),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedImage == null
                          ? theme.dividerColor
                          : theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 60,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Nhấn để chọn ảnh',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Khuyến nghị: 600x800px',
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.red,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              /// GIÁ
              _buildLabel('Giá truyện', theme),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Truyện miễn phí',
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      ),
                      value: _isFree,
                      onChanged: (value) {
                        setState(() => _isFree = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!_isFree) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _price.toString(),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        decoration: _inputDecoration('Nhập giá (VND)', theme),
                        onChanged: (value) {
                          _price = double.tryParse(value) ?? 0.0;
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Thêm truyện',
                      onPressed: _saveStory,
                      isLoading: _isLoading,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker(ThemeData theme) {
    final tempSelected = List<String>.from(_selectedCategories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Chọn thể loại',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const Spacer(),
                          if (tempSelected.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${tempSelected.length} đã chọn',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = tempSelected.contains(cat);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(
                              cat,
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            activeColor: theme.colorScheme.primary,
                            checkColor: Colors.white,
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  tempSelected.add(cat);
                                } else {
                                  tempSelected.remove(cat);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: theme.dividerColor),
                              ),
                              child: Text(
                                'Hủy',
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategories = List.from(tempSelected);
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Xác nhận',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, ThemeData theme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
