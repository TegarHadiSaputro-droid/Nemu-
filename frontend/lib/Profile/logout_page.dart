// logout_page.dart
//
// Halaman Konfirmasi Logout — Flutter

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Theme/app_theme.dart';
import '../Theme/decor_background.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../utils/page_transitions.dart';

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  bool _isLoggingOut = false;

  Future<void> _confirmLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      // Await ini penting — sebelum sign-out beneran selesai, currentUser
      // masih belum null. Kalau LoginScreen langsung dibuka duluan
      // (tanpa nunggu), LoginScreen bisa saja melihat currentUser masih
      // ada dan langsung redirect balik ke HomeScreen.
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        slideRoute(const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal keluar: $e')),
        );
      }
    }
  }

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
        child: Stack(
          children: [
            ...decorCircles(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kCream,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 48,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Keluar dari Akun?',
                            style: GoogleFonts.manrope(
                              color: kInk,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Apakah Anda yakin ingin keluar dari akun ini?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              color: kInk.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: kInk.withValues(alpha: 0.3)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: GoogleFonts.manrope(
                                      color: kInk,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoggingOut ? null : _confirmLogout,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isLoggingOut
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Keluar',
                                          style: GoogleFonts.manrope(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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