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
  final _dailyTypeCtl = TextEditingController();
  int _dailyReps = 10;
  int _dailyDuration = 20;
  final _weeklyTypeCtl = TextEditingController();
  int _weeklyDuration = 120;

  @override
  Widget build(BuildContext context) {
    final planProv = context.watch<PlanProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('목표 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: planProv.isLoading
            ? const CircularProgressIndicator()
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _dailyTypeCtl,
                decoration: const InputDecoration(labelText: '일일 운동 종류'),
                validator: (v) => v!.isEmpty ? '필수 입력' : null,
              ),
              const SizedBox(height: 8),
              Text('일일 반복 횟수: $_dailyReps 회'),
              Slider(
                min: 1,
                max: 100,
                divisions: 99,
                value: _dailyReps.toDouble(),
                onChanged: (v) => setState(() => _dailyReps = v.toInt()),
              ),
              const SizedBox(height: 8),
              Text('일일 운동 시간: $_dailyDuration 분'),
              Slider(
                min: 1,
                max: 180,
                divisions: 179,
                value: _dailyDuration.toDouble(),
                onChanged: (v) => setState(() => _dailyDuration = v.toInt()),
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _weeklyTypeCtl,
                decoration: const InputDecoration(labelText: '주간 운동 종류'),
                validator: (v) => v!.isEmpty ? '필수 입력' : null,
              ),
              const SizedBox(height: 8),
              Text('주간 총 시간: $_weeklyDuration 분'),
              Slider(
                min: 1,
                max: 1000,
                divisions: 999,
                value: _weeklyDuration.toDouble(),
                onChanged: (v) => setState(() => _weeklyDuration = v.toInt()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('저장'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final plan = Plan(
                      userId: context.read<PlanProvider>().plan?.userId ?? 1,
                      dailyExerciseType: _dailyTypeCtl.text,
                      dailyExerciseReps: _dailyReps,
                      dailyExerciseDuration: _dailyDuration,
                      weeklyExerciseType: _weeklyTypeCtl.text,
                      weeklyExerciseDuration: _weeklyDuration,
                    );
                    planProv.createPlan(plan);
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
