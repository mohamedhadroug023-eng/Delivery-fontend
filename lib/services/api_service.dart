import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiService {
  // سيتم تغييره لاحقًا إلى IP الحاسوب الذي يشغل الـ Backend
  static const String baseUrl =
      'http://localhost:3000/api';

  // =========================================================
  // HEADERS
  // =========================================================

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // =========================================================
  // GET
  // =========================================================

  static Future<Map<String, dynamic>> get(
    String endpoint,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // POST
  // =========================================================

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // PUT
  // =========================================================

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // PATCH
  // =========================================================

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // DELETE
  // =========================================================

  static Future<Map<String, dynamic>> delete(
    String endpoint,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
    );

    return _handleResponse(response);
  }

  // =========================================================
  // RESPONSE
  // =========================================================

  static Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'استجابة غير صالحة من الخادم',
      );
    }

    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'انتهت جلسة تسجيل الدخول، يرجى تسجيل الدخول مجددًا',
      );
    }

    throw Exception(
      data['message'] ??
          'حدث خطأ في الاتصال بالخادم',
    );
  }
}
