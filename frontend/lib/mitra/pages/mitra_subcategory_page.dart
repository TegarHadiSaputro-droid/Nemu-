// mitra_subcategory_page.dart
//
// Halaman kedua alur Mitra: daftar sub-kategori di dalam satu kategori
// utama (contoh: kategori "Perbaikan" -> sub-kategori "Elektronik & Gadget").

import 'package:flutter/material.dart';
import '../models/mitra_models.dart';
import '../mitra_style.dart';
import 'mitra_provider_list_page.dart';

class MitraSubCategoryPage extends StatefulWidget {
  final KategoriUtama kategori;
  const MitraSubCategoryPage({super.key, required this.kategori});

  @override
  State<MitraSubCategoryPage> createState() => _MitraSubCategoryPageState();
}

class _MitraSubCategoryPageState extends State<MitraSubCategoryPage> {
  String _keyword = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.kategori.subLayanan
        .where((s) => s.nama.toLowerCase().contains(_keyword.toLowerCase()))
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
                  mitraAppBar(widget.kategori.nama, titleColor: mitraTextDark, iconColor: mitraTextDark),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih jenis layanan ${widget.kategori.nama.toLowerCase()} yang kamu butuhkan',
                          style: mitraFont(size: 12.5, color: mitraTextDark.withValues(alpha: 0.75)),
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
                                    hintText: 'Cari jenis layanan...',
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
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Jenis layanan tidak ditemukan',
                              style: mitraFont(size: 12.5, color: mitraTextDark.withValues(alpha: 0.6)),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _SubLayananTile(sub: filtered[i]),
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