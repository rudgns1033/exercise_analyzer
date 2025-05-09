import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise_record.dart';
import '../providers/record_provider.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeCtl = TextEditingController();
  int _reps = 10;
  @override
  Widget build(BuildContext context) {
    final recProv = context.watch<RecordProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('운동 기록')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: recProv.isLoading
            ? const CircularProgressIndicator()
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _typeCtl,
                decoration: const InputDecoration(labelText: '운동 종류'),
                validator: (v) => v!.isEmpty ? '필수 입력' : null,
              ),
              const SizedBox(height: 8),
              Text('반복 횟수: $_reps 회'),
              Slider(
                min: 1,
                max: 200,
                divisions: 199,
                value: _reps.toDouble(),
                onChanged: (v) => setState(() => _reps = v.toInt()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('저장'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final rec = ExerciseRecord(
                      userId: 1, // TODO: 실제 유저 ID
                      exerciseType: _typeCtl.text,
                      reps: _reps,
                      calories: (_reps * 0.5).toInt(),
                    );
                    recProv.addRecord(rec);
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
