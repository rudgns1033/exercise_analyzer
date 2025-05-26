import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_session.dart';

class AnalysisHistoryService {
  static const _key = 'analysis_history';

  static Future<List<AnalysisSession>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((s) {
      return AnalysisSession.fromJson(jsonDecode(s));
    }).toList();
  }

  static Future<void> saveSession(AnalysisSession sess) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(jsonEncode(sess.toJson()));
    await prefs.setStringList(_key, list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
