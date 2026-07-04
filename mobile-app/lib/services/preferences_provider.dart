import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  
  bool _isDarkMode = false;
  String _language = 'id'; // 'id' or 'en'

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    final darkStr = await _storage.read(key: 'is_dark_mode');
    final langStr = await _storage.read(key: 'language');
    
    if (darkStr != null) {
      _isDarkMode = darkStr == 'true';
    }
    if (langStr != null) {
      _language = langStr;
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _storage.write(key: 'is_dark_mode', value: isDark.toString());
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _storage.write(key: 'language', value: lang);
    notifyListeners();
  }
}
