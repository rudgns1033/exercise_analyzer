class Plan {
  final int? id;
  final int userId;
  final String dailyExerciseType;
  final int dailyExerciseReps;
  final int dailyExerciseDuration;
  final String weeklyExerciseType;
  final int weeklyExerciseDuration;

  Plan({
    this.id,
    required this.userId,
    required this.dailyExerciseType,
    required this.dailyExerciseReps,
    required this.dailyExerciseDuration,
    required this.weeklyExerciseType,
    required this.weeklyExerciseDuration,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json['id'] as int?,
    userId: json['user_id'] as int,
    dailyExerciseType: json['daily_exercise_type'] as String,
    dailyExerciseReps: json['daily_exercise_repit'] as int,
    dailyExerciseDuration: json['daily_exercise_duration'] as int,
    weeklyExerciseType: json['weekly_exercise_type'] as String,
    weeklyExerciseDuration: json['weekly_exercise_duration'] as int,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'daily_exercise_type': dailyExerciseType,
    'daily_exercise_repit': dailyExerciseReps,
    'daily_exercise_duration': dailyExerciseDuration,
    'weekly_exercise_type': weeklyExerciseType,
    'weekly_exercise_duration': weeklyExerciseDuration,
  };
}
