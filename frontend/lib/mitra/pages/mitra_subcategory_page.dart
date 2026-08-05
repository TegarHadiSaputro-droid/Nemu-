// mitra_subcategory_page.dart
//
// Halaman kedua alur Mitra: daftar sub-kategori di dalam satu kategori
// utama (contoh: kategori "Perbaikan" -> sub-kategori "Elektronik & Gadget").

import 'package:flutter/material.dart';
import '../models/mitra_models.dart';
import '../mitra_style.dart';
import 'mitra_provider_list_page.dart';

class MitraSubCategoryPage extends StatelessWidget {
  final KategoriUtama kategori;
  const MitraSubCategoryPage({super.key, required this.kategori});

  @override
  Widget build(BuildContext context) {
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
                  mitraAppBar(kategori.nama),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      'Pilih jenis layanan ${kategori.nama.toLowerCase()} yang kamu butuhkan',
                      style: mitraFont(size: 12.5, color: mitraCream.withValues(alpha: 0.9)),
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
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: kategori.subLayanan.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _SubLayananTile(sub: kategori.subLayanan[i]),
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

class _SubLayananTile extends StatelessWidget {
  final SubLayanan sub;
  const _SubLayananTile({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MitraProviderListPage(sub: sub),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: mitraGreenBottom.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(sub.icon, color: mitraGreenBottom, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.nama,
                      style: mitraFont(size: 13.5, weight: FontWeight.bold, color: mitraTextDark),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub.spesialisasi,
                      style: mitraFont(size: 10.5, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sub.penyedia.length} penyedia tersedia',
                      style: mitraFont(size: 10, weight: FontWeight.w700, color: mitraGreenBottom),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
