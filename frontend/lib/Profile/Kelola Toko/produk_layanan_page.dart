// produk_layanan_page.dart
//
// Halaman Produk / Layanan — Flutter
// Card produk berbentuk kotak (grid 2 kolom), bukan memanjang horizontal.
// Gambar/ikon produk dibesarkan mengisi bagian atas kartu, dengan badge
// status ditumpuk (overlay) di pojok kanan atas gambar.
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
                            color: kInk.withValues(alpha: 0.75),
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

                  // ---------------- Grid kartu produk (kotak) ----------------
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _produk.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      return _ProdukCard(data: _produk[index]);
                    },
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

// ---------------------------------------------------------------------------
// Kartu produk — bentuk kotak: gambar besar mengisi bagian atas kartu
// (badge status ditumpuk di pojok kanan atas gambar), lalu nama, kategori
// & harga di bawahnya.
// ---------------------------------------------------------------------------
class _ProdukCard extends StatelessWidget {
  final _ProdukData data;
  const _ProdukCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isActive = data.status == 'Aktif';
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Gambar/ikon produk (besar, isi lebar kartu) ----------------
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kGradientBottom.withOpacity(0.15),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    // TODO: ganti Icon di bawah ini dengan Image.network(...)
                    // atau Image.asset(...) begitu foto produk sudah ada,
                    // pakai BoxFit.cover supaya tetap mengisi penuh area ini.
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.build_outlined,
                      color: kGradientBottom,
                      size: 40,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.85)
                            : Colors.grey.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data.status,
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ---------------- Detail produk ----------------
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: kInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.kategori,
                      style: GoogleFonts.manrope(
                        color: kInk.withOpacity(0.55),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.harga,
                      style: GoogleFonts.manrope(
                        color: kGradientBottom,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
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