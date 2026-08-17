import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/screens/pasar/gerai_screen.dart';
import 'package:frontend/services/store_service.dart';

// ─────────────────────────────────────────────
//  Warna
// ─────────────────────────────────────────────
const Color _green = Color(0xFF007C3F);
const Color _yellow = Color(0xFFD9DF36);
const Color _dark = Color(0xFF0F1B11);
const Color _cream = Color(0xFFFFFDF7);

TextStyle _ms({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _dark,
}) => GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

// ─────────────────────────────────────────────
//  PasarScreen
// ─────────────────────────────────────────────
class PasarScreen extends StatefulWidget {
  const PasarScreen({super.key});

  @override
  State<PasarScreen> createState() => _PasarScreenState();
}

class _PasarScreenState extends State<PasarScreen> {
  String _query = '';

  List<PasarMarket> get _filtered => mockDaftarPasar
      .where(
        (p) =>
            p.nama.toLowerCase().contains(_query.toLowerCase()) ||
            p.kategori.toLowerCase().contains(_query.toLowerCase()),
      )
      .toList();

  static const Map<String, String> _emojis = {
    'p1': '🥬',
    'p2': '🐟',
    'p3': '🌽',
    'p4': '🏪',
    'p5': '🍜',
    'p6': '🛒',
    'p7': '🦐',
    'p8': '🧺',
    'p9': '🎁',
  };

  // ── Taruh link URL gambar pasar di sini (menggantikan emoji jika diisi) ──
  static const Map<String, String> _marketImageUrls = {
    'p9': 'https://images.bisnis.com/posts/2025/01/20/1833269/pasar-0_1737376804.jpg', // Pasar Kebun Sayur
  };

  static const Map<String, String> _marketImages = {
    'p1': 'assets/products/pasar_sepinggan.jpg',
    'p2': 'assets/products/pasar_klandasan.jpg',
    'p3': 'assets/products/pasar_pandansari.jpg',
    'p4': 'assets/products/pasar_baru.jpg',
    'p5': 'assets/products/pasar_segar.jpg',
    'p6': 'assets/products/pasar_balikpapan_permai.jpg',
    'p7': 'assets/products/pasar_manggar.jpg',
    'p8': 'assets/products/pasar_buton.jpg',
  };

  static const Map<String, Color> _accentColors = {
    'p1': Color(0xFF22C55E),
    'p2': Color(0xFF0EA5E9),
    'p3': Color(0xFF8B5CF6),
    'p4': Color(0xFFF59E0B),
    'p5': Color(0xFFEC4899),
    'p6': Color(0xFF14B8A6),
    'p7': Color(0xFF3B82F6),
    'p8': Color(0xFFEF4444),
    'p9': Color(0xFFD97706),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_yellow, _green],
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
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pasar Tradisional',
                style: _ms(size: 20, weight: FontWeight.w800, color: _dark),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _dark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Balikpapan',
                  style: _ms(size: 11, weight: FontWeight.w700, color: _dark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih pasar tujuan untuk melihat gerai & produk segar',
            style: _ms(size: 12, color: _dark.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: _ms(size: 13),
          decoration: InputDecoration(
            hintText: 'Cari pasar...',
            hintStyle: _ms(size: 13, color: Colors.black38),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.black45),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) return _buildEmpty();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildPasarCard(list[i]),
    );
  }

  Widget _buildPasarCard(PasarMarket market) {
    final accent = _accentColors[market.id] ?? _green;
    final emoji = _emojis[market.id] ?? '🏪';
    final imagePath = _marketImages[market.id];
    final imageUrl = _marketImageUrls[market.id];
    final hasImagePath = imagePath != null && imagePath.isNotEmpty;
    final hasImageUrl = imageUrl != null && imageUrl.isNotEmpty;
    final hasVisual = hasImagePath || hasImageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GeraiScreen(market: market)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _dark.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Foto full-bleed jadi background seluruh card ──
              hasVisual
                  ? (hasImagePath
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _visualFallback(accent, emoji),
                        )
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : _visualLoading(accent),
                          errorBuilder: (_, __, ___) =>
                              _visualFallback(accent, emoji),
                        ))
                  : _visualFallback(accent, emoji),

              // ── Scrim gelap dari bawah biar teks kebaca di atas foto ──
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Badge rating melayang di pojok kanan atas ──
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _cream.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
                      const SizedBox(width: 2),
                      Text(
                        market.rating.toString(),
                        style: _ms(size: 11, weight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Badge jumlah gerai di pojok kiri atas ──
              Positioned(
                top: 12,
                left: 12,
                child: StreamBuilder<QuerySnapshot>(
                  stream: StoreService.allActiveStoresStream(),
                  builder: (context, snapshot) {
                    final firestoreCount = (snapshot.data?.docs ?? [])
                        .where((doc) => StoreService.matchesMarket(
                              doc.data() as Map<String, dynamic>,
                              marketId: market.id,
                              marketNama: market.nama,
                            ))
                        .length;
                    final totalGerai = market.gerai.length + firestoreCount;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$totalGerai Gerai',
                        style: _ms(size: 10, weight: FontWeight.bold, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),

              // ── Teks di atas scrim gelap, dekat bawah card ──
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      market.nama,
                      style: _ms(size: 17, weight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _infoRow(Icons.location_on_rounded, market.alamat, Colors.white70),
                    const SizedBox(height: 3),
                    _infoRow(Icons.access_time_rounded, 'Buka: ${market.jamBuka}', Colors.white70),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _visualFallback(Color accent, String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.5), accent.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
    );
  }

  Widget _visualLoading(Color accent) {
    return Container(
      color: accent.withValues(alpha: 0.25),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      ),
    );
  }

  // ── Info row dengan teks putih + shadow ──
  Widget _infoRow(IconData icon, String label, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: iconColor, shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4),
        ]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: _ms(size: 11, color: Colors.white).copyWith(
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Pasar tidak ditemukan',
              style: _ms(size: 16, weight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba kata kunci atau filter kategori lain',
              style: _ms(size: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}