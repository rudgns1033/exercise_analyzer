// lib/widgets/pose_feedback_widget.dart

import 'package:flutter/material.dart';
import '../services/form_evaluation_service.dart';

class PoseFeedbackWidget extends StatefulWidget {
  /// 운동 타입 (push_up, squat 등)
  final String exerciseType;
  /// ML Kit 에서 뽑아온 관절 좌표 리스트
  final List<Map<String, dynamic>> joints;

  const PoseFeedbackWidget({
    Key? key,
    required this.exerciseType,
    required this.joints,
  }) : super(key: key);

  @override
  _PoseFeedbackWidgetState createState() => _PoseFeedbackWidgetState();
}

class _PoseFeedbackWidgetState extends State<PoseFeedbackWidget> {
  List<String>? _comments;

  void _onTap() {
    // 인스턴스 메서드로 evaluate 호출
    final result = FormEvaluationService().evaluate(
      widget.exerciseType,
      widget.joints,
    );

    setState(() {
      // comments 키로 List<String> 꺼내기
      _comments = (result['comments'] as List).cast<String>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _onTap,
          child: const Text("피드백 보기"),
        ),
        const SizedBox(height: 16),
        if (_comments != null) ...[
          // 코멘트가 비어 있으면 정상 자세 메시지
          if (_comments!.isEmpty)
            const Text(
              '정상적인 자세입니다!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )
          else
          // 에러 아이콘과 함께 각 코멘트를 리스트로 표시
            ..._comments!.map((text) => ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text(text),
            )),
        ],
      ],
    );
  }
}
