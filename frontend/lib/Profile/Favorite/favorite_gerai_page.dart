// favorite_gerai_page.dart
//
// Halaman "Favorit Saya" — dibuka dari Akun > Aktivitas > Favorit saya.
// Menampilkan gerai yang disimpan user, sumber datanya SAMA dengan
// section "Gerai Tersimpan" di beranda (FavoriteGeraiService.streamFavorites),
// jadi otomatis sinkron realtime tanpa kerja tambahan.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/favorite_gerai_service.dart';
import '../../Theme/app_theme.dart';
import '../../Theme/decor_background.dart';

class FavoriteGeraiPage extends StatelessWidget {
  const FavoriteGeraiPage({super.key});

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
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
                          'Favorit Saya',
                          style: GoogleFonts.manrope(
                            color: kInk,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<FavoriteGerai>>(
                      stream: FavoriteGeraiService.instance.streamFavorites(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: kInk),
                          );
                        }

                        final favs = snapshot.data ?? [];

                        if (favs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bookmark_border_rounded,
                                      color: kInk.withOpacity(0.35), size: 40),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Belum ada gerai favorit',
                                    style: GoogleFonts.manrope(
                                      color: kInk,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ketuk ikon bookmark di halaman gerai untuk menyimpannya di sini',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      color: kInk.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: favs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _FavoriteGeraiTile(gerai: favs[i]),
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

class _FavoriteGeraiTile extends StatelessWidget {
  final FavoriteGerai gerai;
  const _FavoriteGeraiTile({required this.gerai});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kInk.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(gerai.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gerai.namaGerai,
                  style: GoogleFonts.manrope(
                    color: kInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (gerai.namaMarket != null && gerai.namaMarket!.isNotEmpty)
                  Text(
                    gerai.namaMarket!,
                    style: GoogleFonts.manrope(
                      color: kInk.withOpacity(0.6),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 2),
                    Text(
                      gerai.rating.toString(),
                      style: GoogleFonts.manrope(
                        color: kInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${gerai.ulasan} Ulasan)',
                      style: GoogleFonts.manrope(
                        color: kInk.withOpacity(0.45),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => FavoriteGeraiService.instance.remove(gerai.geraiId),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.bookmark_rounded, color: kInk.withOpacity(0.75), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}