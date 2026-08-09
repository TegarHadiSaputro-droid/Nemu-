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

class MitraCategoryPage extends StatefulWidget {
  const MitraCategoryPage({super.key});

  @override
  State<MitraCategoryPage> createState() => _MitraCategoryPageState();
}

class _MitraCategoryPageState extends State<MitraCategoryPage> {
  String _keyword = '';

  @override
  Widget build(BuildContext context) {
    final kategoriList = getKategoriMitra()
        .where((k) => k.nama.toLowerCase().contains(_keyword.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: mitraYellowTop,
      body: Container(
        decoration: const BoxDecoration(gradient: mitraBackgroundGradient),
        child: Stack(
          children: [
            ...mitraDecorCircles(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mitraAppBar('', titleColor: mitraTextDark, iconColor: mitraTextDark, titleSize: 22),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Butuh bantuan apa hari ini?',
                          style: mitraFont(size: 20, weight: FontWeight.bold, color: mitraTextDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pilih kategori, kami carikan tukang atau toko terbaik untukmu.',
                          style: mitraFont(size: 15, color: mitraTextDark.withValues(alpha: 0.75)),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: Colors.black45, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  onChanged: (v) => setState(() => _keyword = v),
                                  style: mitraFont(size: 13, color: mitraTextDark),
                                  decoration: InputDecoration(
                                    hintText: 'Cari kategori bantuan...',
                                    hintStyle: mitraFont(size: 12.5, color: Colors.black38),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: kategoriList.isEmpty
                        ? Center(
                            child: Text(
                              'Kategori tidak ditemukan',
                              style: mitraFont(size: 12.5, color: mitraTextDark.withValues(alpha: 0.6)),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: kategoriList.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 2.1,
                            ),
                            itemBuilder: (_, i) => _KategoriCard(kategori: kategoriList[i]),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MitraSubCategoryPage(kategori: kategori),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.10), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: mitraGreenBottom.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(kategori.icon, color: mitraGreenBottom, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  kategori.nama,
                  style: mitraFont(size: 13.5, weight: FontWeight.bold, color: mitraTextDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}