import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  String _lang = "vi";

  String get lang => _lang;

  LanguageService() {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString("lang") ?? "vi";
    notifyListeners();
  }

  Future<void> changeLanguage(String value) async {
    _lang = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lang", value);

    notifyListeners();
  }
}