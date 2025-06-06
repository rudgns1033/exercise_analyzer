import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plan.dart';
import '../providers/plan_provider.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});
  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categories = ['등', '하체', '어깨', '가슴'];
  final Set<String> _dailySelected = {};
  final Set<String> _weeklySelected = {};
  int _dailyReps = 10;
  int _dailyDuration = 20;
  int _weeklyDuration = 120;

  @override
  Widget build(BuildContext context) {
    final planProv = context.watch<PlanProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('목표 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: planProv.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('일일 운동 종류', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._categories.map((cat) => CheckboxListTile(
                title: Text(cat),
                value: _dailySelected.contains(cat),
                onChanged: (v) {
                  setState(() {
                    if (v == true) _dailySelected.add(cat);
                    else _dailySelected.remove(cat);
                  });
                },
              )),
              const SizedBox(height: 16),
              Text('일일 반복 횟수: $_dailyReps 회'),
              Slider(
                min: 1,
                max: 100,
                divisions: 99,
                value: _dailyReps.toDouble(),
                onChanged: (v) => setState(() => _dailyReps = v.toInt()),
              ),
              const SizedBox(height: 16),
              Text('일일 운동 시간: $_dailyDuration 분'),
              Slider(
                min: 1,
                max: 180,
                divisions: 179,
                value: _dailyDuration.toDouble(),
                onChanged: (v) => setState(() => _dailyDuration = v.toInt()),
              ),
              const Divider(height: 32),
              const Text('주간 운동 종류', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._categories.map((cat) => CheckboxListTile(
                title: Text(cat),
                value: _weeklySelected.contains(cat),
                onChanged: (v) {
                  setState(() {
                    if (v == true) _weeklySelected.add(cat);
                    else _weeklySelected.remove(cat);
                  });
                },
              )),
              const SizedBox(height: 16),
              Text('주간 총 시간: $_weeklyDuration 분'),
              Slider(
                min: 1,
                max: 1000,
                divisions: 999,
                value: _weeklyDuration.toDouble(),
                onChanged: (v) => setState(() => _weeklyDuration = v.toInt()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                child: const Text('저장'),
                onPressed: () async {
                  // 유효성 검증
                  if (_dailySelected.isEmpty || _weeklySelected.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('일일/주간 운동 종류를 모두 선택해주세요')),
                    );
                    return;
                  }
                  final plan = Plan(
                    userId: context.read<PlanProvider>().plan?.userId ?? 1,
                    dailyExerciseType: _dailySelected.join(','),
                    dailyExerciseReps: _dailyReps,
                    dailyExerciseDuration: _dailyDuration,
                    weeklyExerciseType: _weeklySelected.join(','),
                    weeklyExerciseDuration: _weeklyDuration,
                  );
                  try {
                    await planProv.createPlan(plan);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('저장되었습니다')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('저장에 실패했습니다: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
