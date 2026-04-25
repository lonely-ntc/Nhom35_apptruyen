import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../services/user_service.dart';
import '../../services/experience_service.dart';
import '../../services/language_service.dart';
import '../../models/experience_model.dart';
import '../../utils/app_text.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_styles.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/glass_card.dart';

import 'settings_screen.dart';
import 'wishlist_screen.dart';
import 'favorite_stories_screen.dart';
import 'notification_screen.dart';
import 'transaction_history_screen.dart';
import 'my_comments_screen.dart';
import '../welcome_screen.dart';
import 'personal_info_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String avatarPath = "assets/avatars/avatar1.png";

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final avatar = await UserService.instance.getAvatar();

    if (!mounted) return;

    setState(() {
      avatarPath = avatar;
    });
  }

  /// Calculate progress for experience bar
  double _calculateProgress(ExperienceModel expModel) {
    if (expModel.rank == 'Đấu Đế') return 1.0;
    
    // Calculate based on current rank
    int currentRankBaseExp = 0;
    int nextRankBaseExp = 0;
    
    if (expModel.rank == 'Đấu Giả') {
      currentRankBaseExp = 0;
      nextRankBaseExp = 900;
    } else if (expModel.rank == 'Đấu Sư') {
      currentRankBaseExp = 900;
      nextRankBaseExp = 1800;
    } else if (expModel.rank == 'Đại Đấu Sư') {
      currentRankBaseExp = 1800;
      nextRankBaseExp = 2700;
    } else if (expModel.rank == 'Đấu Linh') {
      currentRankBaseExp = 2700;
      nextRankBaseExp = 3600;
    } else if (expModel.rank == 'Đấu Vương') {
      currentRankBaseExp = 3600;
      nextRankBaseExp = 4500;
    } else if (expModel.rank == 'Đấu Hoàng') {
      currentRankBaseExp = 4500;
      nextRankBaseExp = 5400;
    } else if (expModel.rank == 'Đấu Tông') {
      currentRankBaseExp = 5400;
      nextRankBaseExp = 6300;
    } else if (expModel.rank == 'Đấu Tôn') {
      currentRankBaseExp = 6300;
      nextRankBaseExp = 7200;
    } else if (expModel.rank == 'Đấu Thánh') {
      currentRankBaseExp = 7200;
      nextRankBaseExp = 9900;
    }
    
    final expInCurrentRank = expModel.exp - currentRankBaseExp;
    final expNeededForNextRank = nextRankBaseExp - currentRankBaseExp;
    
    return expInCurrentRank / expNeededForNextRank;
  }

  /// 🔥 GET REAL STATS FROM FIREBASE
  Stream<Map<String, int>> _getStatsStream() {
    return UserService.instance.getStatsStream(user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>().lang;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,

      body: CustomScrollView(
        slivers: [
          /// ===== MODERN APP BAR =====
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
              ),
            ),
            title: Text(
              AppText.get("profile", lang),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          /// ===== CONTENT =====
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                /// ===== AVATAR SECTION =====
                Column(
                  children: [
                    /// Gradient Avatar Border
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.purpleGradient,
                          boxShadow: [AppStyles.purpleShadow],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.scaffoldBackgroundColor,
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundImage: AssetImage(avatarPath),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      user?.displayName ?? "User",
                      style: AppStyles.heading3.copyWith(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    /// Dynamic Badge based on Rank
                    StreamBuilder<int>(
                      stream: ExperienceService.instance.streamExp(user!.uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.orangeGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Đấu Giả",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        final exp = snapshot.data!;
                        final expModel = ExperienceModel.fromExp(exp);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.orangeGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            expModel.displayRank,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// ===== EXPERIENCE CARD =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<int>(
                    stream: ExperienceService.instance.streamExp(user!.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox();
                      }

                      final exp = snapshot.data!;
                      final expModel = ExperienceModel.fromExp(exp);
                      final progress = expModel.rank == 'Đấu Đế'
                          ? 1.0
                          : _calculateProgress(expModel);

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: AppColors.purpleGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [AppStyles.purpleShadow],
                        ),
                        child: Column(
                          children: [
                            /// RANK with animated icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 600),
                                  builder: (context, value, child) {
                                    return Transform.rotate(
                                      angle: value * 2 * 3.14159,
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.military_tech_rounded,
                                      color: Colors.amber,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Colors.amber, Colors.orange],
                                  ).createShader(bounds),
                                  child: Text(
                                    expModel.displayRank,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            /// PROGRESS BAR with animation
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.stars_rounded,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'EXP: $exp',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      expModel.rank == 'Đấu Đế'
                                          ? '🎉 MAX'
                                          : '${expModel.expToNextRank} EXP',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: progress),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Stack(
                                      children: [
                                        Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: value,
                                          child: Container(
                                            height: 12,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Colors.amber, Colors.orange],
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.amber.withOpacity(0.5),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            /// INFO with icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    expModel.rank == 'Đấu Đế'
                                        ? Icons.emoji_events_rounded
                                        : Icons.trending_up_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      expModel.rank == 'Đấu Đế'
                                          ? '🎉 Bạn đã đạt cấp cao nhất!'
                                          : '💪 Tiếp tục đọc để lên cấp!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),


                /// ===== STATS CARDS =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<Map<String, int>>(
                    stream: _getStatsStream(),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {'read': 0, 'purchased': 0, 'wishlist': 0};
                      
                      return Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              value: stats['read'].toString(),
                              label: AppText.get("read", lang),
                              icon: Icons.menu_book_rounded,
                              gradient: AppColors.blueGradient,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              value: stats['purchased'].toString(),
                              label: AppText.get("purchased", lang),
                              icon: Icons.shopping_bag_rounded,
                              gradient: AppColors.orangeGradient,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              value: stats['wishlist'].toString(),
                              label: AppText.get("wishlist", lang),
                              icon: Icons.favorite_rounded,
                              gradient: AppColors.pinkGradient,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                /// ===== MENU SECTION =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _modernMenuItem(
                        context,
                        Icons.person_rounded,
                        AppText.get("profile", lang),
                        AppColors.primaryPurple,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PersonalInfoScreen(),
                            ),
                          );

                          if (result == true) {
                            await _loadAvatar();
                            setState(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      _modernMenuItem(
                        context,
                        Icons.favorite_rounded,
                        "Truyện yêu thích",
                        AppColors.primaryPink,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FavoriteStoriesScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _modernMenuItem(
                        context,
                        Icons.comment_rounded,
                        AppText.get("comment", lang),
                        AppColors.primaryBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyCommentsScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _modernMenuItem(
                        context,
                        Icons.notifications_rounded,
                        AppText.get("notification", lang),
                        AppColors.primaryOrange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _modernMenuItem(
                        context,
                        Icons.history_rounded,
                        AppText.get("history", lang),
                        AppColors.successGreen,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionHistoryScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _modernMenuItem(
                        context,
                        Icons.lock_rounded,
                        AppText.get("change_password", lang),
                        AppColors.grey600,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      /// ===== LOGOUT BUTTON =====
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.errorRed.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showLogoutDialog(context, lang),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: AppColors.errorRed,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      AppText.get("logout", lang),
                                      style: const TextStyle(
                                        color: AppColors.errorRed,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppColors.errorRed,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Modern Menu Item
  Widget _modernMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppStyles.shadowSmall],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: AppStyles.bodyLarge.copyWith(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.textTheme.bodySmall?.color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, String lang) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [AppStyles.shadowXLarge],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.errorRed,
                      AppColors.errorRed.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppText.get("logout", lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warningOrange,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppText.get("logout_confirm", lang),
                      style: AppStyles.bodyLarge.copyWith(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                            ),
                            child: Text(AppText.get("cancel", lang)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);

                              await FirebaseAuth.instance.signOut();

                              if (!context.mounted) return;

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WelcomeScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.errorRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              AppText.get("logout", lang),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
