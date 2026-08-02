import 'package:flutter/material.dart';

/// ============================================================
/// COLOR SCHEME - "Nemu"
/// ============================================================
class AppColors {
  // Background gradient aplikasi
  static const Color gradientTop = Color(0xFFD9DF36);
  static const Color gradientBottom = Color(0xFF007C3F);

  // Warna teks
  // "Hitam" sekarang bukan hitam pekat, tapi hijau sangat gelap senada
  // dengan warna border form (gradientBottom), supaya lebih menyatu
  // dengan skema hijau dan tidak terlalu kontras/blatant.
  static const Color nightmare = Color(0xFF0B3D24);
  // "Putih" diberi tint beige lebih hangat supaya tidak terlihat putih polos.
  static const Color beige = Color(0xFFF2ECD3);
  // Warna permukaan card/form - beige yang sedikit lebih redup dari
  // `beige` di atas, supaya area putih besar (form) tidak menyilaukan mata.
  static const Color surface = Color(0xFFE9E1BF);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientBottom],
  );
}