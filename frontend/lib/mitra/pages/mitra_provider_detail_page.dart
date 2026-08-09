// mitra_provider_detail_page.dart
//
// Halaman terakhir alur Mitra: profil lengkap satu penyedia jasa —
// menggambarkan siapa dia, spesialisasinya apa, rating, dan tombol
// aksi (chat / panggil sekarang) di bagian bawah.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mitra_models.dart';
import '../mitra_style.dart';
import 'mitra_review_page.dart';

class MitraProviderDetailPage extends StatefulWidget {
  final SubLayanan sub;
  final PenyediaJasa provider;
  const MitraProviderDetailPage({super.key, required this.sub, required this.provider});

  @override
  State<MitraProviderDetailPage> createState() => _MitraProviderDetailPageState();
}

class _MitraProviderDetailPageState extends State<MitraProviderDetailPage> {
  SubLayanan get sub => widget.sub;
  PenyediaJasa get provider => widget.provider;

  bool get _online => statusOnlineUntuk(provider);

  String _cariLayanan = '';

  void _toggleFavorit() {
    toggleMitraTersimpan(provider);
  }

  List<String> get _tagTerfilter => sub.tagSpesialisasi
      .where((t) => t.toLowerCase().contains(_cariLayanan.toLowerCase()))
      .toList();

  String get _deskripsi {
    final peran = provider.isToko ? 'usaha jasa' : 'tenaga ahli lepas (kang)';
    return '${provider.nama} adalah $peran yang melayani ${sub.nama.toLowerCase()} '
        'di area ${provider.lokasi}. Spesialisasi utamanya mencakup '
        '${sub.spesialisasi.toLowerCase()}. Sejauh ini sudah menyelesaikan '
        '${provider.pesananSelesai} pesanan dengan rating ${provider.rating}★ dari pelanggan.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mitraYellowTop,
      body: Container(
        decoration: const BoxDecoration(gradient: mitraBackgroundGradient),
        child: Stack(
          children: [
            ...mitraDecorCircles(),
            SafeArea(
              child: Column(
                children: [
                  mitraAppBar(
                    '',
                    iconColor: mitraTextDark,
                    actions: [
                      ValueListenableBuilder<List<String>>(
                        valueListenable: mitraTersimpanNotifier,
                        builder: (context, tersimpanList, _) {
                          return _TombolSimpanMitra(
                            tersimpan: tersimpanList.contains(provider.nama),
                            onTap: _toggleFavorit,
                          );
                        },
                      ),
                      _MenuAksiMitra(sub: sub, provider: provider),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        color: mitraCream,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 6)),
                                        ],
                                      ),
                                      child: Icon(provider.iconTipe, color: mitraGreenBottom, size: 38),
                                    ),
                                    Positioned(
                                      right: 2,
                                      bottom: 2,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _online ? const Color(0xFF34C759) : Colors.grey.shade400,
                                          border: Border.all(color: mitraCream, width: 2.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  provider.nama,
                                  textAlign: TextAlign.center,
                                  style: mitraFont(size: 18, weight: FontWeight.bold, color: mitraCream),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${provider.labelTipe} • ${sub.nama}',
                                  style: mitraFont(size: 11.5, color: mitraCream.withValues(alpha: 0.85)),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _online ? const Color(0xFF34C759) : Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _online ? 'Sedang online' : 'Sedang offline',
                                      style: mitraFont(size: 11, weight: FontWeight.w700, color: mitraCream.withValues(alpha: 0.95)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.55),
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                            decoration: const BoxDecoration(
                              color: mitraCream,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Statistik singkat ──
                                Row(
                                  children: [
                                    _JamOperasionalBox(provider: provider),
                                    const SizedBox(width: 10),
                                    _StatBox(icon: Icons.star_rounded, iconColor: Colors.amber, label: 'Rating', value: '${provider.rating}'),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: provider.sedangBuka ? mitraGreenBottom.withValues(alpha: 0.12) : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        provider.sedangBuka ? 'Sedang Buka' : 'Sedang Tutup',
                                        style: mitraFont(size: 10.5, weight: FontWeight.bold, color: provider.sedangBuka ? mitraGreenBottom : Colors.black54),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      provider.labelHitungMundur,
                                      style: mitraFont(size: 10.5, color: Colors.black45),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                Text('Tentang', style: mitraFont(size: 14, weight: FontWeight.bold, color: mitraTextDark)),
                                const SizedBox(height: 6),
                                Text(_deskripsi, style: mitraFont(size: 12.5, color: Colors.black87, height: 1.5)),
                                const SizedBox(height: 20),

                                Row(
                                  children: [
                                    Text('Layanan', style: mitraFont(size: 14, weight: FontWeight.bold, color: mitraTextDark)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 32,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.30)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.search_rounded, size: 15, color: mitraTextDark.withValues(alpha: 0.45)),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: TextField(
                                                onChanged: (v) => setState(() => _cariLayanan = v),
                                                style: mitraFont(size: 11, color: mitraTextDark),
                                                decoration: InputDecoration(
                                                  hintText: 'Cari layanan di toko ini',
                                                  hintStyle: mitraFont(size: 10.5, color: mitraTextDark.withValues(alpha: 0.4)),
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (sub.labelEstimasiTarif != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: mitraGreenBottom.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          sub.labelEstimasiTarif!,
                                          style: mitraFont(size: 10, weight: FontWeight.bold, color: mitraGreenBottom),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _tagTerfilter.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Text(
                                          'Layanan tidak ditemukan',
                                          style: mitraFont(size: 11.5, color: mitraTextDark.withValues(alpha: 0.5)),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 132,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: _tagTerfilter.length,
                                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                                          itemBuilder: (_, i) {
                                            final tarif = sub.tingkatKebutuhan.isEmpty
                                                ? null
                                                : sub.tingkatKebutuhan[i % sub.tingkatKebutuhan.length];
                                            return _FotoLayananTile(label: _tagTerfilter[i], tarif: tarif);
                                          },
                                        ),
                                      ),
                                const SizedBox(height: 20),

                                Text('Spesialisasi', style: mitraFont(size: 14, weight: FontWeight.bold, color: mitraTextDark)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: sub.tagSpesialisasi
                                      .map((tag) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: mitraGreenBottom.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.25)),
                                            ),
                                            child: Text(tag, style: mitraFont(size: 11, weight: FontWeight.w700, color: mitraGreenBottom)),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 20),

                                Text('Lokasi', style: mitraFont(size: 14, weight: FontWeight.bold, color: mitraTextDark)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.map_rounded, size: 16, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(provider.lokasi, style: mitraFont(size: 12, color: Colors.black87))),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                Builder(builder: (context) {
                                  final semuaUlasan = ulasanDummyUntuk(provider);
                                  final preview = semuaUlasan.take(3).toList();
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Ulasan Pelanggan',
                                              style: mitraFont(size: 14, weight: FontWeight.bold, color: mitraTextDark),
                                            ),
                                          ),
                                          if (semuaUlasan.length > 3)
                                            TextButton(
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => MitraReviewPage(sub: sub, provider: provider),
                                                ),
                                              ),
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                'Lihat Semua (${semuaUlasan.length})',
                                                style: mitraFont(size: 11.5, weight: FontWeight.bold, color: mitraGreenBottom),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (preview.isEmpty)
                                        Text(
                                          'Belum ada ulasan',
                                          style: mitraFont(size: 12, color: mitraTextDark.withValues(alpha: 0.55)),
                                        )
                                      else
                                        ...preview.map((u) => Padding(
                                              padding: const EdgeInsets.only(bottom: 10),
                                              child: _UlasanCard(ulasan: u),
                                            )),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 80),
                              ],
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          decoration: BoxDecoration(
            color: mitraCream,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -3))],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _snack(context, 'Permintaan panggilan ke ${provider.nama} sedang diproses...'),
                    icon: const Icon(Icons.handshake_rounded, size: 20),
                    label: Text('Panggil Sekarang', style: mitraFont(size: 13.5, weight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mitraGreenBottom,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: mitraGreenBottom, behavior: SnackBarBehavior.floating),
    );
  }
}

/// Tombol "Simpan" di appbar, sebelah kiri tombol titik tiga. Sebelum
/// disimpan ikonnya bookmark outline warna gelap biasa; setelah ditekan
/// (tersimpan) ikonnya berubah jadi bookmark solid + warna hijau khas
/// Mitra.
class _TombolSimpanMitra extends StatelessWidget {
  final bool tersimpan;
  final VoidCallback onTap;
  const _TombolSimpanMitra({required this.tersimpan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tersimpan ? 'Batal simpan' : 'Simpan',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Icon(
          tersimpan ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          key: ValueKey(tersimpan),
          color: tersimpan ? mitraGreenBottom : mitraTextDark,
          size: 24,
        ),
      ),
    );
  }
}

/// Tombol titik tiga di pojok kanan atas halaman detail mitra. Kalau
/// dipencet, muncul kotak menu kecil (mirip dropdown bahasa di web) berisi
/// "Bagikan" dan "Laporkan Mitra Ini".
class _MenuAksiMitra extends StatelessWidget {
  final SubLayanan sub;
  final PenyediaJasa provider;
  const _MenuAksiMitra({required this.sub, required this.provider});

  void _bagikan(BuildContext context) {
    final teks = 'Cek ${provider.nama} (${sub.nama}) — rating ${provider.rating}★, '
        '${provider.pesananSelesai} pesanan selesai. Yuk pesan lewat aplikasi!';
    Clipboard.setData(ClipboardData(text: teks));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Info mitra disalin, siap dibagikan ke teman kamu'),
        backgroundColor: mitraGreenBottom,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _laporkan(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: mitraCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Laporkan ${provider.nama}',
          style: mitraFont(size: 15, weight: FontWeight.bold, color: mitraTextDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ceritakan masalah yang kamu alami dengan mitra ini. Laporanmu akan kami tinjau.',
              style: mitraFont(size: 12, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: mitraFont(size: 12.5, color: mitraTextDark),
              decoration: InputDecoration(
                hintText: 'Tulis alasan laporan...',
                hintStyle: mitraFont(size: 12, color: Colors.black38),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: mitraFont(size: 12.5, color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Laporan terkirim, tim kami akan segera meninjau'),
                  backgroundColor: mitraGreenBottom,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: mitraGreenBottom,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Kirim', style: mitraFont(size: 12.5, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: '',
      color: Colors.white,
      elevation: 6,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: mitraGreenBottom.withValues(alpha: 0.10)),
      ),
      onSelected: (value) {
        if (value == 'share') _bagikan(context);
        if (value == 'report') _laporkan(context);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_rounded, size: 18, color: mitraGreenBottom),
              const SizedBox(width: 10),
              Text('Bagikan', style: mitraFont(size: 12.5, color: mitraTextDark)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag_rounded, size: 18, color: Colors.redAccent),
              const SizedBox(width: 10),
              Text('Laporkan Mitra Ini', style: mitraFont(size: 12.5, color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }
}


/// Foto/ikon visual per item spesialisasi layanan (mis. Sapu & Pel, Cuci
/// Piring, dll). Belum ada aset foto asli, jadi dipakai ikon representatif
/// dengan latar gradasi supaya tetap terasa seperti kartu galeri foto.
IconData _iconUntukLayanan(String label) {
  final l = label.toLowerCase();
  if (l.contains('sapu') || l.contains('pel')) return Icons.cleaning_services_rounded;
  if (l.contains('cuci piring')) return Icons.soap_rounded;
  if (l.contains('cuci') || l.contains('laundry')) return Icons.local_laundry_service_rounded;
  if (l.contains('debu') || l.contains('lap')) return Icons.auto_fix_high_rounded;
  if (l.contains('rapikan') || l.contains('rapih') || l.contains('ruangan')) return Icons.chair_alt_rounded;
  if (l.contains('kaca') || l.contains('jendela')) return Icons.window_rounded;
  if (l.contains('kamar mandi') || l.contains('toilet')) return Icons.bathtub_rounded;
  if (l.contains('kebun') || l.contains('taman')) return Icons.yard_rounded;
  if (l.contains('listrik') || l.contains('kabel')) return Icons.electrical_services_rounded;
  if (l.contains('pipa') || l.contains('bocor') || l.contains('air')) return Icons.plumbing_rounded;
  if (l.contains('cat')) return Icons.format_paint_rounded;
  if (l.contains('ac') || l.contains('pendingin')) return Icons.ac_unit_rounded;
  return Icons.photo_camera_rounded;
}

class _FotoLayananTile extends StatelessWidget {
  final String label;
  final TingkatKebutuhan? tarif;
  const _FotoLayananTile({required this.label, this.tarif});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mitraGreenBottom.withValues(alpha: 0.16), mitraGreenBottom.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_iconUntukLayanan(label), color: mitraGreenBottom, size: 30),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: mitraFont(size: 10, weight: FontWeight.w700, color: mitraTextDark),
          ),
          if (tarif != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.25)),
              ),
              child: Text(
                tarif!.labelTarif,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mitraFont(size: 8.5, weight: FontWeight.bold, color: mitraGreenBottom),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UlasanCard extends StatelessWidget {
  final Ulasan ulasan;
  const _UlasanCard({required this.ulasan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.10)),
      ),
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
        ],
      ),
    );
  }
}

class _JamOperasionalBox extends StatelessWidget {
  final PenyediaJasa provider;
  const _JamOperasionalBox({required this.provider});

  @override
  Widget build(BuildContext context) {
    final buka = provider.sedangBuka;
    final warnaDot = buka ? mitraGreenBottom : Colors.black38;
    final warnaChip = buka ? mitraGreenBottom : Colors.black45;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_filled_rounded, color: mitraGreenBottom, size: 18),
            const SizedBox(height: 4),
            Text(
              provider.labelJamOperasional,
              style: mitraFont(size: 11.5, weight: FontWeight.bold, color: mitraTextDark),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: buka ? mitraGreenBottom.withValues(alpha: 0.10) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: warnaDot),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    buka ? 'Buka' : 'Tutup',
                    style: mitraFont(size: 9.5, weight: FontWeight.bold, color: warnaChip),
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

class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatBox({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.10)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 4),
            Text(value, style: mitraFont(size: 12.5, weight: FontWeight.bold, color: mitraTextDark)),
            Text(label, style: mitraFont(size: 9.5, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}