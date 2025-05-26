// lib/screens/home_tab_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_record.dart';
import 'analysis_history_screen.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({Key? key}) : super(key: key);

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  List<ExerciseRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('exercise_records') ?? [];
    setState(() {
      _records = jsonList
          .map((s) => ExerciseRecord.fromJson(jsonDecode(s)))
          .toList();
    });
  }

  List<ExerciseRecord> _filterRecords(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _records.where((r) => r.date.isAfter(cutoff)).toList();
  }

  Map<String, int> _countByType(List<ExerciseRecord> list) {
    final m = <String,int>{};
    for (var r in list) {
      m[r.exerciseType] = (m[r.exerciseType] ?? 0) + 1;
    }
    return m;
  }

  Widget _buildPie(Map<String,int> data) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('기록이 없습니다')),
      );
    }
    final sections = data.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.key}\n${e.value}',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        showTitle: true,
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(PieChartData(
        sections: sections,
        sectionsSpace: 4,
        centerSpaceRadius: 30,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekRecords  = _filterRecords(7);
    final monthRecords = _filterRecords(30);

    final weekCount  = _countByType(weekRecords);
    final monthCount = _countByType(monthRecords);

    // 예시: 운동 1회당 50 kcal
    final weekCalories = weekRecords.fold<int>(
      0,
          (sum, r) => sum + (r.reps * 50),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '주간 운동 종류 분포',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _buildPie(weekCount),
            const SizedBox(height: 24),
            const Text(
              '월간 운동 종류 분포',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _buildPie(monthCount),
            const SizedBox(height: 24),

            // 주간 소모 칼로리 카드
            Card(
              child: ListTile(
                title: const Text('주간 소모 칼로리'),
                subtitle: Text('$weekCalories kcal'),
              ),
            ),

            // ★ 여기서부터 AI 교정 이력 버튼 추가 ★
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AnalysisHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('AI 교정 이력 보기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
