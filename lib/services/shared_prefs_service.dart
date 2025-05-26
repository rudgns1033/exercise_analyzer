// lib/services/shared_prefs_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_record.dart';

class SharedPrefsService {
  SharedPrefsService._();
  static final SharedPrefsService instance = SharedPrefsService._();

  static const _keyRecords = 'exercise_records';

  /// 저장된 기록을 모두 불러옵니다.
  Future<List<ExerciseRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyRecords) ?? <String>[];
    return jsonList
        .map((s) => ExerciseRecord.fromJson(jsonDecode(s)))
        .toList();
  }

  /// 새 기록을 추가합니다.
  Future<void> addRecord(ExerciseRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyRecords) ?? <String>[];
    list.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_keyRecords, list);
  }

  /// 기록을 전부 덮어씁니다.
  Future<void> setRecords(List<ExerciseRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final list = records.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_keyRecords, list);
  }

  /// 모든 기록을 삭제합니다.
  Future<void> clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecords);
  }
}
