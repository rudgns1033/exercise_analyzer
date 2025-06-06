// lib/screens/feedback_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models/joints.dart';
import '../services/form_evaluation_service.dart';

class FeedbackScreen extends StatefulWidget {
  final String exerciseType;
  final List<Joints?> jointsArr;

  const FeedbackScreen({
    Key? key,
    required this.exerciseType,
    required this.jointsArr,
  }) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late final List<Map<String, dynamic>> results;
  late final List<Uint8List> frames;
  int resultIndex = 0;

  bool isPlaying = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    results = widget.jointsArr
        .map((joints) => FormEvaluationService().evaluate(widget.exerciseType, joints!.joints))
        .toList();
    frames = widget.jointsArr
        .map((joints) => joints!.frameBytes!).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    if (isPlaying) {
      _timer?.cancel();
      setState(() => isPlaying = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (resultIndex < results.length - 1) {
          setState(() => resultIndex++);
        } else {
          _timer?.cancel();
          setState(() => isPlaying = false);
        }
      });
      setState(() => isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = results[resultIndex];
    final comments = (result['comments'] as List).cast<String>();
    final frameBytes = frames[resultIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('자세 피드백')),
      body: Column(
        children: [
          // 1. 맨 위에 사진 (padding 포함)
          if (frameBytes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Image.memory(
                frameBytes,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),

          // 2. 나머지 UI 영역 (피드백, 슬라이더 등)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: comments.isEmpty
                      ? const Center(
                    child: Text(
                      '정상적인 자세입니다!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: Text(comments[i]),
                    ),
                  ),
                ),

                const Divider(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        value: resultIndex.toDouble(),
                        min: 0,
                        max: (results.length - 1).toDouble(),
                        divisions: results.length - 1,
                        label: '자세 ${resultIndex + 1}',
                        onChanged: (val) {
                          setState(() {
                            resultIndex = val.round();
                          });
                        },
                      ),
                      Text(
                        '자세 ${resultIndex + 1}/${results.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: resultIndex > 0
                                ? () => setState(() => resultIndex--)
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('이전'),
                          ),

                          // 재생 / 일시정지 버튼 추가
                          ElevatedButton.icon(
                            onPressed: _togglePlayPause,
                            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                            label: Text(isPlaying ? '일시정지' : '재생'),
                          ),

                          ElevatedButton.icon(
                            onPressed: resultIndex < results.length - 1
                                ? () => setState(() => resultIndex++)
                                : null,
                            icon: const Text('다음'),
                            label: const Icon(Icons.arrow_forward),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}