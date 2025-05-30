// lib/services/form_evaluation_service.dart

import 'dart:math';

/// 세 점 사이의 각도를 degree 로 계산
double _calculateAngle(
    Map<String, double> a,
    Map<String, double> b,
    Map<String, double> c,
    ) {
  final dx1 = a['x']! - b['x']!;
  final dy1 = a['y']! - b['y']!;
  final dx2 = c['x']! - b['x']!;
  final dy2 = c['y']! - b['y']!;
  final dot = dx1 * dx2 + dy1 * dy2;
  final mag1 = sqrt(dx1 * dx1 + dy1 * dy1);
  final mag2 = sqrt(dx2 * dx2 + dy2 * dy2);
  if (mag1 == 0 || mag2 == 0) return 0.0;
  final cosT = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
  return acos(cosT) * 180 / pi;
}

/// 운동별 피드백 설정
class ExerciseConfig {
  final String p1, p2, p3;
  final double idealAngle;
  final String jointName;
  const ExerciseConfig(this.p1, this.p2, this.p3, this.idealAngle, this.jointName);
}

const Map<String, ExerciseConfig> _configs = {
  'push_up':    ExerciseConfig('leftShoulder', 'leftElbow', 'leftWrist',  45.0,  '팔꿈치'),
  'bench_press':ExerciseConfig('leftShoulder', 'leftElbow', 'leftWrist',  90.0,  '팔꿈치'),
  'squat':      ExerciseConfig('leftHip',      'leftKnee',  'leftAnkle', 90.0,  '무릎'),
  'pull_up':    ExerciseConfig('leftShoulder', 'leftElbow', 'leftWrist', 160.0, '팔꿈치'),
  'sit_up':     ExerciseConfig('leftHip',      'leftKnee',  'leftShoulder', 30.0,'허리'),
};

/// joints(list of {type, x, y}) 만으로 피드백 comments 리턴
class FormEvaluationService {
  /// { 'comments': List<String> }
  Map<String, dynamic> evaluate(String exerciseType, List<Map<String, dynamic>> joints) {
    final cfg = _configs[exerciseType];
    if (cfg == null) {
      return {'comments': ['지원하지 않는 운동입니다.']};
    }

    // 빠른 조회를 위한 map 생성
    final lookup = <String, Map<String, double>>{
      for (var j in joints)
        (j['type'] as String): {'x': j['x'] as double, 'y': j['y'] as double}
    };

    final a = lookup[cfg.p1];
    final b = lookup[cfg.p2];
    final c = lookup[cfg.p3];
    if (a == null || b == null || c == null) {
      return {'comments': ['관절을 인식할 수 없습니다.']};
    }

    final angle = _calculateAngle(a, b, c);
    final delta = cfg.idealAngle - angle;
    const tol = 5.0;
    if (delta.abs() <= tol) {
      // 오차 범위 내 → 정상
      return {'comments': []};
    }

    final dir = delta > 0 ? '굽혀야' : '펴야';
    final text = '${cfg.jointName}를 ${delta.abs().toStringAsFixed(1)}° 더 $dir 합니다';
    return {'comments': [text]};
  }
}
