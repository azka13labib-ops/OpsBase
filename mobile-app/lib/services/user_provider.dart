import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// Simpan data user login (termasuk kapabilitas) supaya semua screen bisa
/// akses tanpa fetch ulang tiap kali. Panggil `load()` sekali setelah login.
class UserProvider extends ChangeNotifier {
  UserAuth? _user;
  bool _loading = false;
  String? _error;

  UserAuth? get user => _user;
  bool get loading => _loading;
  String? get error => _error;

  bool can(String capability) => _user?.can(capability) ?? false;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final json = await ApiService.getMe();
      _user = UserAuth.fromJson(json);
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
