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
import '../Theme/app_theme.dart';
import '../Theme/decor_background.dart';
import 'Edit Profile/edit_profile_page.dart';
import 'Nemu+/nemu_plus_page.dart';
import 'Kelola Toko/kelola_toko_page.dart';
import 'Pusat Bantuan/pusat_bantuan_page.dart';

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
                  const SizedBox(height: 20),
              _StatsRow(),
              const SizedBox(height: 24),
              _SectionLabel(text: 'Preferensi Aplikasi'),
              const SizedBox(height: 8),
              _MenuGroup(
                items: [
                  _MenuItemData(
                    icon: Icons.settings_outlined,
                    label: 'Pengaturan',
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
class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: kCream,
          child: Text(
            'RA',
            style: GoogleFonts.manrope(
              color: kInk,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rangga Adi',
                style: GoogleFonts.manrope(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kCream,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Penjual',
                      style: GoogleFonts.manrope(
                        color: kInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.star, size: 14, color: kInk),
                  const SizedBox(width: 2),
                  Text(
                    '4.8',
                    style: GoogleFonts.manrope(
                      color: kInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
// Baris statistik (Aktif / Selesai / Poin)
// ---------------------------------------------------------------------------
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '12', label: 'Aktif')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(value: '87', label: 'Selesai')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(value: '320', label: 'Poin')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.manrope(
              color: kInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: kInk.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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