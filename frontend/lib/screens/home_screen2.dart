import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/Profile/account.dart';
import 'package:frontend/widgets/bottom_navbar.dart';
import 'package:frontend/screens/seller_home_screen.dart';
import 'package:frontend/screens/seller_langganan_screen.dart';

// ─────────────────────────────────────────────
//  Warna Palette (Konsisten dengan home_screen.dart)
// ─────────────────────────────────────────────
const Color _yellowTop   = Color(0xFFD9DF36);
const Color _greenBottom = Color(0xFF007C3F);

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({super.key});

  @override
  State<HomeScreen2> createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> with TickerProviderStateMixin {
  int _navIndex = 0;
  String _userName = 'Sobat Nemu';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted && doc.exists) {
        final data = doc.data();
        setState(() {
          _userName = (data?['nickname'] as String?) ?? (data?['name'] as String?) ?? 'Sobat Nemu';
          _photoUrl = data?['photoUrl'] as String?;
        });
      }
    } catch (_) {
      // Fail silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Base Gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_yellowTop, _greenBottom],
              ),
            ),
          ),

          // ── Dekorasi Playful Background ──
          Positioned(top: -40, right: -50, child: _blob(200, Colors.white.withValues(alpha: 0.12))),
          Positioned(top: 80, left: -60, child: _blob(160, Colors.white.withValues(alpha: 0.10))),
          Positioned(top: 220, right: 20, child: _blob(80, Colors.white.withValues(alpha: 0.08))),
          Positioned(top: 300, left: 30, child: _dot(18, Colors.white.withValues(alpha: 0.20))),
          Positioned(top: 340, right: 60, child: _dot(10, Colors.white.withValues(alpha: 0.18))),
          Positioned(bottom: 200, right: -40, child: _blob(150, const Color(0xFFD9DF36).withValues(alpha: 0.18))),
          Positioned(bottom: 350, left: 10, child: _dot(14, Colors.white.withValues(alpha: 0.15))),

          // ── Konten Utama ──
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _navIndex == 0
                          ? SellerDashboardBody(
                              key: const ValueKey('seller_dash'),
                              userName: _userName,
                              photoUrl: _photoUrl,
                            )
                          : _navIndex == 1
                              ? const SellerLanggananScreen(
                                  key: ValueKey('seller_langganan'),
                                )
                              : AccountPage(
                                  key: const ValueKey('seller_account'),
                                ),
                    ),
                  ),

                  // Bottom Nav Khusus Seller
                  NemuBottomNavbar(
                    currentIndex: _navIndex,
                    isSeller: true,
                    onTap: (i) => setState(() => _navIndex = i),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Background shapes helper
  // ─────────────────────────────────────────────
  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }

  Widget _dot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
