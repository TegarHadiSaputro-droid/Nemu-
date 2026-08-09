// mitra_provider_list_page.dart
//
// Halaman ketiga alur Mitra: daftar toko/orang yang bisa dipanggil untuk
// satu sub-kategori tertentu. Ada search bar aktif buat nyaring nama.

import 'package:flutter/material.dart';
import '../models/mitra_models.dart';
import '../mitra_style.dart';
import 'mitra_provider_detail_page.dart';

class MitraProviderListPage extends StatefulWidget {
  final SubLayanan sub;
  const MitraProviderListPage({super.key, required this.sub});

  @override
  State<MitraProviderListPage> createState() => _MitraProviderListPageState();
}

class _MitraProviderListPageState extends State<MitraProviderListPage> {
  String _keyword = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.sub.penyedia
        .where((p) => p.nama.toLowerCase().contains(_keyword.toLowerCase()))
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
                  mitraAppBar(widget.sub.nama, titleColor: mitraTextDark, iconColor: mitraTextDark),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Container(
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
                                hintText: 'Cari nama tukang atau toko...',
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
                  ),
                  Expanded(
                    child: ValueListenableBuilder<List<String>>(
                      valueListenable: mitraTersimpanNotifier,
                      builder: (context, tersimpanList, _) {
                        // Yang sudah disimpan selalu naik ke paling atas.
                        // Di antara sesama yang tersimpan, yang PALING
                        // BARU disimpan ditaruh paling depan (mengikuti
                        // urutan di tersimpanList, index 0 = paling baru).
                        // Yang belum disimpan tetap diurutkan dari rating
                        // tertinggi seperti biasa.
                        final terurut = List<PenyediaJasa>.from(filtered)
                          ..sort((a, b) {
                            final aIndex = tersimpanList.indexOf(a.nama);
                            final bIndex = tersimpanList.indexOf(b.nama);
                            final aTersimpan = aIndex != -1;
                            final bTersimpan = bIndex != -1;
                            if (aTersimpan && bTersimpan) {
                              return aIndex.compareTo(bIndex);
                            }
                            if (aTersimpan != bTersimpan) {
                              return aTersimpan ? -1 : 1;
                            }
                            return b.rating.compareTo(a.rating);
                          });

                        if (terurut.isEmpty) {
                          return Center(
                            child: Text(
                              'Tidak ada penyedia dengan nama itu',
                              style: mitraFont(size: 12.5, color: mitraTextDark.withValues(alpha: 0.6)),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: terurut.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.55,
                          ),
                          itemBuilder: (_, i) => _ProviderTile(
                            key: ValueKey(terurut[i].nama),
                            sub: widget.sub,
                            provider: terurut[i],
                          ),
                        );
                      },
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

class _ProviderTile extends StatefulWidget {
  final SubLayanan sub;
  final PenyediaJasa provider;
  const _ProviderTile({super.key, required this.sub, required this.provider});

  @override
  State<_ProviderTile> createState() => _ProviderTileState();
}

class _ProviderTileState extends State<_ProviderTile> {
  SubLayanan get sub => widget.sub;
  PenyediaJasa get provider => widget.provider;

  void _toggleSimpan() {
    toggleMitraTersimpan(provider);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MitraProviderDetailPage(sub: sub, provider: provider),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.12), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo & nama toko ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: mitraGreenBottom.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(provider.iconTipe, color: mitraGreenBottom, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.nama,
                      style: mitraFont(size: 12.5, weight: FontWeight.bold, color: mitraTextDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // ── Spesialisasi singkat ──
              Text(
                sub.spesialisasi,
                style: mitraFont(size: 10, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // ── Lokasi/area mitra ──
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 11, color: mitraGreenBottom.withValues(alpha: 0.65)),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      provider.lokasi,
                      style: mitraFont(size: 9.5, color: Colors.black45),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // ── Status buka/tutup, rating, & ikon simpan ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.sedangBuka ? mitraGreenBottom.withValues(alpha: 0.12) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      provider.sedangBuka ? 'Buka' : 'Tutup',
                      style: mitraFont(
                        size: 10,
                        weight: FontWeight.bold,
                        color: provider.sedangBuka ? mitraGreenBottom : Colors.black45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text('${provider.rating}', style: mitraFont(size: 11, weight: FontWeight.bold, color: mitraTextDark)),
                  const Spacer(),
                  ValueListenableBuilder<List<String>>(
                    valueListenable: mitraTersimpanNotifier,
                    builder: (context, tersimpanList, _) {
                      final tersimpan = tersimpanList.contains(provider.nama);
                      return GestureDetector(
                        onTap: _toggleSimpan,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 23,
                          height: 23,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tersimpan ? mitraGreenBottom : Colors.white,
                            border: Border.all(
                              color: tersimpan ? mitraGreenBottom : Colors.black26,
                            ),
                          ),
                          child: Icon(
                            tersimpan ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 12,
                            color: tersimpan ? Colors.white : Colors.black45,
                          ),
                        ),
                      );
                    },
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