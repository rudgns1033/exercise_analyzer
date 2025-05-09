import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final _api = ApiService();
  User? _user;
  bool _loading = false;

  User? get user => _user;
  bool get isLoading => _loading;

  Future<void> registerUser(User u) async {
    _loading = true;
    notifyListeners();

    try {
      _user = await _api.createUser(u);
    } catch (e) {
      // TODO: 오류 처리
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
