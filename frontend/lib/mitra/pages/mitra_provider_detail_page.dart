// mitra_provider_detail_page.dart
//
// Halaman terakhir alur Mitra: profil lengkap satu penyedia jasa —
// menggambarkan siapa dia, spesialisasinya apa, rating, dan tombol
// aksi (chat / panggil sekarang) di bagian bawah.

import 'package:flutter/material.dart';
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
                  mitraAppBar('', iconColor: mitraTextDark),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Column(
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
                                    _StatBox(icon: Icons.star_rounded, iconColor: Colors.amber, label: 'Rating', value: '${provider.rating}'),
                                    const SizedBox(width: 10),
                                    _StatBox(icon: Icons.task_alt_rounded, iconColor: mitraGreenBottom, label: 'Selesai', value: '${provider.pesananSelesai}x'),
                                    const SizedBox(width: 10),
                                    _StatBox(icon: Icons.location_on_rounded, iconColor: Colors.redAccent, label: 'Jarak', value: '${provider.jarakKm} km'),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: provider.buka ? mitraGreenBottom.withValues(alpha: 0.12) : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        provider.buka ? 'Sedang Buka' : 'Sedang Tutup',
                                        style: mitraFont(size: 10.5, weight: FontWeight.bold, color: provider.buka ? mitraGreenBottom : Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                Text('Tentang', style: mitraFont(size: 14, weight: FontWeight.bold, color: mitraTextDark)),
                                const SizedBox(height: 6),
                                Text(_deskripsi, style: mitraFont(size: 12.5, color: Colors.black87, height: 1.5)),
                                const SizedBox(height: 20),

                                Text('Layanan', style: mitraFont(size: 14, weight: FontWeight.bold, color: mitraTextDark)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 108,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: sub.tagSpesialisasi.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                                    itemBuilder: (_, i) => _FotoLayananTile(label: sub.tagSpesialisasi[i]),
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
              _CircleActionButton(
                icon: Icons.chat_bubble_rounded,
                onTap: () => _snack(context, 'Membuka chat dengan ${provider.nama}...'),
              ),
              const SizedBox(width: 10),
              _CircleActionButton(
                icon: Icons.share_rounded,
                onTap: () => _snack(context, 'Bagikan profil ${provider.nama}'),
              ),
              const SizedBox(width: 12),
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
  const _FotoLayananTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
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
          Icon(_iconUntukLayanan(label), color: mitraGreenBottom, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: mitraFont(size: 10, weight: FontWeight.w700, color: mitraTextDark),
          ),
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

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: mitraGreenBottom.withValues(alpha: 0.2))),
          child: Icon(icon, color: mitraGreenBottom, size: 20),
        ),
      ),
    );
  }
}