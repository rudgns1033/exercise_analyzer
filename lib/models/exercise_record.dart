// lib/models/exercise_record.dart

class ExerciseRecord {
  final int id;
  final int userId;
  final String exerciseType;
  final int reps;
  final int calories;
  final DateTime date;           // 추가된 필드

  ExerciseRecord({
  required this.id,
  required this.userId,
  required this.exerciseType,
  required this.reps,
  required this.calories,
  required this.date,           // 생성자에 포함
});

factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
return ExerciseRecord(
id: json['id'] as int,
userId: json['user_id'] as int,
exerciseType: json['exercise_type'] as String,
reps: json['exercise_reps'] as int,
calories: json['burn_calories'] as int,
date: DateTime.parse(json['date'] as String), // JSON의 date 필드 파싱
);
}

Map<String, dynamic> toJson() {
return {
'id': id,
'user_id': userId,
'exercise_type': exerciseType,
'exercise_reps': reps,
'burn_calories': calories,
    'date': date.toIso8601String(),               // ISO 문자열로 직렬화
};
}
}
