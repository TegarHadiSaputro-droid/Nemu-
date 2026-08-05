import 'package:flutter/material.dart';

/// ============================================================
/// PAGE TRANSITIONS
/// Ganti semua `MaterialPageRoute` dengan `slideRoute(...)` supaya
/// transisi antar halaman lebih halus: slide dari kanan + fade,
/// alih-alih transisi platform default yang polos.
/// ============================================================
Route<T> slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
  );
}