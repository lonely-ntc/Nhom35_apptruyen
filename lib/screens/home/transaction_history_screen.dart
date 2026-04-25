import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../utils/image_helper.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends State<TransactionHistoryScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final _db = FirebaseFirestore.instance;

  String selectedFilter = "all"; // all, purchase, topup
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;

  double totalSpent = 0;
  int purchaseCount = 0;
  int topupCount = 0;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  /// 🔥 LOAD TRANSACTIONS
  Future<void> loadTransactions() async {
    try {
      // Load purchased stories
      final purchasedSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('purchased')
          .orderBy('purchaseDate', descending: true)
          .get();

      final List<Map<String, dynamic>> allTransactions = [];

      for (var doc in purchasedSnapshot.docs) {
        final data = doc.data();
        allTransactions.add({
          'type': 'purchase',
          'title': data['title'] ?? 'Không rõ',
          'amount': -(data['price'] ?? 0),
          'date': data['purchaseDate'],
          'image': data['image'],
          'status': 'success',
        });
      }

      // Calculate stats
      double spent = 0;
      int purchases = 0;
      int topups = 0;

      for (var tx in allTransactions) {
        if (tx['type'] == 'purchase') {
          spent += (tx['amount'] as num).abs();
          purchases++;
        } else if (tx['type'] == 'topup') {
          topups++;
        }
      }

      if (!mounted) return;

      setState(() {
        transactions = allTransactions;
        totalSpent = spent;
        purchaseCount = purchases;
        topupCount = topups;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ loadTransactions error: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  /// 🔥 FILTER TRANSACTIONS
  List<Map<String, dynamic>> get filteredTransactions {
    if (selectedFilter == "all") return transactions;
    return transactions
        .where((tx) => tx['type'] == selectedFilter)
        .toList();
  }

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

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// ===== HEADER STATS =====
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.purpleAccent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tổng chi tiêu",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${NumberFormat('#,###').format(totalSpent)} đ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _statItem(
                            icon: Icons.shopping_bag,
                            label: "$purchaseCount lần mua",
                          ),
                          const SizedBox(width: 24),
                          _statItem(
                            icon: Icons.account_balance_wallet,
                            label: "$topupCount lần nạp",
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                /// ===== FILTER CHIPS =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _filterChip("Tất cả", "all"),
                      _filterChip("Mua truyện", "purchase"),
                      _filterChip("Nạp tiền", "topup"),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                /// ===== TRANSACTION LIST =====
                Expanded(
                  child: filteredTransactions.isEmpty
                      ? const Center(
                          child: Text("Chưa có giao dịch nào"),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = filteredTransactions[index];
                            return _TransactionItem(
                              transaction: tx,
                            );
                          },
                        ),
                )
              ],
            ),
    );
  }

  /// 🔥 STAT ITEM
  Widget _statItem({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  /// 🔥 FILTER CHIP
  Widget _filterChip(String text, String value) {
    final selected = selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: Colors.deepPurple.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// 🔥 TRANSACTION ITEM
class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final type = transaction['type'];
    final title = transaction['title'];
    final amount = transaction['amount'] as num;
    final date = transaction['date'];
    final image = transaction['image'];
    final isPositive = amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          /// IMAGE/ICON
          if (type == 'purchase' && image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<String>(
                future: ImageHelper.getImageFromStory(
                  title: title,
                  category: "",
                  pathFromDb: image,
                ),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                    );
                  }

                  final imagePath = snapshot.data!;

                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: Image(
                      fit: BoxFit.cover,
                      image: ImageHelper.isNetwork(imagePath)
                          ? NetworkImage(imagePath)
                          : AssetImage(imagePath) as ImageProvider,
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                type == 'topup'
                    ? Icons.account_balance_wallet
                    : Icons.book,
                color: isPositive ? Colors.green : Colors.red,
                size: 24,
              ),
            ),

          const SizedBox(width: 12),

          /// INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Thành công",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// AMOUNT
          Text(
            "${isPositive ? '+' : ''}${NumberFormat('#,###').format(amount)} đ",
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          )
        ],
      ),
    );
  }

  /// 🔥 FORMAT DATE
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";

    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
        date = (timestamp as dynamic).toDate();
      } else {
        return "";
      }

      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return "Hôm nay ${DateFormat('HH:mm').format(date)}";
      } else if (diff.inDays == 1) {
        return "Hôm qua ${DateFormat('HH:mm').format(date)}";
      } else if (diff.inDays < 7) {
        return "${diff.inDays} ngày trước";
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      return "";
    }
  }
}