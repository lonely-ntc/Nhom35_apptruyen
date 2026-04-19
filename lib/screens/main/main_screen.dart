import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/home_screen.dart';
import '../home/explore_screen.dart';
import '../home/wishlist_screen.dart';
import '../home/purchased_screen.dart';
import '../home/profile_screen.dart';

import '../../services/language_service.dart';
import '../../utils/app_text.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  /// 🔥 FIX: KHÔNG DÙNG LIST CACHE NỮA
  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ExploreScreen();
      case 2:
        return const WishlistScreen();
      case 3:
        return const PurchasedScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<LanguageService>().lang;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      /// 🔥 FIX: mỗi lần build → tạo lại screen
      body: _getScreen(currentIndex),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
        },

        backgroundColor: theme.cardColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.textTheme.bodySmall?.color,

        type: BottomNavigationBarType.fixed,

        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppText.get("home", lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: AppText.get("explore", lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: AppText.get("wishlist", lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: AppText.get("purchased", lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppText.get("profile", lang),
          ),
        ],
      ),
    );
  }
}