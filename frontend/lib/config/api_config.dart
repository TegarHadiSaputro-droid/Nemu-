import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// ============================================================
/// KONFIGURASI API
/// baseUrl otomatis menyesuaikan platform tempat app dijalankan:
/// - Flutter Web (Chrome)   -> http://localhost/nemu_backend
/// - Android Emulator       -> http://10.0.2.2/nemu_backend
/// - iOS Simulator          -> http://localhost/nemu_backend
/// - HP fisik (WiFi)        -> ganti manual ke IP laptop kamu,
///   contoh: http://192.168.1.5/nemu_backend
///   (cek IP laptop dengan `ipconfig` di CMD, cari "IPv4 Address")
/// ============================================================
class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    } else {
      return 'http://localhost:8000/api/v1';
    }
  }

  static String get loginUrl => '$baseUrl/login';
  static String get registerUrl => '$baseUrl/register';
}