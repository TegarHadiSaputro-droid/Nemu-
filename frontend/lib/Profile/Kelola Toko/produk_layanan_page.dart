// produk_layanan_page.dart
//
// Halaman Produk / Layanan — Flutter
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/Theme/app_theme.dart';
import '/Theme/decor_background.dart';

class ProdukLayananPage extends StatelessWidget {
  const ProdukLayananPage({super.key});

  static const List<_ProdukData> _produk = [
    _ProdukData(
      nama: 'Ganti Oli Mesin',
      kategori: 'Servis rutin',
      harga: 'Rp 85.000',
      status: 'Aktif',
    ),
    _ProdukData(
      nama: 'Servis Rem Cakram',
      kategori: 'Perbaikan',
      harga: 'Rp 120.000',
      status: 'Aktif',
    ),
    _ProdukData(
      nama: 'Tune Up Motor',
      kategori: 'Servis rutin',
      harga: 'Rp 150.000',
      status: 'Aktif',
    ),
    _ProdukData(
      nama: 'Ganti Ban Luar',
      kategori: 'Sparepart',
      harga: 'Rp 250.000',
      status: 'Nonaktif',
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
                  _TopBar(title: 'Produk / Layanan'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_produk.length} item terdaftar',
                          style: GoogleFonts.manrope(
                            color: kInk.withOpacity(0.75),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kCream,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 14, color: kInk),
                              const SizedBox(width: 4),
                              Text(
                                'Tambah',
                                style: GoogleFonts.manrope(
                                  color: kInk,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._produk.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProdukCard(data: p),
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
  final String title;
  const _TopBar({required this.title});

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
          title,
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

class _ProdukData {
  final String nama;
  final String kategori;
  final String harga;
  final String status;
  const _ProdukData({
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.status,
  });
}

class _ProdukCard extends StatelessWidget {
  final _ProdukData data;
  const _ProdukCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isActive = data.status == 'Aktif';
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kGradientBottom.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.build_outlined, color: kGradientBottom),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    '${data.kategori} • ${data.harga}',
                    style: GoogleFonts.manrope(
                      color: kInk.withOpacity(0.6),
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
                color: isActive
                    ? Colors.green.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data.status,
                style: GoogleFonts.manrope(
                  color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}