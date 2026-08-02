import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// ============================================================
/// KONFIGURASI API
/// baseUrl otomatis menyesuaikan platform tempat app dijalankan:
/// - Flutter Web (Chrome)   -> http://localhost:8000/api/v1
/// - Android Emulator       -> http://10.0.2.2:8000/api/v1
/// - HP fisik (WiFi)        -> http://192.168.1.4:8000/api/v1
/// 
/// PENTING: Ganti _physicalDeviceIp jika IP laptop berubah!
/// Cek IP laptop: buka CMD -> ketik `ipconfig` -> cari IPv4
/// ============================================================

/// IP laptop kamu di jaringan WiFi lokal
const String _physicalDeviceIp = '192.168.1.4';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 = emulator saja. HP fisik pakai IP laptop langsung.
      return 'http://$_physicalDeviceIp:8000/api/v1';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000/api/v1';
    } else {
      return 'http://localhost:8000/api/v1';
    }
  }

  static String get loginUrl => '$baseUrl/login';
  static String get registerUrl => '$baseUrl/register';
  static String get berandaUrl => '$baseUrl/beranda';
}