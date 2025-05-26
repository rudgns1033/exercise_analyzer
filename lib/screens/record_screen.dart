// lib/screens/record_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_record.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);
  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final TextEditingController _repsController = TextEditingController();
  String? _selectedType;
  bool _saving = false;

  final _exerciseTypes = [
    'push_up', 'squat', 'bench_press', 'pull_up', 'sit_up'
  ];

  @override
  void dispose() {
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (_selectedType == null || _repsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운동 종류와 횟수를 모두 입력하세요')),
      );
      return;
    }
    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('exercise_records') ?? <String>[];

    final int reps = int.tryParse(_repsController.text) ?? 0;
    final int calories = reps * 50;  // 예: 1회당 50kcal 소모

    final rec = ExerciseRecord(
      id: DateTime.now().millisecondsSinceEpoch,  // 고유 ID
      userId: 1,                                  // 임시 유저 ID
      exerciseType: _selectedType!,               // e.g. 'push_up'
      reps: reps,                                 // 반복 횟수
      calories: calories,                         // 소모 칼로리
      date: DateTime.now(),                       // 기록 날짜
    );

    list.add(jsonEncode(rec.toJson()));
    await prefs.setStringList('exercise_records', list);

    setState(() {
      _saving = false;
      _selectedType = null;
      _repsController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('운동 기록이 저장되었습니다!')),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운동 기록')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('운동 종류'),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedType,
              hint: const Text('선택하세요'),
              items: _exerciseTypes.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.replaceAll('_', ' ')),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '횟수'),
            ),
            const SizedBox(height: 24),
            Center(
              child: _saving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _saveRecord,
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
