// decor_background.dart
//
// Widget dekorasi bulatan playful untuk background halaman bergradasi.
// Dipakai di account.dart dan semua halaman turunan Kelola Toko supaya
// background tidak terasa kosong, tanpa perlu duplikat kode di tiap file.
//
// Cara pakai:
//   Stack(
//     children: [
//       ...decorCircles(),   // taruh sebelum konten utama
//       SafeArea(child: ...) // konten utama di atasnya
//     ],
//   )

import 'package:flutter/material.dart';
import 'app_theme.dart';

class DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const DecorCircle({super.key, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kCream.withValues(alpha: opacity),
      ),
    );
  }
}

/// Set bulatan dekoratif standar (4 lingkaran di 4 sudut).
/// Taruh sebagai children pertama dalam Stack, sebelum konten utama.
List<Widget> decorCircles() {
  return const [
    Positioned(
      top: -40,
      right: -30,
      child: DecorCircle(size: 140, opacity: 0.10),
    ),
    Positioned(
      top: 120,
      left: -50,
      child: DecorCircle(size: 100, opacity: 0.08),
    ),
    Positioned(
      bottom: 60,
      right: -40,
      child: DecorCircle(size: 160, opacity: 0.08),
    ),
    Positioned(
      bottom: -60,
      left: -20,
      child: DecorCircle(size: 180, opacity: 0.10),
    ),
  ];
}