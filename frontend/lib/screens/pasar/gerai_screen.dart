import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/screens/pasar/toko_screen.dart';
import 'package:frontend/screens/pasar/firestore_toko_screen.dart';
import 'package:frontend/screens/pasar/checkout_screen.dart';
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
  final CartManager _cart = CartManager.instance;

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
          child: Stack(
            children: [
              Column(
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

              // Floating Cart Bottom Bar
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildCartBottomBar(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.market.nama,
                  style: _gs(size: 20, weight: FontWeight.bold, color: _gDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Daftar Gerai & Toko Pasar',
                  style: _gs(size: 12, color: _gDark.withValues(alpha: 0.7)),
                ),
              ],
            ),
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
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: _gs(size: 14),
          decoration: InputDecoration(
            hintText: 'Cari warung / gerai...',
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
  //  DAFTAR GERAI (Statis + Firestore Real-Time)
  // ─────────────────────────────────────────────
  Widget _buildGeraList() {
    return StreamBuilder<QuerySnapshot>(
      stream: StoreService.allActiveStoresStream(marketType: widget.market.nama),
      builder: (context, snapshot) {
        List<DocumentSnapshot> firestoreDocs = [];
        if (snapshot.hasData) {
          firestoreDocs = snapshot.data!.docs;
        }

        final filteredFirestore = firestoreDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['store_name'] as String? ?? '').toLowerCase();
          final desc = (data['description'] as String? ?? '').toLowerCase();
          final q = _query.toLowerCase();
          return name.contains(q) || desc.contains(q);
        }).toList();

        final staticGerai = _filteredStaticGerai;
        final totalCount = staticGerai.length + filteredFirestore.length;

        if (snapshot.connectionState == ConnectionState.waiting && firestoreDocs.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              ...staticGerai.map((g) => _buildStaticGeraiCard(g)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: _gGreen, strokeWidth: 2)),
              ),
            ],
          );
        }

        if (totalCount == 0) {
          return _buildEmpty('Warung / Gerai tidak ditemukan');
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          children: [
            // ── Gerai Firestore (Mitra Nemu+ / Penjual terdaftar) ──
            if (filteredFirestore.isNotEmpty) ...[
              _buildSectionLabel('Mitra Nemu+ Terdaftar', Icons.verified_rounded, color: _gGreen),
              const SizedBox(height: 8),
              ...filteredFirestore.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildFirestoreGeraiCard(doc.id, data);
              }),
              const SizedBox(height: 12),
            ],

            // ── Gerai Statis ──
            if (staticGerai.isNotEmpty) ...[
              _buildSectionLabel('Gerai Tetap Pasar', Icons.store_rounded),
              const SizedBox(height: 8),
              ...staticGerai.map((g) => _buildStaticGeraiCard(g)),
            ],
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
        isOpen: true,
        gerai: gerai,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Kartu Gerai FIRESTORE (Mitra Nemu+)
  // ─────────────────────────────────────────────
  Widget _buildFirestoreGeraiCard(String storeId, Map<String, dynamic> data) {
    final name = data['store_name'] as String? ?? 'Gerai Nemu+';
    final description = data['description'] as String? ?? 'Toko Mitra Nemu+ Terdaftar';
    final isOpen = (data['is_open'] as bool?) ??
        (data['isOpen'] as bool?) ??
        (data['is_active'] as bool?) ??
        true;

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
        isOpen: isOpen,
      ),
    );
  }

  Widget _buildGeraiCardShell({
    required String emoji,
    required String name,
    required String description,
    double? rating,
    int? ulasan,
    String? badge,
    bool isOpen = true,
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
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _gGreen.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 42)),
            ),
          ),
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
                      // Status Buka/Tutup
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isOpen ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          isOpen ? 'Buka' : 'Tutup',
                          style: _gs(
                            size: 9,
                            weight: FontWeight.bold,
                            color: isOpen ? _gGreen : Colors.red.shade600,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_gGreen, Color(0xFF00A852)]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badge, style: _gs(size: 8.5, weight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
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
                        Text('Mitra Terverifikasi', style: _gs(size: 10, color: _gGreen)),
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

  Widget _buildCartBottomBar() {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: _cart.items,
      builder: (_, items, _) {
        if (items.isEmpty) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
            ).then((_) => setState(() {}));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _gGreen,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _gGreen.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 22),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(color: Color(0xFFFF3B30), shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '${_cart.totalQty}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_cart.totalQty} item', style: _gs(size: 11, color: Colors.white70)),
                    Text(StoreService.formatRupiahFull(_cart.totalHarga), style: _gs(size: 13, weight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const Spacer(),
                Text('Checkout', style: _gs(size: 14, weight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏪', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(message, style: _gs(size: 16, weight: FontWeight.bold)),
          Text('Coba cari dengan kata kunci lain', style: _gs(size: 13, color: Colors.black45)),
        ],
      ),
    );
  }
}
