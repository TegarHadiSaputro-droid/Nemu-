// mitra_review_page.dart
//
// Halaman "Lihat Semua Ulasan", dibuka dari tombol di
// mitra_provider_detail_page.dart. Menampilkan ringkasan rating (gaya
// Google Maps: rata-rata + distribusi bintang) lalu daftar lengkap ulasan
// di dalam satu kotak besar. Setiap ulasan punya tombol "Setuju" (like)
// supaya pengguna lain bisa menandai ulasan yang menurutnya membantu.

import 'package:flutter/material.dart';
import '../models/mitra_models.dart';
import '../mitra_style.dart';

class MitraReviewPage extends StatefulWidget {
  final SubLayanan sub;
  final PenyediaJasa provider;
  const MitraReviewPage({super.key, required this.sub, required this.provider});

  @override
  State<MitraReviewPage> createState() => _MitraReviewPageState();
}

class _MitraReviewPageState extends State<MitraReviewPage> {
  late final List<Ulasan> _semuaUlasan = ulasanDummyUntuk(widget.provider);

  // Status "sudah disetujui" per index ulasan, disimpan di halaman ini
  // (lokal saja, belum tersambung backend) supaya tap like langsung
  // kelihatan efeknya tanpa reload data.
  late final Set<int> _disetujui = {};

  // null = tampilkan semua ulasan. Kalau diisi (1-5), daftar ulasan
  // difilter supaya cuma menampilkan ulasan dengan rating bintang itu.
  int? _filterBintang;

  void _toggleSetuju(int index) {
    setState(() {
      if (_disetujui.contains(index)) {
        _disetujui.remove(index);
      } else {
        _disetujui.add(index);
      }
    });
  }

  void _pilihFilter(int bintang) {
    setState(() => _filterBintang = _filterBintang == bintang ? null : bintang);
  }

  // Index asli di _semuaUlasan yang lolos filter aktif, supaya status like
  // (_disetujui) tetap merujuk ke ulasan yang benar walau daftar difilter.
  List<int> get _indeksTampil {
    return List.generate(_semuaUlasan.length, (i) => i)
        .where((i) => _filterBintang == null || _semuaUlasan[i].rating.round() == _filterBintang)
        .toList();
  }

  double get _rataRata {
    if (_semuaUlasan.isEmpty) return widget.provider.rating;
    final total = _semuaUlasan.fold<double>(0, (a, b) => a + b.rating);
    return total / _semuaUlasan.length;
  }

  Map<int, int> get _distribusiBintang {
    final map = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final u in _semuaUlasan) {
      final bintang = u.rating.round().clamp(1, 5);
      map[bintang] = (map[bintang] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

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
                  mitraAppBar('Ulasan Pelanggan', titleColor: mitraTextDark, iconColor: mitraTextDark, titleSize: 17),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 15, color: mitraTextDark),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            provider.lokasi,
                            style: mitraFont(size: 12, color: mitraTextDark.withValues(alpha: 0.85)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RingkasanRating(rataRata: _rataRata, distribusi: _distribusiBintang, total: _semuaUlasan.length),
                          const SizedBox(height: 14),
                          _FilterBintangRow(
                            distribusi: _distribusiBintang,
                            aktif: _filterBintang,
                            onPilih: _pilihFilter,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _filterBintang == null
                                ? 'Semua Ulasan (${_semuaUlasan.length})'
                                : 'Ulasan Bintang $_filterBintang (${_indeksTampil.length})',
                            style: mitraFont(size: 14, weight: FontWeight.bold, color: mitraTextDark),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.15)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: _indeksTampil.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: Text(
                                        'Belum ada ulasan bintang $_filterBintang',
                                        style: mitraFont(size: 12, color: mitraTextDark.withValues(alpha: 0.6)),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(_indeksTampil.length, (pos) {
                                      final i = _indeksTampil[pos];
                                      final terakhir = pos == _indeksTampil.length - 1;
                                      return Column(
                                        children: [
                                          _UlasanItem(
                                            ulasan: _semuaUlasan[i],
                                            disetujui: _disetujui.contains(i),
                                            onToggleSetuju: () => _toggleSetuju(i),
                                          ),
                                          if (!terakhir) Divider(height: 24, color: mitraGreenBottom.withValues(alpha: 0.10)),
                                          if (terakhir) const SizedBox(height: 14),
                                        ],
                                      );
                                    }),
                                  ),
                          ),
                        ],
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

/// Deretan tombol filter bintang 1-5. Tap salah satu untuk menampilkan
/// hanya ulasan dengan rating itu; tap lagi tombol yang sama untuk
/// kembali menampilkan semua ulasan.
class _FilterBintangRow extends StatelessWidget {
  final Map<int, int> distribusi;
  final int? aktif;
  final ValueChanged<int> onPilih;
  const _FilterBintangRow({required this.distribusi, required this.aktif, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final bintang = 5 - i;
          final jumlah = distribusi[bintang] ?? 0;
          final terpilih = aktif == bintang;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onPilih(bintang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: terpilih ? mitraGreenBottom : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: terpilih ? mitraGreenBottom : mitraTextDark.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$bintang', style: mitraFont(size: 12, weight: FontWeight.bold, color: terpilih ? Colors.white : mitraTextDark)),
                  const SizedBox(width: 3),
                  Icon(Icons.star_rounded, size: 14, color: terpilih ? Colors.white : Colors.amber),
                  const SizedBox(width: 4),
                  Text('($jumlah)', style: mitraFont(size: 10.5, color: terpilih ? Colors.white70 : mitraTextDark.withValues(alpha: 0.55))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Kartu putih ringkasan rating, meniru tampilan ringkasan rating Google:
/// deretan bar per bintang (5 -> 1) di kiri, angka rata-rata + bintang +
/// jumlah ulasan di kanan.
class _RingkasanRating extends StatelessWidget {
  final double rataRata;
  final Map<int, int> distribusi;
  final int total;
  const _RingkasanRating({required this.rataRata, required this.distribusi, required this.total});

  String get _label => rataRata.toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: List.generate(5, (i) {
                final bintang = 5 - i;
                final jumlah = distribusi[bintang] ?? 0;
                final proporsi = total == 0 ? 0.0 : jumlah / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('$bintang', style: mitraFont(size: 11, weight: FontWeight.bold, color: mitraTextDark)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: proporsi,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(Colors.amber),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(_label, style: mitraFont(size: 30, weight: FontWeight.bold, color: mitraTextDark)),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < rataRata.round();
                    return Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, size: 15, color: Colors.amber);
                  }),
                ),
                const SizedBox(height: 2),
                Text('$total ulasan', style: mitraFont(size: 10.5, color: mitraTextDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu baris ulasan di dalam kotak besar, lengkap dengan tombol
/// "Setuju" (like) di bawah komentar.
class _UlasanItem extends StatelessWidget {
  final Ulasan ulasan;
  final bool disetujui;
  final VoidCallback onToggleSetuju;
  const _UlasanItem({required this.ulasan, required this.disetujui, required this.onToggleSetuju});

  int get _jumlahSetuju => ulasan.jumlahSetujuAwal + (disetujui ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: mitraGreenBottom.withValues(alpha: 0.12),
                child: Text(
                  ulasan.nama.substring(0, 1),
                  style: mitraFont(size: 13, weight: FontWeight.bold, color: mitraGreenBottom),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ulasan.nama, style: mitraFont(size: 12.5, weight: FontWeight.bold, color: mitraTextDark)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = i < ulasan.rating.round();
                          return Icon(
                            filled ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 13,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: 6),
                        Text(ulasan.waktu, style: mitraFont(size: 10, color: Colors.black45)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(ulasan.komentar, style: mitraFont(size: 11.5, color: Colors.black87, height: 1.4)),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onToggleSetuju,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: disetujui ? mitraGreenBottom.withValues(alpha: 0.12) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: disetujui ? mitraGreenBottom.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    disetujui ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                    size: 13,
                    color: disetujui ? mitraGreenBottom : Colors.black45,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _jumlahSetuju == 0 ? 'Setuju' : 'Setuju ($_jumlahSetuju)',
                    style: mitraFont(size: 10.5, weight: FontWeight.bold, color: disetujui ? mitraGreenBottom : Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}