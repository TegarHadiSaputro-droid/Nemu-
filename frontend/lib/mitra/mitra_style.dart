// mitra_style.dart
//
// Warna & text style dipakai bersama di seluruh halaman Mitra supaya
// konsisten dengan HomeScreen (draco) — gradient hijau-kuning yang sama,
// font Manrope yang sama, warna teks gelap yang sama.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Sengaja disamakan persis dengan konstanta di home_screen.dart supaya
// tidak ada "loncatan" warna saat pindah dari Beranda ke Mitra.
const Color mitraYellowTop = Color(0xFFD9DF36);
const Color mitraGreenBottom = Color(0xFF007C3F);
const Color mitraTextDark = Color(0xFF0F1B11);
const Color mitraCream = Color(0xFFF5F5DC);

const LinearGradient mitraBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [mitraYellowTop, mitraGreenBottom],
  stops: [0.0, 0.45],
);

/// Helper text style Manrope, sama pola pemakaiannya dengan `_m()` di
/// home_screen.dart supaya gampang dibaca siapapun yang lanjutin kode ini.
TextStyle mitraFont({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = mitraTextDark,
  double? height,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

/// Bulatan dekoratif transparan, gaya sama dengan decor_background.dart
/// (dipakai di halaman login/account), supaya background gradient di
/// halaman Mitra tidak terasa kosong/polos.
List<Widget> mitraDecorCircles() {
  return const [
    Positioned(
      top: -40,
      right: -30,
      child: _MitraDecorCircle(size: 140, opacity: 0.10),
    ),
    Positioned(
      top: 160,
      left: -50,
      child: _MitraDecorCircle(size: 100, opacity: 0.08),
    ),
    Positioned(
      bottom: 80,
      right: -40,
      child: _MitraDecorCircle(size: 160, opacity: 0.08),
    ),
    Positioned(
      bottom: -60,
      left: -20,
      child: _MitraDecorCircle(size: 180, opacity: 0.10),
    ),
  ];
}

class _MitraDecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _MitraDecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: mitraCream.withValues(alpha: opacity),
      ),
    );
  }
}

/// AppBar transparan standar dipakai di semua halaman Mitra.
PreferredSizeWidget mitraAppBar(
  String title, {
  List<Widget>? actions,
  Color titleColor = mitraCream,
  Color iconColor = mitraCream,
  double titleSize = 18,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: iconColor),
    title: Text(
      title,
      style: mitraFont(size: titleSize, weight: FontWeight.bold, color: titleColor),
    ),
    actions: actions,
  );
}