import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'topup_screen.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text.dart';
import '../../services/language_service.dart';

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

  List<Map<String, dynamic>> approvedTopups = [];
  bool isLoading = true;

  int totalTopupCount = 0;
  int totalCoinsAdded = 0;

  @override
  void initState() {
    super.initState();
    loadApprovedTopups();
  }

  /// 🔥 LOAD APPROVED TOPUPS ONLY
  Future<void> loadApprovedTopups() async {
    try {
      // Load approved topup requests
      final requestsSnapshot = await _db
          .collection('topup_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .limit(100)
          .get();

      final List<Map<String, dynamic>> topups = [];
      int totalCoins = 0;

      for (var doc in requestsSnapshot.docs) {
        final data = doc.data();
        topups.add({
          'id': doc.id,
          'amount_vnd': data['amount_vnd'] ?? 0,
          'coin_amount': data['coin_amount'] ?? 0,
          'bonus_coin': data['bonus_coin'] ?? 0,
          'total_coin': data['total_coin'] ?? 0,
          'createdAt': data['createdAt'],
          'processedAt': data['processedAt'],
        });
        
        totalCoins += (data['total_coin'] ?? 0) as int;
      }

      // Sort by processedAt (newest first)
      topups.sort((a, b) {
        final aDate = a['processedAt'];
        final bDate = b['processedAt'];
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        
        try {
          DateTime aDateTime;
          DateTime bDateTime;
          
          if (aDate is DateTime) {
            aDateTime = aDate;
          } else if (aDate.runtimeType.toString().contains('Timestamp')) {
            aDateTime = (aDate as dynamic).toDate();
          } else {
            return 1;
          }
          
          if (bDate is DateTime) {
            bDateTime = bDate;
          } else if (bDate.runtimeType.toString().contains('Timestamp')) {
            bDateTime = (bDate as dynamic).toDate();
          } else {
            return -1;
          }
          
          return bDateTime.compareTo(aDateTime);
        } catch (e) {
          return 0;
        }
      });

      if (!mounted) return;

      setState(() {
        approvedTopups = topups;
        totalTopupCount = topups.length;
        totalCoinsAdded = totalCoins;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ loadApprovedTopups error: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final langService = Provider.of<LanguageService>(context);
    final lang = langService.lang;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: Text(AppText.get("transaction_history", lang)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          // Nút nạp tiền
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TopupScreen(),
                  ),
                );
                // Reload after returning from topup
                loadApprovedTopups();
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppText.get("topup", lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadApprovedTopups,
              child: CustomScrollView(
                slivers: [
                  /// ===== HEADER STATS =====
                  SliverToBoxAdapter(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: _db
                          .collection('users')
                          .doc(userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        int currentBalance = 0;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          currentBalance = data?['coin_balance'] ?? 0;
                        }

                        return Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple,
                                AppColors.primaryPurple.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppText.get("current_balance", lang),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.monetization_on,
                                            color: Colors.amber,
                                            size: 32,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "$currentBalance",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppText.get("coins", lang),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.history_rounded,
                                      value: "$totalTopupCount",
                                      label: AppText.get("topup_times", lang),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _statCard(
                                      icon: Icons.add_circle_outline_rounded,
                                      value: "$totalCoinsAdded",
                                      label: AppText.get("total_coins_added", lang),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  /// ===== SECTION TITLE =====
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryPurple,
                                  AppColors.primaryPurple.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppText.get("topup_history", lang),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          if (totalTopupCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$totalTopupCount ${AppText.get('transactions', lang)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  /// ===== TOPUP LIST =====
                  approvedTopups.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppText.get("no_transactions", lang),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppText.get("tap_topup_to_start", lang),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final topup = approvedTopups[index];
                                return _TopupItem(
                                  topup: topup,
                                  isDark: isDark,
                                  lang: lang,
                                );
                              },
                              childCount: approvedTopups.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  /// 🔥 STAT CARD
  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔥 TOPUP ITEM
class _TopupItem extends StatelessWidget {
  final Map<String, dynamic> topup;
  final bool isDark;
  final String lang;

  const _TopupItem({
    required this.topup,
    required this.isDark,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final amountVnd = topup['amount_vnd'] as int;
    final coinAmount = topup['coin_amount'] as int;
    final bonusCoin = topup['bonus_coin'] as int;
    final totalCoin = topup['total_coin'] as int;
    final processedAt = topup['processedAt'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.green,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER ROW
                Row(
                  children: [
                    /// ICON
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_circle_rounded,
                        color: Colors.white,
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
                            AppText.get("topup_success", lang),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppText.get("approved", lang),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(processedAt),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "+$totalCoin",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          "xu",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// DIVIDER
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade200,
                        Colors.grey.shade100,
                        Colors.grey.shade200,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// DETAILS
                Row(
                  children: [
                    Expanded(
                      child: _detailItem(
                        icon: Icons.payments_rounded,
                        label: AppText.get("amount", lang),
                        value: "${NumberFormat('#,###').format(amountVnd)} đ",
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _detailItem(
                        icon: Icons.stars_rounded,
                        label: AppText.get("base_coins", lang),
                        value: "$coinAmount ${AppText.get('coins', lang)}",
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                if (bonusCoin > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade50,
                          Colors.orange.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.card_giftcard_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppText.get("bonus_coins", lang),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "+$bonusCoin ${AppText.get('bonus_label', lang)}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.celebration_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 DETAIL ITEM
  Widget _detailItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primaryPurple,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
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

      if (diff.inMinutes < 1) {
        return AppText.get("just_now", lang);
      } else if (diff.inHours < 1) {
        return "${diff.inMinutes} ${AppText.get('minutes_ago', lang)}";
      } else if (diff.inDays == 0) {
        return "${AppText.get('today', lang)} ${DateFormat('HH:mm').format(date)}";
      } else if (diff.inDays == 1) {
        return "${AppText.get('yesterday', lang)} ${DateFormat('HH:mm').format(date)}";
      } else if (diff.inDays < 7) {
        return "${diff.inDays} ${AppText.get('days_ago', lang)}";
      } else {
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
    } catch (e) {
      return "";
    }
  }
}