// kelola_toko_page.dart
//
// Halaman Kelola Toko / Bengkel — Flutter
// Gaya mengikuti account.dart & settings_page.dart:
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/Theme/app_theme.dart';
import '/Theme/decor_background.dart';
import 'produk_layanan_page.dart';
import 'pesanan_masuk_page.dart';
import 'informasi_toko_page.dart';
import 'jam_operasional_page.dart';
import 'statistik_penjualan_page.dart';
import 'promosikan_toko_page.dart';

class KelolaTokoPage extends StatelessWidget {
  const KelolaTokoPage({super.key});

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
                  _TopBar(),
                  const SizedBox(height: 20),
                  _StoreHeader(),
                  const SizedBox(height: 24),
                  _StatsRow(),
                  const SizedBox(height: 24),
                  _SectionLabel(text: 'Kelola'),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    items: [
                      _MenuItemData(
                        icon: Icons.inventory_2_outlined,
                        label: 'Produk / Layanan',
                        trailing: '24',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProdukLayananPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.receipt_long_outlined,
                        label: 'Pesanan masuk',
                        trailing: '3 baru',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PesananMasukPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.storefront_outlined,
                        label: 'Informasi toko',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InformasiTokoPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.schedule_outlined,
                        label: 'Jam operasional',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JamOperasionalPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(text: 'Performa'),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    items: [
                      _MenuItemData(
                        icon: Icons.bar_chart_outlined,
                        label: 'Statistik penjualan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StatistikPenjualanPage(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.campaign_outlined,
                        label: 'Promosikan tokomu',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PromosikanTokoPage(),
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

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
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
          'Kelola Toko',
          style: GoogleFonts.manrope(
            color: kInk,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _StoreHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.storefront, color: kInk, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bengkel Rangga Jaya',
                style: GoogleFonts.manrope(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Buka sekarang',
                    style: GoogleFonts.manrope(
                      color: kInk.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '24', label: 'Produk')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(value: '156', label: 'Terjual')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(value: '4.8', label: 'Rating')),
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
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
              color: kInk.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

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
          color: kInk.withValues(alpha: 0.75),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  _MenuItemData({
    required this.icon,
    required this.label,
    this.trailing,
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
                      : BorderSide(color: kInk.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: kInk.withValues(alpha: 0.75)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.manrope(
                        color: kInk,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (item.trailing != null) ...[
                    Text(
                      item.trailing!,
                      style: GoogleFonts.manrope(
                        color: kInk.withValues(alpha: 0.6),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: kInk.withValues(alpha: 0.4),
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