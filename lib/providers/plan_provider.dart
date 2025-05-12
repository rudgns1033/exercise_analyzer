import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../services/api_service.dart';

class PlanProvider extends ChangeNotifier {
  final _api = ApiService();
  Plan? _plan;
  bool _loading = false;

  Plan? get plan => _plan;
  bool get isLoading => _loading;

  Future<void> createPlan(Plan p) async {
    _loading = true;
    notifyListeners();
    try {
      _plan = await _api.createPlan(p);
    } catch (e) {
      // TODO
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPlan(int userId) async {
    _loading = true;
    notifyListeners();
    try {
      _plan = await _api.getPlan(userId);
    } catch (e) {
      // TODO
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
