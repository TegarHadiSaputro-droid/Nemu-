// main.dart
//
// Entry point aplikasi. Halaman kosong (Beranda) dengan satu lingkaran
// avatar di pojok kanan atas. Ketuk lingkaran itu untuk pindah ke
// Halaman Akun (profil/account_page.dart) lewat Navigator.push.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Theme/app_theme.dart'; // berisi kInk, kCream, kGradientTop, kGradientBottom
import 'Profile/account.dart'; // berisi AccountPage
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/registration_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; // berisi HomeScreen
import 'theme/app_colors.dart';
import 'widgets/background_decoration.dart';
import 'utils/page_transitions.dart';
import 'Theme/app_theme.dart'; // berisi kInk, kCream, kGradientTop, kGradientBottom
import 'Profile/account.dart'; // berisi AccountPage
import 'package:provider/provider.dart';
import 'localization/language_provider.dart'; // berisi LanguageProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nemu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.manropeTextTheme(),
      ),
      home: const AuthGate(),
    );
  }
}

/// ============================================================
/// AUTH GATE
/// Menentukan halaman pertama yang tampil berdasarkan status login.
/// Firebase Auth sendiri sudah otomatis menyimpan sesi login di device,
/// jadi authStateChanges() akan langsung mengembalikan user yang sudah
/// login sebelumnya tanpa perlu login ulang setiap buka aplikasi.
/// ============================================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Masih ngecek status login ke Firebase, tampilkan splash sebentar.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = snapshot.data;

        // Sudah pernah login sebelumnya (sesi tersimpan otomatis oleh
        // Firebase) -> langsung ke Beranda, tidak perlu login ulang.
        if (user != null) {
          return const HomeScreen();
        }

        // Belum login -> tampilkan halaman awal seperti biasa.
        return const LandingPage();
      },
    );
  }
}

/// Splash sederhana selagi menunggu Firebase mengecek status login.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.beige),
        ),
      ),
    );
  }
}

/// ============================================================
/// LANDING PAGE
/// Logo ditaruh di dalam lingkaran beige supaya kontras dan tidak
/// blend ke background gradient. Di bagian bawah ada dua tombol:
/// "Masuk" (outline) dan "Daftar" (solid). BackgroundDecoration
/// menambah elemen dekoratif tipis supaya area kosong tidak
/// terasa kopong.
/// ============================================================
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: BackgroundDecoration()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // ---------- LOGO DENGAN BACKDROP LINGKARAN ----------
                    Container(
                      width: 160,
                      height: 160,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.beige,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/logo.png'),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Nemu',
                      style: GoogleFonts.manrope(
                        color: AppColors.beige,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belanja kebutuhan segar jadi lebih mudah',
                      style: GoogleFonts.manrope(
                        color: AppColors.beige.withOpacity(0.85),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(flex: 4),

                    // ---------- TOMBOL DAFTAR (solid) ----------
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            slideRoute(const RegistrationScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.nightmare,
                          foregroundColor: AppColors.beige,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Daftar',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.beige,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---------- TOMBOL MASUK (outline) ----------
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            slideRoute(const LoginScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.beige,
                          side: BorderSide(
                            color: AppColors.beige.withOpacity(0.8),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Masuk',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.beige,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}