class User {
  final int? id;
  final int height;
  final int weight;
  final int age;
  final bool beginner;

  User({
    this.id,
    required this.height,
    required this.weight,
    required this.age,
    required this.beginner,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int?,
    height: json['height'] as int,
    weight: json['weight'] as int,
    age: json['age'] as int,
    beginner: json['beginner'] as bool,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'height': height,
    'weight': weight,
    'age': age,
    'beginner': beginner,
  };
}
