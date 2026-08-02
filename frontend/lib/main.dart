import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/registration_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/background_decoration.dart';

void main() {
  runApp(const MyApp());
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
      home: const LandingPage(),
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
                            MaterialPageRoute(
                              builder: (context) => const RegistrationScreen(),
                            ),
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
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
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