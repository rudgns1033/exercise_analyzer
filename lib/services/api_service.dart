
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/video_analysis.dart';
import '../models/exercise_record.dart';
import '../models/plan.dart';

class ApiService {
  static const _baseUrl = 'http://129.154.48.51:9090/api';

  /// 사용자 등록
  Future<User> createUser(User user) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return User.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to create user: ${resp.statusCode} ${resp.body}');
  }

  /// 개인화 운동 계획 생성
  Future<Plan> createPlan(Plan plan) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/plans'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(plan.toJson()),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return Plan.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to create plan: ${resp.statusCode} ${resp.body}');
  }

  /// 사용자 운동 계획 조회
  Future<Plan> getPlan(int userId) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/plans/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      return Plan.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to fetch plan: ${resp.statusCode} ${resp.body}');
  }

  /// 운동 기록 저장
  Future<ExerciseRecord> postRecord(ExerciseRecord rec) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/exercise_record'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(rec.toJson()),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return ExerciseRecord.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Failed to post record: ${resp.statusCode} ${resp.body}');
  }

  /// 사용자별 운동 기록 조회
  Future<List<ExerciseRecord>> getRecords(int userId) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/exercise_record/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body) as List;
      return data.map((item) => ExerciseRecord.fromJson(item)).toList();
    }
    throw Exception('Failed to fetch records: ${resp.statusCode} ${resp.body}');
  }

  /// 영상 자세 분석 요청
  Future<VideoAnalysisResult> analyzeVideo(VideoAnalysisRequest req) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    if (resp.statusCode == 200) {
      return VideoAnalysisResult.fromJson(jsonDecode(resp.body));
    }
    throw Exception('Video analysis failed: ${resp.statusCode} ${resp.body}');
  }
}
