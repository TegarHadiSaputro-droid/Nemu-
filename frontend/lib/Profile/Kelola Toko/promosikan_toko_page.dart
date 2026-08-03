// promosikan_toko_page.dart
//
// Halaman Promosikan Tokomu — Flutter
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/Theme/app_theme.dart';
import '/Theme/decor_background.dart';

class PromosikanTokoPage extends StatelessWidget {
  const PromosikanTokoPage({super.key});

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
                  _HeroBanner(),
                  const SizedBox(height: 24),
                  Text(
                    'Pilih paket promosi',
                    style: GoogleFonts.manrope(
                      color: kInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PromoCard(
                    icon: Icons.trending_up,
                    title: 'Boost 3 Hari',
                    subtitle: 'Tampil di posisi atas pencarian',
                    price: 'Rp 15.000',
                  ),
                  const SizedBox(height: 10),
                  _PromoCard(
                    icon: Icons.rocket_launch_outlined,
                    title: 'Boost 7 Hari',
                    subtitle: 'Jangkauan lebih luas seminggu penuh',
                    price: 'Rp 30.000',
                    highlight: true,
                    badge: 'Populer',
                  ),
                  const SizedBox(height: 10),
                  _PromoCard(
                    icon: Icons.home_outlined,
                    title: 'Tampilkan di Beranda',
                    subtitle: 'Muncul di rekomendasi halaman utama',
                    price: 'Rp 20.000',
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
          'Promosikan Tokomu',
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

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kGradientBottom,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.campaign, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toko sepi pelanggan?',
                  style: GoogleFonts.manrope(
                    color: kInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Naikkan tokomu ke posisi atas biar makin dilirik pembeli.',
                  style: GoogleFonts.manrope(
                    color: kInk.withOpacity(0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final bool highlight;
  final String? badge;

  const _PromoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    this.highlight = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(14),
          border: highlight
              ? Border.all(color: kGradientBottom, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: kGradientBottom),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          color: kInk,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kGradientBottom,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: GoogleFonts.manrope(
                              color: kCream,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      color: kInk.withOpacity(0.6),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: GoogleFonts.manrope(
                color: kInk,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}