// main.dart
//
// Entry point aplikasi. Halaman kosong (Beranda) dengan satu lingkaran
// avatar di pojok kanan atas. Ketuk lingkaran itu untuk pindah ke
// Halaman Akun (profil/account_page.dart) lewat Navigator.push.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Theme/app_theme.dart'; // berisi kInk, kCream, kGradientTop, kGradientBottom
import 'Profile/account.dart'; // berisi AccountPage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pasar & Perbaikan App',
      theme: ThemeData(
        textTheme: GoogleFonts.manropeTextTheme().apply(
          bodyColor: kInk,
          displayColor: kInk,
        ),
        scaffoldBackgroundColor: kGradientBottom,
      ),
      home: const HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman kosong (Beranda) — hanya berisi lingkaran avatar di pojok kanan atas
// ---------------------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kGradientTop, kGradientBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountPage(),
                    ),
                  );
                },
                customBorder: const CircleBorder(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kCream,
                    shape: BoxShape.circle,
                    border: Border.all(color: kInk.withOpacity(0.15), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'RA',
                    style: GoogleFonts.manrope(
                      color: kInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}