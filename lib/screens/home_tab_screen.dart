import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/plan_provider.dart';
import '../providers/record_provider.dart';
import '../models/plan.dart';
import '../models/exercise_record.dart';

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final planProv = context.watch<PlanProvider>();
    final recProv  = context.watch<RecordProvider>();

    final Plan? plan = planProv.plan;
    final List<ExerciseRecord> allRecords = recProv.records;

    // 오늘 기준으로 지난 7일치, 지난 30일치 필터링
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final weekRecords = allRecords.where((r) => r.date.isAfter(weekAgo)).toList();
    final monthRecords = allRecords.where((r) => r.date.isAfter(monthAgo)).toList();

    // 종류별 카운트 계산
    Map<String, int> countByType(List<ExerciseRecord> list) {
      final map = <String,int>{};
      for (var r in list) {
        map[r.exerciseType] = (map[r.exerciseType] ?? 0) + 1;
      }
      return map;
    }

    final weekCount = countByType(weekRecords);
    final monthCount = countByType(monthRecords);

    // 주간 칼로리 합계
    final weekCalories = weekRecords.fold<int>(0, (sum, r) => sum + r.calories);

    Widget buildPie(Map<String,int> data) {
      final sections = data.entries.map((e) {
        return PieChartSectionData(
          value: e.value.toDouble(),
          title: '${e.key}\n${e.value}',
        );
      }).toList();
      return SizedBox(
        height: 200,
        child: PieChart(PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 30,
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. 주간 운동 분포
          const Text('주간 운동 종류 분포', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (weekCount.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('기록이 없습니다')),
            )
          else
            buildPie(weekCount),

          const SizedBox(height: 24),

          // 2. 월간 운동 분포
          const Text('월간 운동 종류 분포', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (monthCount.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('기록이 없습니다')),
            )
          else
            buildPie(monthCount),

          const SizedBox(height: 24),

          // 3. 일일 목표 운동량
          if (plan != null) ...[
            Card(
              child: ListTile(
                title: const Text('일일 목표 운동량'),
                subtitle: Text('${plan.dailyExerciseReps}회 / ${plan.dailyExerciseDuration}분'),
              ),
            ),
            const SizedBox(height: 12),

            // 4. 운동 목표 (주간 총 시간)
            Card(
              child: ListTile(
                title: const Text('주간 총 운동 목표'),
                subtitle: Text('${plan.weeklyExerciseDuration}분'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 5. 주간 소모 칼로리
          Card(
            child: ListTile(
              title: const Text('주간 소모 칼로리'),
              subtitle: Text('$weekCalories kcal'),
            ),
          ),
        ],
      ),
    );
  }
}
