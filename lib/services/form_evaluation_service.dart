// lib/services/form_evaluation_service.dart

import 'dart:math';

class FormFeedback {
  final bool isCorrect;
  final List<String> comments;

  FormFeedback({required this.isCorrect, required this.comments});
}

class FormEvaluationService {
  static FormFeedback evaluate({
    required String exerciseType,
    required List<Map<String, dynamic>> joints,
  }) {
    switch (exerciseType) {
      case 'push_up':
        return _evaluatePushUp(joints);
      case 'squat':
        return _evaluateSquat(joints);
      case 'bench_press':
        return _evaluateBenchPress(joints);
      case 'pull_up':
        return _evaluatePullUp(joints);
      case 'sit_up':
        return _evaluateSitUp(joints);
      default:
        return FormFeedback(isCorrect: false, comments: ['알 수 없는 운동 유형입니다.']);
    }
  }

  static FormFeedback _evaluatePushUp(List<Map<String, dynamic>> j) {
    final notes = <String>[];
    final elbow = _findLandmark(j, 'leftElbow');
    final shoulder = _findLandmark(j, 'leftShoulder');
    final wrist = _findLandmark(j, 'leftWrist');
    if (elbow == null || shoulder == null || wrist == null) {
      notes.add('관절을 정확히 인식하지 못했습니다.');
      return FormFeedback(isCorrect: false, comments: notes);
    }
    final angle = _angle(shoulder, elbow, wrist);
    if (angle < 70) notes.add('팔을 더 굽혀주세요 (현재 ${angle.toStringAsFixed(1)}°)');
    if (angle > 100) notes.add('팔을 덜 펴도 됩니다 (현재 ${angle.toStringAsFixed(1)}°)');
    final hip = _findLandmark(j, 'leftHip');
    final knee = _findLandmark(j, 'leftKnee');
    if (hip != null && knee != null) {
      final torsoAngle = _angle(shoulder, hip, knee);
      if ((torsoAngle - 180).abs() > 10) {
        notes.add('몸통이 일직선이 아닙니다 (현재 ${torsoAngle.toStringAsFixed(1)}°)');
      }
    }
    return FormFeedback(isCorrect: notes.isEmpty, comments: notes);
  }

  static FormFeedback _evaluateSquat(List<Map<String, dynamic>> j) {
    final notes = <String>[];
    final hip = _findLandmark(j, 'leftHip');
    final knee = _findLandmark(j, 'leftKnee');
    final ankle = _findLandmark(j, 'leftAnkle');
    if (hip == null || knee == null || ankle == null) {
      notes.add('관절을 정확히 인식하지 못했습니다.');
      return FormFeedback(isCorrect: false, comments: notes);
    }
    final kneeAngle = _angle(hip, knee, ankle);
    if (kneeAngle > 100) {
      notes.add('엉덩이를 더 내려주세요 (현재 ${kneeAngle.toStringAsFixed(1)}°)');
    }
    if ((knee['x'] as double) > (ankle['x'] as double) + 20) {
      notes.add('무릎이 발끝을 넘지 않도록 해주세요');
    }
    return FormFeedback(isCorrect: notes.isEmpty, comments: notes);
  }

  static FormFeedback _evaluateBenchPress(List<Map<String, dynamic>> j) {
    final notes = <String>[];
    final shoulder = _findLandmark(j, 'leftShoulder');
    final elbow = _findLandmark(j, 'leftElbow');
    final wrist = _findLandmark(j, 'leftWrist');
    if (shoulder == null || elbow == null || wrist == null) {
      notes.add('관절을 정확히 인식하지 못했습니다.');
      return FormFeedback(isCorrect: false, comments: notes);
    }
    final angle = _angle(shoulder, elbow, wrist);
    if ((angle - 90).abs() > 15) {
      notes.add('팔꿈치 각도를 약 90°로 유지해 주세요 (현재 ${angle.toStringAsFixed(1)}°)');
    }
    return FormFeedback(isCorrect: notes.isEmpty, comments: notes);
  }

  static FormFeedback _evaluatePullUp(List<Map<String, dynamic>> j) {
    final notes = <String>[];
    final wrist = _findLandmark(j, 'leftWrist');
    final shoulder = _findLandmark(j, 'leftShoulder');
    if (wrist == null || shoulder == null) {
      notes.add('관절을 정확히 인식하지 못했습니다.');
      return FormFeedback(isCorrect: false, comments: notes);
    }
    if ((wrist['y'] as double) > (shoulder['y'] as double)) {
      notes.add('턱이 바보다 아래에 있습니다. 턱을 더 올려주세요');
    }
    final elbow = _findLandmark(j, 'leftElbow');
    if (elbow != null) {
      if ((elbow['y'] as double) < (shoulder['y'] as double) - 20) {
        notes.add('팔을 더 완전히 펴주세요');
      }
    }
    return FormFeedback(isCorrect: notes.isEmpty, comments: notes);
  }

  static FormFeedback _evaluateSitUp(List<Map<String, dynamic>> j) {
    final notes = <String>[];
    final shoulder = _findLandmark(j, 'leftShoulder');
    final hip = _findLandmark(j, 'leftHip');
    final knee = _findLandmark(j, 'leftKnee');
    if (shoulder == null || hip == null || knee == null) {
      notes.add('관절을 정확히 인식하지 못했습니다.');
      return FormFeedback(isCorrect: false, comments: notes);
    }
    final angle = _angle(shoulder, hip, knee);
    if (angle > 100) {
      notes.add('허리를 더 구부려 상체를 올려주세요 (현재 ${angle.toStringAsFixed(1)}°)');
    }
    return FormFeedback(isCorrect: notes.isEmpty, comments: notes);
  }

  static double _angle(
      Map<String, dynamic> a,
      Map<String, dynamic> b,
      Map<String, dynamic> c,
      ) {
    final dx1 = (a['x'] as double) - (b['x'] as double);
    final dy1 = (a['y'] as double) - (b['y'] as double);
    final dx2 = (c['x'] as double) - (b['x'] as double);
    final dy2 = (c['y'] as double) - (b['y'] as double);
    final dot = dx1 * dx2 + dy1 * dy2;
    final mag1 = sqrt(dx1 * dx1 + dy1 * dy1);
    final mag2 = sqrt(dx2 * dx2 + dy2 * dy2);
    final cosTheta = dot / (mag1 * mag2);
    return acos(cosTheta) * 180 / pi;
  }

  static Map<String, dynamic>? _findLandmark(
      List<Map<String, dynamic>> j, String type) {
    try {
      return j.firstWhere((e) => e['type'] == type);
    } catch (_) {
      return null;
    }
  }
}
