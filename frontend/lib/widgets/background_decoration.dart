import 'package:flutter/material.dart';

/// ============================================================
/// BACKGROUND DECORATION
/// Elemen dekoratif (blob blur & ikon tipis) yang ditaruh di
/// belakang konten supaya background gradient hijau tidak terasa
/// kosong/kopong. Semua elemen transparan & IgnorePointer supaya
/// tidak mengganggu interaksi user.
/// ============================================================
class BackgroundDecoration extends StatelessWidget {
  const BackgroundDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Blob besar di kiri atas
          Positioned(
            top: -70,
            left: -70,
            child: _blob(200, Colors.white.withOpacity(0.07)),
          ),
          // Blob di kanan bawah
          Positioned(
            bottom: -90,
            right: -70,
            child: _blob(240, Colors.black.withOpacity(0.06)),
          ),
          // Ikon-ikon dekoratif tersebar tipis-tipis
          Positioned(
            top: 100,
            right: 24,
            child: _icon(Icons.eco_outlined, 46, 0.12, -0.3),
          ),
          Positioned(
            top: 260,
            left: 18,
            child: _icon(Icons.shopping_basket_outlined, 38, 0.10, 0.35),
          ),
          Positioned(
            bottom: 180,
            right: 40,
            child: _icon(Icons.local_florist_outlined, 34, 0.10, -0.2),
          ),
          Positioned(
            bottom: 70,
            left: 36,
            child: _icon(Icons.spa_outlined, 30, 0.10, 0.25),
          ),
          Positioned(
            top: 40,
            left: 120,
            child: _icon(Icons.grass_outlined, 26, 0.10, 0.5),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _icon(IconData icon, double size, double opacity, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Icon(icon, size: size, color: Colors.white.withOpacity(opacity)),
    );
  }
}