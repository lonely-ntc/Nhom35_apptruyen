import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/story_model.dart';
import '../../widgets/story_card.dart';
import '../../services/language_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_styles.dart';
import '../../utils/app_text.dart';

class AllStoriesScreen extends StatefulWidget {
  final String category;
  final List<Story> allStories;

  const AllStoriesScreen({
    super.key,
    required this.category,
    required this.allStories,
  });

  @override
  State<AllStoriesScreen> createState() => _AllStoriesScreenState();
}

class _AllStoriesScreenState extends State<AllStoriesScreen> {
  String selectedPriceFilter = 'all';
  List<String> selectedCategories = [];
  
  final List<String> allCategories = [
    "Tiên Hiệp", "Kiếm Hiệp", "Ngôn Tình", "Đam Mỹ", "Bách Hợp",
    "Quan Trường", "Huyền Huyễn", "Khoa Huyễn", "Võng Du", "Đô Thị",
    "Dị Giới", "Dị Năng", "Quân Sự", "Lịch Sử", "Trinh Thám",
    "Linh Dị", "Sắc", "Ngược", "Sủng", "Hài", "Cung Đấu",
    "Trọng Sinh", "Nhanh Xuyên", "Cổ Đại", "Hiện Đại", "Xuyên Không",
    "Hệ Thống", "Tu Tiên", "Huyền Ảo", "Đồng Nhân", "Gia Đấu",
    "Nữ Cường", "Điền Văn", "Học Đường", "Giải Trí"
  ];

  List<Story> get filteredStories {
    var stories = widget.allStories;

    // Filter by price
    if (selectedPriceFilter == 'free') {
      stories = stories.where((s) => s.isFree).toList();
    } else if (selectedPriceFilter == 'paid') {
      stories = stories.where((s) => !s.isFree).toList();
    }

    // Filter by categories
    if (selectedCategories.isNotEmpty) {
      stories = stories.where((story) {
        // Kiểm tra xem thể loại của truyện có chứa bất kỳ thể loại nào được chọn không
        for (final selectedCat in selectedCategories) {
          if (story.category.toLowerCase().contains(selectedCat.toLowerCase())) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    return stories;
  }

  bool get hasActiveFilters {
    return selectedPriceFilter != 'all' || selectedCategories.isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      selectedPriceFilter = 'all';
      selectedCategories.clear();
    });
  }

  void _showCategoryFilter() {
    final lang = context.read<LanguageService>().lang;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == "vi" ? 'Chọn thể loại' : 'Select Categories',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            selectedCategories.clear();
                          });
                          setState(() {});
                        },
                        child: Text(lang == "vi" ? 'Xóa tất cả' : 'Clear all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) {
                        final category = allCategories[index];
                        final isSelected = selectedCategories.contains(category);
                        
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                selectedCategories.remove(category);
                              } else {
                                selectedCategories.add(category);
                              }
                            });
                            setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.purpleGradient : null,
                              color: isSelected ? null : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        lang == "vi" ? 'Áp dụng (${selectedCategories.length})' : 'Apply (${selectedCategories.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageService>().lang;
    final filtered = filteredStories;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              lang == "vi" ? '${filtered.length} truyện' : '${filtered.length} stories',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: lang == "vi" ? 'Xóa bộ lọc' : 'Clear filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Price filter chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', lang),
                        const SizedBox(width: 8),
                        _buildFilterChip('free', lang),
                        const SizedBox(width: 8),
                        _buildFilterChip('paid', lang),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Category filter button
                Container(
                  decoration: BoxDecoration(
                    gradient: selectedCategories.isNotEmpty
                        ? AppColors.purpleGradient
                        : null,
                    color: selectedCategories.isEmpty
                        ? theme.cardColor
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [AppStyles.shadowSmall],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showCategoryFilter,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 18,
                              color: selectedCategories.isNotEmpty
                                  ? Colors.white
                                  : theme.iconTheme.color,
                            ),
                            if (selectedCategories.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${selectedCategories.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Stories grid
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(theme)
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return StoryCard(story: filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String lang) {
    final isSelected = selectedPriceFilter == filterKey;
    final theme = Theme.of(context);
    
    String getLabel() {
      if (filterKey == 'all') return AppText.get("all_story", lang);
      if (filterKey == 'free') return AppText.get("free_stories", lang);
      if (filterKey == 'paid') return AppText.get("paid_stories", lang);
      return filterKey;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPriceFilter = filterKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.purpleGradient : null,
          color: isSelected ? null : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AppStyles.shadowSmall],
        ),
        child: Text(
          getLabel(),
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final lang = context.watch<LanguageService>().lang;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              boxShadow: [AppStyles.shadowMedium],
            ),
            child: Icon(
              Icons.search_off,
              size: 48,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            lang == "vi" ? 'Không tìm thấy truyện' : 'No stories found',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang == "vi" ? 'Thử thay đổi bộ lọc để xem thêm truyện' : 'Try changing filters to see more stories',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: Text(lang == "vi" ? 'Xóa bộ lọc' : 'Clear filters'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
