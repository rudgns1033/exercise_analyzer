// lib/screens/analysis_history_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../models/analysis_session.dart';
import '../services/analysis_history_service.dart';
import 'jointDisplayScreen.dart';

class AnalysisHistoryScreen extends StatefulWidget {
  const AnalysisHistoryScreen({Key? key}) : super(key: key);
  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen> {
  late Future<List<AnalysisSession>> _future;

  @override
  void initState() {
    super.initState();
    _future = AnalysisHistoryService.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 교정 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: '전체 삭제',
            onPressed: () async {
              await AnalysisHistoryService.clear();
              setState(() => _future = AnalysisHistoryService.load());
            },
          ),
        ],
      ),
      body: FutureBuilder<List<AnalysisSession>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snap.data!;
          if (sessions.isEmpty) {
            return const Center(child: Text('저장된 기록이 없습니다'));
          }
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (ctx, i) {
              final s = sessions[sessions.length - 1 - i];
              return ListTile(
                leading: Image.file(File(s.thumbnailPath), width: 56, fit: BoxFit.cover),
                title: Text(s.exerciseType.replaceAll('_', ' ').toUpperCase()),
                subtitle: Text(
                  '${s.timestamp.year}/${s.timestamp.month.toString().padLeft(2,'0')}/'
                      '${s.timestamp.day.toString().padLeft(2,'0')} '
                      '${s.timestamp.hour.toString().padLeft(2,'0')}:'
                      '${s.timestamp.minute.toString().padLeft(2,'0')}',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => JointDisplayScreen(
                        thumbnailPath: s.thumbnailPath,
                        joints: s.joints,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
