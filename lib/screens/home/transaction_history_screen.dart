import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Lịch sử giao dịch"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Column(
        children: [

          /// ===== HEADER =====
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Tổng chi tiêu",
                    style: TextStyle(color: Colors.white70)),
                SizedBox(height: 6),
                Text(
                  "336.000 đ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text("4 lần mua",
                        style: TextStyle(color: Colors.white)),
                    SizedBox(width: 20),
                    Text("1 lần nạp tiền",
                        style: TextStyle(color: Colors.white)),
                  ],
                )
              ],
            ),
          ),

          /// FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _chip("Tất cả", true),
                _chip("Mua truyện", false),
                _chip("Nạp tiền", false),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                _TransactionItem(
                  title: "Chủ Mẫu Xuyên Không",
                  price: "-99.000đ",
                  type: "Mua truyện",
                ),
                _TransactionItem(
                  title: "Nạp tiền ví",
                  price: "+200.000đ",
                  type: "Nạp tiền",
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// CHIP
  Widget _chip(String text, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.deepPurple : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

/// ITEM
class _TransactionItem extends StatelessWidget {
  final String title;
  final String price;
  final String type;

  const _TransactionItem({
    required this.title,
    required this.price,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = price.contains("+");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.book, size: 40),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Thành công",
                    style: TextStyle(color: Colors.green)),
              ],
            ),
          ),

          Text(
            price,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}