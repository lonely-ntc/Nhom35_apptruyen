import 'package:flutter/material.dart';
import '../../data/category_data.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() =>
      _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {

  /// SORT
  String selectedSort = "Thịnh hành";

  final List<String> sortOptions = [
    "Thịnh hành",
    "Mới xuất bản",
    "Đánh giá cao nhất",
    "Đánh giá thấp nhất",
  ];

  /// CATEGORY (MULTI)
  List<String> selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lọc"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                /// 🔥 SORT
                const Text("Sắp xếp",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                ...sortOptions.map((e) {
                  return RadioListTile(
                    value: e,
                    groupValue: selectedSort,
                    title: Text(e),
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;
                      });
                    },
                  );
                }),

                const SizedBox(height: 20),

                /// 🔥 CATEGORY FILTER
                const Text("Thể loại",
                    style: TextStyle(
                        fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((e) {
                    final isSelected =
                        selectedCategories.contains(e);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedCategories.remove(e);
                          } else {
                            selectedCategories.add(e);
                          }
                        });
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepPurple
                              : Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          e,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          /// 🔥 BUTTON
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [

                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedSort = "Thịnh hành";
                        selectedCategories.clear();
                      });
                    },
                    child: const Text("Xóa bộ lọc"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        "sort": selectedSort,
                        "categories": selectedCategories,
                      });
                    },
                    child: const Text("Xác nhận"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}