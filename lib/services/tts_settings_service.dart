import 'package:shared_preferences/shared_preferences.dart';

/// Service để lưu và load cài đặt TTS
/// Các cài đặt này sẽ được giữ nguyên qua các truyện khác nhau
class TtsSettingsService {
  static const String _keyRate = 'tts_speech_rate';
  static const String _keyPitch = 'tts_pitch';
  static const String _keyVolume = 'tts_volume';

  // Default values
  static const double defaultRate = 0.5;
  static const double defaultPitch = 1.0;
  static const double defaultVolume = 1.0;

  /// Lưu tốc độ đọc
  static Future<void> saveSpeechRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRate, rate);
  }

  /// Lưu cao độ giọng
  static Future<void> savePitch(double pitch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPitch, pitch);
  }

  /// Lưu âm lượng
  static Future<void> saveVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, volume);
  }

  /// Load tốc độ đọc
  static Future<double> loadSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyRate) ?? defaultRate;
  }

  /// Load cao độ giọng
  static Future<double> loadPitch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyPitch) ?? defaultPitch;
  }

  /// Load âm lượng
  static Future<double> loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyVolume) ?? defaultVolume;
  }

  /// Load tất cả settings
  static Future<Map<String, double>> loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'rate': prefs.getDouble(_keyRate) ?? defaultRate,
      'pitch': prefs.getDouble(_keyPitch) ?? defaultPitch,
      'volume': prefs.getDouble(_keyVolume) ?? defaultVolume,
    };
  }

  /// Reset về giá trị mặc định
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRate, defaultRate);
    await prefs.setDouble(_keyPitch, defaultPitch);
    await prefs.setDouble(_keyVolume, defaultVolume);
  }
}
