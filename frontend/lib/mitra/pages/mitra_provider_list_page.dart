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
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

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
                  mitraAppBar(widget.sub.nama),
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
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      decoration: const BoxDecoration(
                        color: mitraCream,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada penyedia dengan nama itu',
                                style: mitraFont(size: 12.5, color: Colors.black45),
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => _ProviderTile(sub: widget.sub, provider: filtered[i]),
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

class _ProviderTile extends StatelessWidget {
  final SubLayanan sub;
  final PenyediaJasa provider;
  const _ProviderTile({required this.sub, required this.provider});

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
              builder: (_) => MitraProviderDetailPage(sub: sub, provider: provider),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: mitraGreenBottom.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(provider.iconTipe, color: mitraGreenBottom, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.nama,
                            style: mitraFont(size: 13.5, weight: FontWeight.bold, color: mitraTextDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: provider.buka ? mitraGreenBottom.withValues(alpha: 0.12) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            provider.buka ? 'Buka' : 'Tutup',
                            style: mitraFont(
                              size: 9,
                              weight: FontWeight.bold,
                              color: provider.buka ? mitraGreenBottom : Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      provider.labelTipe,
                      style: mitraFont(size: 10.5, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text('${provider.rating}', style: mitraFont(size: 11, weight: FontWeight.bold, color: mitraTextDark)),
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on_rounded, size: 13, color: Colors.black38),
                        const SizedBox(width: 2),
                        Text('${provider.jarakKm} km', style: mitraFont(size: 11, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
