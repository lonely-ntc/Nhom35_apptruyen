import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LanguageService extends ChangeNotifier {
  String _lang = "vi";

  String get lang => _lang;

  LanguageService() {
    loadLanguage();
  }

  /// 🔥 Load ngôn ngữ từ hệ thống (không lưu SharedPreferences nữa)
  Future<void> loadLanguage() async {
    // Lấy ngôn ngữ từ hệ thống
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    final systemLangCode = systemLocale.languageCode;
    
    // Nếu hệ thống là tiếng Việt thì dùng "vi", còn lại dùng "en"
    _lang = systemLangCode == 'vi' ? 'vi' : 'en';
    
    print('🌍 System language: $systemLangCode → Using: $_lang');
    
    notifyListeners();
  }

  /// 🔥 Không còn cho phép thay đổi ngôn ngữ thủ công nữa
  /// Ngôn ngữ sẽ tự động theo hệ thống
  @Deprecated('Language now follows system settings')
  Future<void> changeLanguage(String value) async {
    // Không làm gì cả - ngôn ngữ theo hệ thống
    print('⚠️ changeLanguage is deprecated - language follows system settings');
  }
}