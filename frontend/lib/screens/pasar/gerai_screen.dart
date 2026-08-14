import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/screens/pasar/toko_screen.dart';
import 'package:frontend/screens/pasar/firestore_toko_screen.dart';
import 'package:frontend/services/store_service.dart';
import 'package:frontend/services/favorite_gerai_service.dart';

const Color _gGreen  = Color(0xFF007C3F);
const Color _gYellow = Color(0xFFD9DF36);
const Color _gDark   = Color(0xFF0F1B11);

TextStyle _gs({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _gDark,
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

class GeraiScreen extends StatefulWidget {
  final PasarMarket market;
  const GeraiScreen({super.key, required this.market});

  @override
  State<GeraiScreen> createState() => _GeraiScreenState();
}

class _GeraiScreenState extends State<GeraiScreen> {
  String _query = '';

  List<PasarGerai> get _filteredStaticGerai => widget.market.gerai
      .where((g) =>
          g.nama.toLowerCase().contains(_query.toLowerCase()) ||
          g.deskripsi.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gYellow, _gGreen],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              const SizedBox(height: 12),
              Expanded(
                child: _buildGeraList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _gDark),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Warung',
                  style: _gs(size: 22, weight: FontWeight.bold, color: _gDark)),
              Text('Pasar: ${widget.market.nama}',
                  style: _gs(size: 13, color: _gDark.withValues(alpha: 0.65))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: _gs(size: 14),
          decoration: InputDecoration(
            hintText: 'Cari warung/gerai...',
            hintStyle: _gs(size: 13, color: Colors.black38),
            prefixIcon: const Icon(Icons.search_rounded, color: _gGreen, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Daftar Gerai — Hybrid: Statis + Firestore Real-Time
  // ─────────────────────────────────────────────
  Widget _buildGeraList() {
    return StreamBuilder<QuerySnapshot>(
      stream: StoreService.allActiveStoresStream(marketSection: widget.market.nama),
      builder: (context, snapshot) {
        // Daftar gerai dari Firestore (penjual aktif)
        List<DocumentSnapshot> firestoreDocs = [];
        if (snapshot.hasData) {
          firestoreDocs = snapshot.data!.docs;
        }

        // Filter query ke gerai Firestore
        final filteredFirestore = firestoreDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['store_name'] as String? ?? '').toLowerCase();
          final desc = (data['description'] as String? ?? '').toLowerCase();
          final q = _query.toLowerCase();
          return name.contains(q) || desc.contains(q);
        }).toList();

        final staticGerai = _filteredStaticGerai;
        final totalCount = staticGerai.length + filteredFirestore.length;

        // Loading state (hanya tampil saat pertama kali load, masih ada statis)
        if (snapshot.connectionState == ConnectionState.waiting && firestoreDocs.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Tampilkan statis dulu selagi menunggu Firestore
              ...staticGerai.map((g) => _buildStaticGeraiCard(g)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: _gGreen, strokeWidth: 2)),
              ),
            ],
          );
        }

        if (totalCount == 0) {
          return _buildEmpty();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── Gerai Statis (data tetap / hardcoded) ──
            if (staticGerai.isNotEmpty) ...[
              _buildSectionLabel('Gerai Tetap', Icons.store_rounded),
              const SizedBox(height: 8),
              ...staticGerai.map((g) => _buildStaticGeraiCard(g)),
            ],

            // ── Gerai Firestore (Mitra Nemu+ / Penjual terdaftar) ──
            if (filteredFirestore.isNotEmpty) ...[
              if (staticGerai.isNotEmpty) const SizedBox(height: 8),
              _buildSectionLabel('Mitra Nemu+', Icons.verified_rounded, color: _gGreen),
              const SizedBox(height: 8),
              ...filteredFirestore.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildFirestoreGeraiCard(doc.id, data);
              }),
            ],

            // ── Pesan kosong jika query tidak menemukan di Firestore ──
            if (filteredFirestore.isEmpty && firestoreDocs.isNotEmpty && _query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Tidak ada Mitra Nemu+ yang cocok',
                    style: _gs(size: 11, color: Colors.black38),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, {Color color = Colors.black54}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: _gs(size: 12, weight: FontWeight.bold, color: color)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Kartu Gerai STATIS (data hardcoded/mock)
  // ─────────────────────────────────────────────
  Widget _buildStaticGeraiCard(PasarGerai gerai) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TokoPasarScreen(market: widget.market, gerai: gerai),
          ),
        );
      },
      child: _buildGeraiCardShell(
        emoji: gerai.emoji,
        name: gerai.nama,
        description: gerai.deskripsi,
        rating: gerai.rating,
        ulasan: gerai.ulasan,
        badge: null,
        gerai: gerai,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Kartu Gerai FIRESTORE (Mitra Nemu+)
  // ─────────────────────────────────────────────
  Widget _buildFirestoreGeraiCard(String storeId, Map<String, dynamic> data) {
    final name = data['store_name'] as String? ?? 'Gerai Nemu+';
    final description = data['description'] as String? ?? 'Toko Mitra Nemu+';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FirestoreTokoScreen(
              storeId: storeId,
              storeData: data,
            ),
          ),
        );
      },
      child: _buildGeraiCardShell(
        emoji: '🏪',
        name: name,
        description: description,
        rating: null,
        ulasan: null,
        badge: 'Nemu+',
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Shell kartu gerai (reusable)
  // ─────────────────────────────────────────────
  Widget _buildGeraiCardShell({
    required String emoji,
    required String name,
    required String description,
    double? rating,
    int? ulasan,
    String? badge,
    PasarGerai? gerai,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Foto gerai (Emoji)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _gGreen.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 46)),
            ),
          ),
          // Info gerai
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: _gs(size: 14, weight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_gGreen, Color(0xFF00A852)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, color: Colors.white, size: 9),
                              const SizedBox(width: 3),
                              Text(badge, style: _gs(size: 8.5, weight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: _gs(size: 11, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (rating != null && ulasan != null)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 3),
                        Text(rating.toString(), style: _gs(size: 12, weight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Text('($ulasan Ulasan)', style: _gs(size: 10, color: Colors.black38)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded, size: 13, color: _gGreen.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text('Mitra Nemu+ Terverifikasi', style: _gs(size: 10, color: _gGreen)),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (gerai != null)
            StreamBuilder<Set<String>>(
              stream: FavoriteGeraiService.instance.streamFavoriteIds(),
              builder: (context, snap) {
                final isSaved = snap.data?.contains(gerai.id) ?? false;
                return GestureDetector(
                  onTap: () => FavoriteGeraiService.instance.toggle(
                    gerai: gerai,
                    marketId: widget.market.id,
                    namaMarket: widget.market.nama,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: isSaved ? _gGreen : Colors.black38,
                      size: 22,
                    ),
                  ),
                );
              },
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏪', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Warung tidak ditemukan', style: _gs(size: 16, weight: FontWeight.bold)),
          Text('Coba cari dengan nama lainnya', style: _gs(size: 13, color: Colors.black45)),
        ],
      ),
    );
  }
}
