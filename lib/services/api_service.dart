import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // غيّر هذا لاحقًا إلى عنوان الـ Backend الحقيقي
  static const String baseUrl = 'http://localhost:3000/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<Map<String, dynamic>> get(
    String endpoint,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data['message'] ?? 'حدث خطأ في الاتصال بالخادم',
    );
  }
}
