class ExerciseRecord {
  final int? id;
  final int userId;
  final String exerciseType;
  final int reps;
  final int calories;

  ExerciseRecord({
    this.id,
    required this.userId,
    required this.exerciseType,
    required this.reps,
    required this.calories,
  });

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) => ExerciseRecord(
    id: json['id'] as int?,
    userId: json['user_id'] as int,
    exerciseType: json['exercise_type'] as String,
    reps: json['exercise_repit'] as int,
    calories: json['burn_calories'] as int,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'exercise_type': exerciseType,
    'exercise_repit': reps,
    'burn_calories': calories,
  };
}
