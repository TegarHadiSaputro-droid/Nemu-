// pesanan_masuk_page.dart
//
// Halaman Pesanan Masuk — Flutter
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/Theme/app_theme.dart';
import '/Theme/decor_background.dart';

class PesananMasukPage extends StatelessWidget {
  const PesananMasukPage({super.key});

  static const List<_PesananData> _pesanan = [
    _PesananData(
      nama: 'Budi Santoso',
      layanan: 'Ganti Oli Mesin',
      waktu: 'Hari ini, 10:30',
      status: 'Baru',
    ),
    _PesananData(
      nama: 'Siti Aminah',
      layanan: 'Servis Rem Cakram',
      waktu: 'Hari ini, 09:15',
      status: 'Baru',
    ),
    _PesananData(
      nama: 'Joko Prasetyo',
      layanan: 'Tune Up Motor',
      waktu: 'Hari ini, 08:00',
      status: 'Baru',
    ),
    _PesananData(
      nama: 'Dewi Lestari',
      layanan: 'Ganti Ban Luar',
      waktu: 'Kemarin, 16:45',
      status: 'Selesai',
    ),
  ];

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
                  ..._pesanan.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PesananCard(data: p),
                      )),
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
          'Pesanan Masuk',
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

class _PesananData {
  final String nama;
  final String layanan;
  final String waktu;
  final String status;
  const _PesananData({
    required this.nama,
    required this.layanan,
    required this.waktu,
    required this.status,
  });
}

class _PesananCard extends StatelessWidget {
  final _PesananData data;
  const _PesananCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isBaru = data.status == 'Baru';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kGradientBottom.withValues(alpha: 0.15),
                child: Text(
                  data.nama.substring(0, 1),
                  style: GoogleFonts.manrope(
                    color: kGradientBottom,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.nama,
                      style: GoogleFonts.manrope(
                        color: kInk,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      data.layanan,
                      style: GoogleFonts.manrope(
                        color: kInk.withValues(alpha: 0.6),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isBaru
                      ? kGradientBottom.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.status,
                  style: GoogleFonts.manrope(
                    color: isBaru ? kGradientBottom : Colors.grey.shade700,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 13, color: kInk.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                data.waktu,
                style: GoogleFonts.manrope(
                  color: kInk.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isBaru) ...[
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Tolak',
                    style: GoogleFonts.manrope(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kInk,
                    foregroundColor: kCream,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Terima',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}