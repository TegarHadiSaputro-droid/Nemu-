// account_page.dart
//
// Halaman Akun — Flutter
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11
//
// Dependency yang dibutuhkan di pubspec.yaml:
//   dependencies:
//     flutter:
//       sdk: flutter
//     google_fonts: ^6.2.1
//
// Cara pakai: import file ini lalu panggil AccountPage() sebagai halaman/route.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Theme/app_theme.dart';
import '../Theme/decor_background.dart';
import 'logout_page.dart';
import 'Edit Profile/edit_profile_page.dart';
import 'Nemu+/nemu_plus_page.dart';
import 'Kelola Toko/kelola_toko_page.dart';
import 'Pusat Bantuan/pusat_bantuan_page.dart';
import '../settings/setting_page.dart'; // TODO: sesuaikan path jika lokasi setting_page.dart berbeda

// ---------------------------------------------------------------------------
// Halaman Akun
// (dipanggil dari home_page.dart lewat Navigator.push)
// ---------------------------------------------------------------------------
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.maybePop(context),
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.arrow_back, color: kInk),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Akun Saya',
                        style: GoogleFonts.manrope(
                          color: kInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProfileHeader(),
                  const SizedBox(height: 24),
              _SectionLabel(text: 'Preferensi Aplikasi'),
              const SizedBox(height: 8),
              _MenuGroup(
                items: [
                  _MenuItemData(
                    icon: Icons.settings_outlined,
                    label: 'Pengaturan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingPage(),
                        ),
                      );
                    },
                  ),
                  _MenuItemData(
                    icon: Icons.shield_outlined,
                    label: 'Keamanan Akun',
                  ),
                  _MenuItemData(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Nemu+',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NemuPlusPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel(text: 'Aktivitas'),
              const SizedBox(height: 8),
              _MenuGroup(
                items: [
                  _MenuItemData(
                    icon: Icons.favorite_border,
                    label: 'Favorit saya',
                  ),
                  _MenuItemData(
                    icon: Icons.storefront_outlined,
                    label: 'Kelola toko / bengkel',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KelolaTokoPage(),
                        ),
                      );
                    },
                  ),
                  _MenuItemData(
                    icon: Icons.star_border,
                    label: 'Ulasan saya',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel(text: 'Lainnya'),
              const SizedBox(height: 8),
              _MenuGroup(
                items: [
                  _MenuItemData(
                    icon: Icons.help_outline,
                    label: 'Pusat bantuan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PusatBantuanPage(),
                        ),
                      );
                    },
                  ),
                  _MenuItemData(
                    icon: Icons.description_outlined,
                    label: 'Syarat dan kebijakan privasi',
                  ),
                  _MenuItemData(
                    icon: Icons.logout,
                    label: 'Keluar',
                    isDanger: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LogoutPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header profil (avatar, nama, badge peran, rating)
// ---------------------------------------------------------------------------
class _ProfileHeader extends StatefulWidget {
  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? _photoUrl; // URL foto dari Firestore (diatur lewat EditProfilePage)
  String _userName = 'Nama Pengguna';

  // Role: setiap user otomatis 'Pembeli' sejak registrasi.
  // 'Penjual' cuma aktif kalau ada dokumen di collection 'seller'
  // (document ID = uid) dengan field status == 'active'. Selama masih
  // 'menunggu_verifikasi' atau belum daftar sama sekali, badge tetap 'Pembeli'.
  bool _isBuyer = true;
  bool _isSeller = false;
  double? _rating;

  String get _initials {
    final trimmed = _userName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Data dasar (nama, foto) tetap dari collection 'users'.
      final userDoc = await _firestore.collection('users').doc(uid).get();

      // Status penjual dibaca dari collection 'seller', document ID = uid.
      // Badge "Penjual" cuma muncul kalau field status == 'active'
      // (bukan cuma karena sudah pernah daftar / masih 'menunggu_verifikasi').
      final sellerDoc = await _firestore.collection('seller').doc(uid).get();

      if (mounted) {
        final userData = userDoc.data();
        final sellerData = sellerDoc.data();
        setState(() {
          _userName = (userData?['name'] as String?) ?? 'Nama Pengguna';
          _photoUrl = userData?['photoUrl'] as String?;
          _isBuyer = true;
          _isSeller =
              sellerDoc.exists && (sellerData?['status'] as String?) == 'active';
          _rating = (userData?['sellerRating'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      // Biarkan placeholder default kalau gagal fetch
      debugPrint('Gagal memuat data profil: $e');
    }
  }

  ImageProvider? get _avatarImage {
    if (_photoUrl != null) return NetworkImage(_photoUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: kCream,
          backgroundImage: _avatarImage,
          child: _avatarImage == null
              ? Text(
                  _initials,
                  style: GoogleFonts.manrope(
                    color: kInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: GoogleFonts.manrope(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Cuma satu badge yang tampil: default "Pembeli",
                  // otomatis berganti jadi "Penjual" begitu _isSeller true
                  // (nggak ditampilkan berdampingan lagi).
                  _RoleBadge(label: _isSeller ? 'Penjual' : 'Pembeli'),
                  if (_isSeller) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.star, size: 14, color: kInk),
                    const SizedBox(width: 2),
                    Text(
                      (_rating ?? 0).toStringAsFixed(1),
                      style: GoogleFonts.manrope(
                        color: kInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfilePage(),
              ),
            );
          },
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.chevron_right, color: kInk.withOpacity(0.6)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Badge kecil untuk role (Pembeli / Penjual)
// ---------------------------------------------------------------------------
class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          color: kInk,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Label section (Aktivitas / Pengaturan / Lainnya)
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          color: kInk.withOpacity(0.75),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grup menu (list item dalam satu kartu cream)
// ---------------------------------------------------------------------------
class _MenuItemData {
  final IconData icon;
  final String label;
  final bool isDanger;
  final VoidCallback? onTap;

  _MenuItemData({
    required this.icon,
    required this.label,
    this.isDanger = false,
    this.onTap,
  });
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuItemData> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return InkWell(
            onTap: item.onTap ?? () {},
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? const Radius.circular(14) : Radius.zero,
              bottom: isLast ? const Radius.circular(14) : Radius.zero,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(color: kInk.withOpacity(0.08)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: item.isDanger
                        ? Colors.red.shade700
                        : kInk.withOpacity(0.75),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.manrope(
                        color: item.isDanger ? Colors.red.shade700 : kInk,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!item.isDanger)
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: kInk.withOpacity(0.4),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}