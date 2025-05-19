import 'dart:math';

/// 좌표값 맵 리스트에서 특정 관절 좌표를 쉽게 추출하기 위한 헬퍼
class Landmark {
  final double x;
  final double y;
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

/// 두 벡터의 각도를 계산하는 함수
double _angle(Landmark a, Landmark b, Landmark c) {
  // b를 정점으로 하는 각 ABC
  final ab = Point(a.x - b.x, a.y - b.y);
  final cb = Point(c.x - b.x, c.y - b.y);
  final dot = ab.x * cb.x + ab.y * cb.y;
  final magAB = sqrt(ab.x * ab.x + ab.y * ab.y);
  final magCB = sqrt(cb.x * cb.x + cb.y * cb.y);
  if (magAB == 0 || magCB == 0) return 0.0;
  var cosAngle = dot / (magAB * magCB);
  if (cosAngle.abs() > 1) cosAngle = cosAngle.sign;
  return acos(cosAngle) * 180 / pi;
}

/// 운동 자세 평가 결과
class FormFeedback {
  final bool isCorrect;
  final List<String> comments;
  FormFeedback({required this.isCorrect, required this.comments});
}

/// 운동 종류에 따라 올바른 자세를 평가하는 서비스
class FormEvaluationService {
  /// 팔굽혀펴기 자세 평가
  /// joints: 관절 좌표 리스트
  /// 기본 기준:
  /// - 팔꿈치 각도(어깨-팔꿈치-손목)가 내려갔을 때 약 90도
  /// - 몸통(어깨-엉덩이-발목)이 일직선
  FormFeedback evaluatePushUp(List<Map<String, dynamic>> joints) {
    List<String> comments = [];

    // 1) 팔꿈치 각도
    final shoulder = _getLandmark(joints, 'leftShoulder');
    final elbow = _getLandmark(joints, 'leftElbow');
    final wrist = _getLandmark(joints, 'leftWrist');
    if (shoulder == null || elbow == null || wrist == null) {
      comments.add('팔 관절을 인식할 수 없습니다.');
    } else {
      final elbowAngle = _angle(shoulder, elbow, wrist);
      if (elbowAngle > 100 || elbowAngle < 70) {
        comments.add('팔꿈치를 더 굽혀주세요 (약 90도 목표). 현재 각도: ${elbowAngle.toStringAsFixed(1)}°');
      }
    }

    // 2) 몸통 일직선 확인 (어깨-엉덩이-발목)
    final hip = _getLandmark(joints, 'leftHip');
    final ankle = _getLandmark(joints, 'leftAnkle');
    if (shoulder == null || hip == null || ankle == null) {
      comments.add('몸통 라인을 확인할 수 없습니다.');
    } else {
      // 3점이 얼마나 일직선에 가까운지: 세 점 내각 차이가 15도 이내
      final hipAngle = _angle(shoulder, hip, ankle);
      if ((hipAngle - 180).abs() > 15) {
        comments.add('몸통을 일직선으로 유지하세요. 현재 각도: ${hipAngle.toStringAsFixed(1)}°');
      }
    }

    final isCorrect = comments.isEmpty;
    return FormFeedback(isCorrect: isCorrect, comments: comments);
  }

  /// 스쿼트 자세 평가
  /// 기준:
  /// - 무릎 각도(엉덩이-무릎-발목)이 낮을 때 약 90도 이하
  /// - 무릎이 발끝을 넘지 않도록
  FormFeedback evaluateSquat(List<Map<String, dynamic>> joints) {
    List<String> comments = [];

    // 1) 무릎 각도
    final hip = _getLandmark(joints, 'leftHip');
    final knee = _getLandmark(joints, 'leftKnee');
    final ankle = _getLandmark(joints, 'leftAnkle');
    if (hip == null || knee == null || ankle == null) {
      comments.add('하체 관절을 인식할 수 없습니다.');
    } else {
      final kneeAngle = _angle(hip, knee, ankle);
      if (kneeAngle > 100) {
        comments.add('엉덩이를 더 낮춰주세요 (무릎 각도 90° 목표). 현재 각도: ${kneeAngle.toStringAsFixed(1)}°');
      }
    }

    // 2) 무릎과 발끝 위치 비교 (2D 화면 기준)
    if (knee != null && ankle != null) {
      if (knee.x > ankle.x + 0.05) {
        comments.add('무릎이 발끝을 넘지 않도록 유지하세요.');
      }
    }

    final isCorrect = comments.isEmpty;
    return FormFeedback(isCorrect: isCorrect, comments: comments);
  }
}
