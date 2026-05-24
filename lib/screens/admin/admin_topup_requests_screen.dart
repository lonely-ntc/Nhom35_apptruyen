import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/payment_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';

class AdminTopupRequestsScreen extends StatefulWidget {
  const AdminTopupRequestsScreen({super.key});

  @override
  State<AdminTopupRequestsScreen> createState() => _AdminTopupRequestsScreenState();
}

class _AdminTopupRequestsScreenState extends State<AdminTopupRequestsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _paymentService = PaymentService();
  
  String selectedFilter = 'pending'; // pending, approved, rejected, all
  
  // Counts for each status
  int pendingCount = 0;
  int approvedCount = 0;
  int rejectedCount = 0;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  /// 🔥 LOAD COUNTS FOR EACH STATUS
  Future<void> _loadCounts() async {
    try {
      // Get pending count
      final pendingSnapshot = await _firestore
          .collection('topup_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      
      // Get approved count
      final approvedSnapshot = await _firestore
          .collection('topup_requests')
          .where('status', isEqualTo: 'approved')
          .get();
      
      // Get rejected count
      final rejectedSnapshot = await _firestore
          .collection('topup_requests')
          .where('status', isEqualTo: 'rejected')
          .get();
      
      // Get total count
      final totalSnapshot = await _firestore
          .collection('topup_requests')
          .get();
      
      if (mounted) {
        setState(() {
          pendingCount = pendingSnapshot.docs.length;
          approvedCount = approvedSnapshot.docs.length;
          rejectedCount = rejectedSnapshot.docs.length;
          totalCount = totalSnapshot.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading counts: $e');
    }
  }

  /// 🔥 GET REQUESTS STREAM (Simplified - no orderBy to avoid index issues)
  Stream<QuerySnapshot> _getRequestsStream() {
    if (selectedFilter == 'all') {
      return _firestore
          .collection('topup_requests')
          .limit(100)
          .snapshots();
    } else {
      return _firestore
          .collection('topup_requests')
          .where('status', isEqualTo: selectedFilter)
          .limit(100)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Duyệt nạp xu"),
            if (pendingCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              _loadCounts(); // Reload counts
            },
            tooltip: "Làm mới",
          ),
        ],
      ),
      body: Column(
        children: [
          /// ===== FILTER TABS =====
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.darkCard : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Chờ duyệt', 'pending', Colors.orange, pendingCount),
                  _filterChip('Đã duyệt', 'approved', Colors.green, approvedCount),
                  _filterChip('Từ chối', 'rejected', Colors.red, rejectedCount),
                  _filterChip('Tất cả', 'all', Colors.blue, totalCount),
                ],
              ),
            ),
          ),

          /// ===== REQUESTS LIST =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            "Lỗi: ${snapshot.error}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            _loadCounts();
                          },
                          child: const Text("Thử lại"),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Không có yêu cầu nào",
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort requests by createdAt in memory (newest first)
                final requests = snapshot.data!.docs;
                requests.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  
                  return bTime.compareTo(aTime); // Descending order
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final doc = requests[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildRequestCard(doc.id, data, theme, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 FILTER CHIP
  Widget _filterChip(String text, String value, Color color, int count) {
    final selected = selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 🔥 REQUEST CARD
  Widget _buildRequestCard(
    String requestId,
    Map<String, dynamic> data,
    ThemeData theme,
    bool isDark,
  ) {
    final status = data['status'] ?? 'pending';
    final amountVnd = data['amount_vnd'] ?? 0;
    final totalCoin = data['total_coin'] ?? 0;
    final bonusCoin = data['bonus_coin'] ?? 0;
    final userEmail = data['userEmail'] ?? 'Unknown';
    final createdAt = data['createdAt'] as Timestamp?;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Đã duyệt';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Từ chối';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Chờ duyệt';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending' ? Colors.orange.withOpacity(0.3) : theme.dividerColor,
          width: status == 'pending' ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// CONTENT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// AMOUNT INFO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Số tiền nạp",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${NumberFormat('#,###').format(amountVnd)} VNĐ",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryPurple,
                            AppColors.primaryPurple.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
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
                                "$totalCoin xu",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (bonusCoin > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "+$bonusCoin xu",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                /// ACTIONS (only for pending)
                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectRequest(requestId, data),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text("Từ chối"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _approveRequest(requestId, data),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text("Duyệt"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                /// PROCESSED INFO
                if (status != 'pending' && data['processedAt'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Xử lý bởi: ${data['processedBy'] ?? 'Admin'}\n${_formatDate(data['processedAt'])}",
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 APPROVE REQUEST
  Future<void> _approveRequest(String requestId, Map<String, dynamic> data) async {
    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận duyệt"),
        content: Text(
          "Duyệt yêu cầu nạp ${data['total_coin']} xu cho ${data['userEmail']}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Duyệt"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Add coins to user - PASS userId from request data
      final success = await _paymentService.xacNhanThanhToanThanhCong(
        soTienVND: data['amount_vnd'],
        bonusXu: data['bonus_coin'],
        userId: data['userId'], // IMPORTANT: Pass the user's ID, not admin's ID
      );

      if (success) {
        // Update request status
        await _firestore.collection('topup_requests').doc(requestId).update({
          'status': 'approved',
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': 'Admin',
        });

        await NotificationService.instance.notifyTopupSuccess(
          userId: data['userId'],
          totalCoin: data['total_coin'],
          amountVnd: data['amount_vnd'],
          bonusCoin: data['bonus_coin'] ?? 0,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading

        // Reload counts
        _loadCounts();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Đã duyệt và cộng xu thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("Failed to add coins");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Lỗi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔥 REJECT REQUEST
  Future<void> _rejectRequest(String requestId, Map<String, dynamic> data) async {
    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận từ chối"),
        content: Text(
          "Từ chối yêu cầu nạp xu của ${data['userEmail']}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Từ chối"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Update request status
      await _firestore.collection('topup_requests').doc(requestId).update({
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': 'Admin',
      });

      await NotificationService.instance.notifyTopupFailed(
        userId: data['userId'],
        totalCoin: data['total_coin'],
        amountVnd: data['amount_vnd'],
        reason: 'Admin chưa nhận được tiền chuyển khoản',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Reload counts
      _loadCounts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Đã từ chối yêu cầu!"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Lỗi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔥 FORMAT DATE
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";

    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
        date = (timestamp as Timestamp).toDate();
      } else {
        return "N/A";
      }

      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return "Vừa xong";
      } else if (diff.inHours < 1) {
        return "${diff.inMinutes} phút trước";
      } else if (diff.inDays < 1) {
        return "${diff.inHours} giờ trước";
      } else if (diff.inDays < 7) {
        return "${diff.inDays} ngày trước";
      } else {
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
    } catch (e) {
      return "N/A";
    }
  }
}
