import 'dart:math';

/// 좌표값 맵 리스트에서 특정 관절 좌표를 Landmark 객체로 변환
class Landmark {
  final double x, y;
  Landmark(this.x, this.y);
}

Landmark? _getLandmark(List<Map<String, dynamic>> joints, String type) {
  for (var j in joints) {
    if (j['type'] == type) {
      return Landmark(j['x'] as double, j['y'] as double);
    }
  }
  return null;
}

/// 세 점 A-B-C에서 B를 정점으로 하는 각도(도)를 계산
double _angle(Landmark a, Landmark b, Landmark c) {
  final ab = Point(a.x - b.x, a.y - b.y);
  final cb = Point(c.x - b.x, c.y - b.y);
  final dot = ab.x * cb.x + ab.y * cb.y;
  final magAB = sqrt(ab.x * ab.x + ab.y * ab.y);
  final magCB = sqrt(cb.x * cb.x + cb.y * cb.y);
  if (magAB == 0 || magCB == 0) return 0.0;
  var cosA = dot / (magAB * magCB);
  cosA = cosA.clamp(-1.0, 1.0);
  return acos(cosA) * 180 / pi;
}

/// 운동 자세 평가 결과
class FormFeedback {
  final bool isCorrect;
  final List<String> comments;
  FormFeedback({required this.isCorrect, required this.comments});
}

/// 여러 운동 유형에 대해 자세를 평가
class FormEvaluationService {
  /// 팔굽혀펴기 평가
  FormFeedback evaluatePushUp(List<Map<String, dynamic>> joints) {
    final List<String> comments = [];
    final ls = _getLandmark(joints, 'leftShoulder');
    final le = _getLandmark(joints, 'leftElbow');
    final lw = _getLandmark(joints, 'leftWrist');
    if (ls == null || le == null || lw == null) {
      comments.add('팔 관절을 정확히 인식하지 못했습니다.');
    } else {
      final angle = _angle(ls, le, lw);
      if (angle > 100 || angle < 70) {
        comments.add('팔꿈치를 약 90도로 굽혀주세요. 현재: ${angle.toStringAsFixed(1)}°');
      }
    }
    final ss = _getLandmark(joints, 'leftShoulder');
    final lh = _getLandmark(joints, 'leftHip');
    final la = _getLandmark(joints, 'leftAnkle');
    if (ss == null || lh == null || la == null) {
      comments.add('몸통 라인을 확인할 수 없습니다.');
    } else {
      final torsoAngle = _angle(ss, lh, la);
      if ((torsoAngle - 180).abs() > 15) {
        comments.add('몸을 일직선으로 유지하세요. 현재: ${torsoAngle.toStringAsFixed(1)}°');
      }
    }
    return FormFeedback(isCorrect: comments.isEmpty, comments: comments);
  }

  /// 스쿼트 평가
  FormFeedback evaluateSquat(List<Map<String, dynamic>> joints) {
    final List<String> comments = [];
    final lh = _getLandmark(joints, 'leftHip');
    final lk = _getLandmark(joints, 'leftKnee');
    final la = _getLandmark(joints, 'leftAnkle');
    if (lh == null || lk == null || la == null) {
      comments.add('하체 관절을 정확히 인식하지 못했습니다.');
    } else {
      final kneeAngle = _angle(lh, lk, la);
      if (kneeAngle > 100) {
        comments.add('엉덩이를 더 낮춰 무릎 각도를 90°로 유지하세요. 현재: ${kneeAngle.toStringAsFixed(1)}°');
      }
      if (lk.x > la.x + 0.05) {
        comments.add('무릎이 발끝을 넘지 않도록 유지하세요.');
      }
    }
    return FormFeedback(isCorrect: comments.isEmpty, comments: comments);
  }

  /// 벤치프레스 평가
  FormFeedback evaluateBenchPress(List<Map<String, dynamic>> joints) {
    final List<String> comments = [];
    final ss = _getLandmark(joints, 'leftShoulder');
    final le = _getLandmark(joints, 'leftElbow');
    final lw = _getLandmark(joints, 'leftWrist');
    if (ss == null || le == null || lw == null) {
      comments.add('벤치프레스 관절을 인식할 수 없습니다.');
    } else {
      final elbowAngle = _angle(ss, le, lw);
      if (elbowAngle < 70 || elbowAngle > 110) {
        comments.add('팔꿈치를 약 90도로 구부려 바를 가슴까지 내리세요. 현재: ${elbowAngle.toStringAsFixed(1)}°');
      }
      if (lw.y > ss.y + 0.1) {
        comments.add('바를 너무 낮게 내렸습니다. 가슴 상단에 맞춰주세요.');
      }
    }
    return FormFeedback(isCorrect: comments.isEmpty, comments: comments);
  }

  /// 턱걸이 평가
  FormFeedback evaluatePullUp(List<Map<String, dynamic>> joints) {
    final List<String> comments = [];
    final ls = _getLandmark(joints, 'leftShoulder');
    final rs = _getLandmark(joints, 'rightShoulder');
    final lw = _getLandmark(joints, 'leftWrist');
    final rw = _getLandmark(joints, 'rightWrist');
    if (ls == null || rs == null || lw == null || rw == null) {
      comments.add('턱걸이 관절을 정확히 인식할 수 없습니다.');
    } else {
      final avgWristY = (lw.y + rw.y) / 2;
      final avgShoulderY = (ls.y + rs.y) / 2;
      if (avgWristY > avgShoulderY - 0.05) {
        comments.add('턱을 바 위로 충분히 올리세요.');
      }
      if ((lw.y - ls.y).abs() < 0.1 && (rw.y - rs.y).abs() < 0.1) {
        comments.add('팔을 완전히 펴고 시작하세요.');
      }
    }
    return FormFeedback(isCorrect: comments.isEmpty, comments: comments);
  }

  /// 윗몸일으키기 평가
  FormFeedback evaluateSitUp(List<Map<String, dynamic>> joints) {
    final List<String> comments = [];
    final ls = _getLandmark(joints, 'leftShoulder');
    final lh = _getLandmark(joints, 'leftHip');
    final lk = _getLandmark(joints, 'leftKnee');
    if (ls == null || lh == null || lk == null) {
      comments.add('윗몸일으키기 관절을 인식할 수 없습니다.');
    } else {
      final hipAngle = _angle(ls, lh, lk);
      if (hipAngle > 100) {
        comments.add('상체를 더 들어올려 90° 각도를 유지하세요. 현재: ${hipAngle.toStringAsFixed(1)}°');
      }
    }
    return FormFeedback(isCorrect: comments.isEmpty, comments: comments);
  }
}
