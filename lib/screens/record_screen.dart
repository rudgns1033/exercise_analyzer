import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise_record.dart';
import '../providers/record_provider.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({Key? key}) : super(key: key);

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final List<String> _categories = ['등', '하체', '어깨', '가슴'];
  final Set<String> _selected = {};
  int _reps = 10;

  @override
  Widget build(BuildContext context) {
    final recProv = context.watch<RecordProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('운동 기록')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: recProv.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            const Text('운동 종류', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._categories.map((cat) => CheckboxListTile(
              title: Text(cat),
              value: _selected.contains(cat),
              onChanged: (v) {
                setState(() {
                  if (v == true) _selected.add(cat);
                  else _selected.remove(cat);
                });
              },
            )),
            const SizedBox(height: 16),
            Text('반복 횟수: $_reps 회'),
            Slider(
              min: 1,
              max: 200,
              divisions: 199,
              value: _reps.toDouble(),
              onChanged: (v) => setState(() => _reps = v.toInt()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              child: const Text('저장'),
              onPressed: () async {
                if (_selected.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('운동 종류를 최소 하나 선택하세요')),
                  );
                  return;
                }
                try {
                  for (var type in _selected) {
                    final rec = ExerciseRecord(
                      id: 0, // 서버 생성 ID
                      userId: 1, // TODO: 실제 userId 적용
                      exerciseType: type,
                      reps: _reps,
                      calories: (_reps * 0.5).toInt(),
                      date: DateTime.now(), // 현재 시각으로 기록
                    );
                    await recProv.addRecord(rec);
                  }
                  setState(() => _selected.clear());
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
    );
  }
}
