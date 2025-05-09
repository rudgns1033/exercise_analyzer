import 'package:flutter/material.dart';
import '../models/exercise_record.dart';
import '../services/api_service.dart';

class RecordProvider extends ChangeNotifier {
  final _api = ApiService();
  List<ExerciseRecord> _records = [];
  bool _loading = false;

  List<ExerciseRecord> get records => _records;
  bool get isLoading => _loading;

  Future<void> addRecord(ExerciseRecord rec) async {
    _loading = true;
    notifyListeners();
    try {
      final created = await _api.postRecord(rec);
      _records.add(created);
    } catch (e) {
      // TODO
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecords(int userId) async {
    _loading = true;
    notifyListeners();
    try {
      _records = await _api.getRecords(userId);
    } catch (e) {
      // TODO
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
