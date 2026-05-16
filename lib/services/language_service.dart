import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LanguageService extends ChangeNotifier {
  String _lang = "vi";

  String get lang => _lang;

  LanguageService() {
    loadLanguage();
  }

  /// 🔥 Load ngôn ngữ đã lưu hoặc từ hệ thống
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language');
    
    if (savedLang != null) {
      // Nếu đã có ngôn ngữ được lưu, dùng ngôn ngữ đó
      _lang = savedLang;
    } else {
      // Nếu chưa có, lấy từ hệ thống
      final systemLocale = ui.PlatformDispatcher.instance.locale;
      final systemLangCode = systemLocale.languageCode;
      _lang = systemLangCode == 'vi' ? 'vi' : 'en';
    }
    
    notifyListeners();
  }

  /// 🔥 Thay đổi ngôn ngữ thủ công
  Future<void> changeLanguage(String newLang) async {
    if (_lang == newLang) return;
    
    _lang = newLang;
    
    // Lưu vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLang);
    
    notifyListeners();
  }
}