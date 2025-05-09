class ApiError {
  final String message;

  ApiError(this.message);

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      ApiError(json['message'] as String);
}
