import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// ============================================================
/// AUTH SERVICE
/// Kumpulan fungsi untuk komunikasi ke backend Laragon.
/// ============================================================
class AuthService {
  /// Login. Melempar Exception dengan pesan dari backend jika gagal.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['success'] == true) {
      return data; // berisi { success, message, user }
    } else {
      throw Exception(data['message'] ?? 'Login gagal');
    }
  }

  /// Registrasi. Melempar Exception dengan pesan dari backend jika gagal.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.registerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Registrasi gagal');
    }
  }
}
