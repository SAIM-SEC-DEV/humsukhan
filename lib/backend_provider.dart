import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class BackendProvider {
  final Dio _dio;
  static const String _baseUrl = 'http://localhost:8000'; // Change for production
  String? _token;

  BackendProvider() : _dio = Dio(BaseOptions(baseUrl: _baseUrl)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  bool get isAuthenticated => _token != null;

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/token',
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );
      _token = response.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String email, String username, String password, String gender) async {
    try {
      await _dio.post('/users/', data: {
        'email': email,
        'username': username,
        'password': password,
        'gender': gender,
      });
      return await login(username, password);
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<List<ProfessionalRecord>> getRecords() async {
    try {
      final response = await _dio.get('/records/');
      return (response.data as List)
          .map((json) => ProfessionalRecord.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> syncRecord(ProfessionalRecord record) async {
    try {
      await _dio.post('/records/', data: record.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRecord(String recordId) async {
    try {
      await _dio.delete('/records/$recordId');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<ProfessionalInsights?> generateInsights(List<TranscriptLine> transcript) async {
    try {
      final response = await _dio.post('/ai/summarize', data: 
        transcript.map((line) => line.toJson()).toList()
      );
      final data = response.data;
      return ProfessionalInsights(
        summary: data['summary'],
        vocabulary: List<String>.from(data['vocabulary']),
        difficultTerms: [],
        themes: [],
        actionItems: List<String>.from(data['action_items']),
        deadlines: [],
        mentionedPeople: [],
      );
    } catch (e) {
      return null;
    }
  }
}
