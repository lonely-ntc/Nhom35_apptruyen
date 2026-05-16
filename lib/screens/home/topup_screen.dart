import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../services/payment_service.dart';
import '../../services/email_service.dart';
import '../../services/language_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text.dart';
import 'transaction_history_screen.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final PaymentService _paymentService = PaymentService();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final _firestore = FirebaseFirestore.instance;

  int? selectedAmount;
  bool isLoadingBalance = true; 
  int currentBalance = 0; 

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    if (!mounted) return;

    setState(() {
      isLoadingBalance = true;
    });

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          currentBalance = data?['coin_balance'] ?? 0;
          isLoadingBalance = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading balance: $e');
      if (mounted) {
        setState(() {
          isLoadingBalance = false;
        });
      }
    }
  }

  Future<void> _refreshBalance() async {
    await _loadBalance();
  }

  final List<Map<String, dynamic>> topupPackages = [
    {'vnd': 10000, 'xu': 10, 'bonus': 0},
    {'vnd': 20000, 'xu': 20, 'bonus': 0},
    {'vnd': 50000, 'xu': 50, 'bonus': 5},
    {'vnd': 100000, 'xu': 100, 'bonus': 10},
    {'vnd': 200000, 'xu': 200, 'bonus': 25},
    {'vnd': 500000, 'xu': 500, 'bonus': 75},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = context.watch<LanguageService>().lang;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppText.get("topup_title", lang)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoadingBalance ? null : _refreshBalance,
            icon: Icon(
              Icons.refresh,
              color: isLoadingBalance ? Colors.grey : null,
            ),
            tooltip: lang == "vi" ? "Làm mới số dư" : "Refresh balance",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBalance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              /// ===== HEADER: CURRENT BALANCE =====
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple,
                      AppColors.primaryPurple.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      AppText.get("current_balance", lang),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    isLoadingBalance
                        ? const SizedBox(
                            height: 44,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "$currentBalance ${AppText.get("coins", lang)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),

              /// ===== TOPUP PACKAGES =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryOrange,
                                AppColors.primaryOrange.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppText.get("select_package", lang),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: topupPackages.length,
                      itemBuilder: (context, index) {
                        final package = topupPackages[index];
                        final isSelected = selectedAmount == package['vnd'];
                        final hasBonus = package['bonus'] > 0;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedAmount = package['vnd'];
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryPurple.withOpacity(0.1)
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryPurple
                                    : theme.dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryPurple
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.monetization_on,
                                            color: isSelected
                                                ? AppColors.primaryPurple
                                                : Colors.amber,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${package['xu']} xu",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppColors.primaryPurple
                                                  : theme.textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${package['vnd'] ~/ 1000}K VNĐ",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: theme.textTheme.bodySmall?.color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (hasBonus) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange,
                                                Colors.orange.shade700,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "+${package['bonus']} xu",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurple,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    /// ===== PAYMENT BUTTON =====
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: selectedAmount == null
                            ? null
                            : _showQRPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: selectedAmount == null ? 0 : 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_2, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              selectedAmount == null
                                  ? AppText.get("select_package", lang)
                                  : (lang == "vi" ? "Hiển thị mã QR" : "Show QR Code"),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// ===== INFO BOX =====
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Hướng dẫn nạp xu",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "1. Chọn gói nạp xu phù hợp\n"
                            "2. Nhấn 'Hiển thị mã QR'\n"
                            "3. Quét mã QR bằng app ngân hàng\n"
                            "4. Xu sẽ được cộng tự động sau khi thanh toán",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 SHOW QR PAYMENT DIALOG
  void _showQRPayment() {
    if (selectedAmount == null) return;

    final lang = context.read<LanguageService>().lang;
    final package = topupPackages.firstWhere((p) => p['vnd'] == selectedAmount);
    final user = FirebaseAuth.instance.currentUser;
    
    // GỌI API VIETQR THEO FORM MỚI
    final qrUrl = _paymentService.taoUrlVietQR(
      soTienVND: selectedAmount!,
      tenNguoiDung: user?.displayName ?? "NguoiDung",
      email: user?.email ?? "Khach",
      soXu: package['xu'] + package['bonus'],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// HEADER
              Row(
                children: [
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
                    child: const Icon(
                      Icons.qr_code_2,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Quét mã thanh toán",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// QR CODE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: qrUrl,
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 250,
                          height: 250,
                          color: Colors.grey.shade100,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Đang tải mã QR...",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 250,
                          height: 250,
                          color: Colors.grey.shade200,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Không thể tải mã QR",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// PAYMENT INFO
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.1),
                      AppColors.primaryPurple.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${AppText.get("amount", lang)}:",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "${selectedAmount! ~/ 1000}K VNĐ",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${AppText.get("received", lang)}:",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${package['xu'] + package['bonus']} xu",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (package['bonus'] > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              lang == "vi" ? "🎁 Tặng ${package['bonus']} xu" : "🎁 ${AppText.get("gift", lang)} ${package['bonus']} ${AppText.get("coins", lang)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// CONFIRM BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showConfirmationDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppText.get("payment_completed", lang),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 SHOW CONFIRMATION DIALOG & SEND EMAIL
  void _showConfirmationDialog() async {
    final lang = context.read<LanguageService>().lang;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final package = topupPackages.firstWhere(
        (p) => p['vnd'] == selectedAmount,
      );

      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email ?? 'Khách ẩn danh';
      final userName = user?.displayName ?? 'Người dùng';
      final totalXu = package['xu'] + package['bonus'];

      // 1. Lưu Firebase cho Admin App duyệt
      final docRef = await FirebaseFirestore.instance
          .collection('topup_requests')
          .add({
            'userId': userId,
            'amount_vnd': selectedAmount!,
            'coin_amount': package['xu'],
            'bonus_coin': package['bonus'],
            'total_coin': totalXu,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'userEmail': userEmail,
          });

      // Tạo transaction ID từ document ID
      final transactionId = docRef.id.substring(0, 8).toUpperCase();

      // 2. Gửi Email chuẩn Form cho Admin qua EmailJS
      final emailSent = await EmailService.thongBaoChoAdmin(
        tenNguoiDung: userName,
        emailKhachHang: userEmail,
        soXuNap: totalXu.toString(),
        transactionId: transactionId,
        bankInfo: 'Vietcombank - 1234567890 - NGUYEN VAN A',
      );

      if (!mounted) return;
      
      // Close loading
      Navigator.pop(context);

      // 🔥 Log email status
      if (emailSent) {
        debugPrint('✅ Email notification sent to admins successfully');
      } else {
        debugPrint('⚠️ Email notification failed, but request was saved');
      }

      // 🔥 Show success dialog with 24h notice
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  lang == 'vi' ? 'Yêu cầu đã được gửi!' : 'Request Sent!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.blue.shade700,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang == 'vi' 
                          ? 'Trong vòng 24h xu sẽ được nạp vào tài khoản của bạn'
                          : 'Coins will be added to your account within 24 hours',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.blue.shade900,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang == 'vi'
                          ? 'Mã giao dịch: $transactionId'
                          : 'Transaction ID: $transactionId',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // OK Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // Close dialog
                      Navigator.pop(context);
                      // Close topup screen
                      Navigator.pop(context);
                      // Navigate to transaction history (replace current route)
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionHistoryScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Close loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ ${lang == 'vi' ? 'Có lỗi xảy ra' : 'An error occurred'}: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}