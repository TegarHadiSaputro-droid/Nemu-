// mitra_category_page.dart
//
// Halaman pertama alur Mitra: menampilkan kategori utama penyedia jasa.
// Dibuka lewat tap tombol "Mitra" di bottom nav Beranda, atau lewat
// banner "Panggil Tukang Kapan Saja".

import 'package:flutter/material.dart';
import '../data/mitra_data.dart';
import '../models/mitra_models.dart';
import '../mitra_style.dart';
import 'mitra_subcategory_page.dart';

class MitraCategoryPage extends StatelessWidget {
  const MitraCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final kategoriList = getKategoriMitra();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: mitraBackgroundGradient),
        child: Stack(
          children: [
            ...mitraDecorCircles(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mitraAppBar('Mitra'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Butuh bantuan apa hari ini?',
                          style: mitraFont(size: 20, weight: FontWeight.bold, color: mitraCream),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pilih kategori, kami carikan tukang atau toko terbaik untukmu.',
                          style: mitraFont(size: 12.5, color: mitraCream.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      decoration: const BoxDecoration(
                        color: mitraCream,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: kategoriList.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.95,
                        ),
                        itemBuilder: (_, i) => _KategoriCard(kategori: kategoriList[i]),
                      ),
                    ),
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

class _KategoriCard extends StatelessWidget {
  final KategoriUtama kategori;
  const _KategoriCard({required this.kategori});

  @override
  Widget build(BuildContext context) {
    final totalPenyedia = kategori.subLayanan
        .fold<int>(0, (sum, s) => sum + s.penyedia.length);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MitraSubCategoryPage(kategori: kategori),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: mitraGreenBottom.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(kategori.icon, color: mitraGreenBottom, size: 24),
              ),
              const Spacer(),
              Text(
                kategori.nama,
                style: mitraFont(size: 15, weight: FontWeight.bold, color: mitraTextDark),
              ),
              const SizedBox(height: 4),
              Text(
                kategori.deskripsiSingkat,
                style: mitraFont(size: 10.5, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.groups_rounded, size: 13, color: mitraGreenBottom),
                  const SizedBox(width: 4),
                  Text(
                    '$totalPenyedia mitra siap panggil',
                    style: mitraFont(size: 10, weight: FontWeight.w700, color: mitraGreenBottom),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
