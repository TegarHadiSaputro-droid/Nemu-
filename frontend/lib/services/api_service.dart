import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Configurable base URL
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://127.0.0.1:8000/api/v1';
  }

  /// Fetch full Beranda data from Laravel API
  static Future<Map<String, dynamic>?> fetchBerandaData() async {
    try {
      final uri = Uri.parse('$baseUrl/beranda');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success') {
          return decoded['data'];
        }
      }
    } catch (e) {
      debugPrint('ApiService fetchBerandaData error: $e');
    }
    return null;
  }

  /// Trigger real-time market price sync on the server
  static Future<bool> syncMarketPrices() async {
    try {
      final uri = Uri.parse('$baseUrl/beranda/sync-prices');
      final response = await http.post(uri).timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService syncMarketPrices error: $e');
      return false;
    }
  }
}
