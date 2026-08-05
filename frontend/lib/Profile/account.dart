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
import 'package:flutter/foundation.dart' show kDebugMode;
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
                        onTap: () => _showLogoutConfirmation(context),
                      ),
                    ],
                  ),
                  // -------------------------------------------------------
                  // DEBUG ONLY — otomatis hilang di build production
                  // (kDebugMode == false saat `flutter run --release` /
                  // `flutter build`). Dipakai buat reset status "Penjual"
                  // ke "Pembeli" tanpa perlu buka Firebase Console manual.
                  // -------------------------------------------------------
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    _SectionLabel(text: 'Debug (dev only)'),
                    const SizedBox(height: 8),
                    _MenuGroup(
                      items: [
                        _MenuItemData(
                          icon: Icons.restart_alt,
                          label: 'Reset jadi Pembeli',
                          onTap: () => _resetToBuyer(context),
                        ),
                      ],
                    ),
                  ],
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
// Catatan: avatar di sini hanya menampilkan foto (read-only). Untuk
// mengganti foto profil, buka Edit Profil lewat tanda panah di kanan —
// fungsi pilih & upload foto ada di edit_profile_page.dart.
// ---------------------------------------------------------------------------
class _ProfileHeader extends StatefulWidget {
  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  ImageProvider? _avatarImageFor(String? photoUrl) {
    if (photoUrl != null) return NetworkImage(photoUrl);
    return null;
  }

  // Inisial avatar dihitung dari nama asli (bukan hardcode), supaya
  // konsisten dengan logika _avatarInitials di edit_profile_page.dart.
  String _initialsFor(String userName) {
    final name = userName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    // Kalau belum login, tampilkan versi default (Pembeli) tanpa stream.
    if (uid == null) {
      return _buildContent(
        context,
        userName: 'Nama Pengguna',
        photoUrl: null,
        isSeller: false,
        rating: null,
      );
    }

    // StreamBuilder mendengarkan perubahan dokumen user secara realtime.
    // Begitu pendaftaran gerai di Nemu+ berhasil dan backend meng-update
    // roles.seller jadi true, badge di sini otomatis berubah dari
    // "Pembeli" ke "Penjual" tanpa perlu keluar-masuk halaman.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final roles = data?['roles'] as Map<String, dynamic>?;

        return _buildContent(
          context,
          userName: (data?['name'] as String?) ?? 'Nama Pengguna',
          photoUrl: data?['photoUrl'] as String?,
          isSeller: (roles?['seller'] as bool?) ?? false,
          rating: (data?['sellerRating'] as num?)?.toDouble(),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required String userName,
    required String? photoUrl,
    required bool isSeller,
    required double? rating,
  }) {
    final avatarImage = _avatarImageFor(photoUrl);
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: kCream,
          backgroundImage: avatarImage,
          child: avatarImage == null
              ? Text(
                  _initialsFor(userName),
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
                userName,
                style: GoogleFonts.manrope(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _RoleBadge(label: isSeller ? 'Penjual' : 'Pembeli'),
                  if (isSeller) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.star, size: 14, color: kInk),
                    const SizedBox(width: 2),
                    Text(
                      (rating ?? 0).toStringAsFixed(1),
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

// ---------------------------------------------------------------------------
// DEBUG ONLY — reset roles.seller jadi false di Firestore, supaya badge
// balik ke "Pembeli" tanpa perlu ubah data manual lewat Firebase Console.
// StreamBuilder di _ProfileHeader otomatis nangkep perubahan ini.
// ---------------------------------------------------------------------------
Future<void> _resetToBuyer(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'roles': {'seller': false},
      },
      SetOptions(merge: true),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status di-reset jadi Pembeli')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal reset: $e')),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog konfirmasi Keluar (card di tengah layar, bukan halaman terpisah)
// ---------------------------------------------------------------------------
void _showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.logout,
                  size: 26,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Yakin ingin keluar?',
                style: GoogleFonts.manrope(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kamu perlu login kembali untuk mengakses akunmu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: kInk.withOpacity(0.65),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kInk,
                        side: BorderSide(color: kInk.withOpacity(0.25)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: proses logout & arahkan ke halaman login
                        Navigator.pop(context);
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: kCream,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Ya, Keluar',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}