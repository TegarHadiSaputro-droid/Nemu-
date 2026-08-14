import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/screens/pasar/gerai_screen.dart';

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
    'p1': 'https://nomorsatukaltim.disway.id/uploads/pasar-sepinggan.jpg', // Pasar Sepinggan
    'p2': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRWL__NIHl6U-AMt-_sC9dDY3sgDuKx-SFKm7NnwkbsQtPiwNeHo4SwRl8&s=10', // Pasar Klandasan
    'p3': 'https://www.niaga.asia/wp-content/uploads/2024/02/pandansari.jpg', // Pasar Pandansari
    'p4': 'https://airial.travel/_next/image?url=https%3A%2F%2Fcoinventmediastorage.blob.core.windows.net%2Fmedia-storage-container%2Fgphoto_ChIJnabs3NxH8S0R525KRyz9WtM_0.jpg&w=2048&q=70', // Pasar Baru
    'p5': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSyuR0bnZIYOHVlqcNHcoXc9HFmwIjMqtbxsfXVFQw7EWukDiG5Ark-Atg&s=10', // Pasar Segar
    'p6': 'https://witness.tempo.co/source/index.php?image=/9/1/7/1/9171.jpg&size=1000&dimension=width&quality=100', // Pasar Balikpapan Permai
    'p7': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_PIXPBXZbvfrDTwtxLkKnoo3nS9UbGtCYHS3o2A46XQ&s=10', // Pasar Manggar
    'p8': 'https://lh3.googleusercontent.com/gps-cs-s/AHRPTWn-HQMSzmVMZv6U8iKMpx1UBVj6RS2c3AvCQ1WtL6BNCPWiVDpVf-Z6wIjRatlJN2yV1cFKWqz6yilIt4WTxN6sO-tAmcji7VVgyU-5S3EF6opu6-AWhF_gzLThFrkowZgZvTvM=w243-h174-n-k-no-nu', // Pasar Butun
    'p9': 'https://images.bisnis.com/posts/2025/01/20/1833269/pasar-0_1737376804.jpg', // Pasar Kebun Sayur
  };

  static const Map<String, String> _marketImages = {
    'p1': 'assets/products/pasar_sepinggan.jpg',
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
            Expanded(
              child: _filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _buildPasarCard(_filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Pasar',
            style: _ms(size: 24, weight: FontWeight.bold, color: _dark),
          ),
          const SizedBox(height: 2),
          Text(
            '${mockDaftarPasar.length} pasar tradisional tersedia',
            style: _ms(size: 13, color: _dark.withOpacity(0.65)),
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
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: _ms(size: 14),
          decoration: InputDecoration(
            hintText: 'Cari pasar...',
            hintStyle: _ms(size: 13, color: Colors.black38),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _green,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Helper: render gambar dari URL biasa ATAU data:base64 URI ──
  Widget _resolveImage(String imageUrl, Color accent, String emoji) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.substring(imageUrl.indexOf(',') + 1);
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => _visualFallback(accent, emoji),
        );
      } catch (_) {
        return _visualFallback(accent, emoji);
      }
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => _visualFallback(accent, emoji),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _visualLoading(accent);
      },
    );
  }

  Widget _buildPasarCard(PasarMarket market) {
    final accent = _accentColors[market.id] ?? _green;
    final emoji = _emojis[market.id] ?? '🏪';
    final imageUrl = _marketImageUrls[market.id];
    final hasImageUrl = imageUrl != null && imageUrl.isNotEmpty;
    final imagePath = hasImageUrl ? null : _marketImages[market.id];
    final hasVisual = hasImageUrl || imagePath != null;

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
              color: _dark.withOpacity(0.18),
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
                  ? (hasImageUrl
                      ? _resolveImage(imageUrl, accent, emoji)
                      : Image.asset(
                          imagePath!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
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
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.78),
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
                    color: _cream.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${market.gerai.length} Gerai',
                    style: _ms(size: 10, weight: FontWeight.bold, color: Colors.white),
                  ),
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

  // ── Helper: fallback saat tidak ada foto ──
  Widget _visualFallback(Color accent, String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.55), accent.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }

  // ── Helper: loading state saat foto dari network belum siap ──
  Widget _visualLoading(Color accent) {
    return Container(
      color: accent.withOpacity(0.25),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      ),
    );
  }

  // ── Info row dengan teks putih + shadow, biar kebaca di atas foto apa pun ──
  Widget _infoRow(IconData icon, String label, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: iconColor, shadows: [
          Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 4),
        ]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: _ms(size: 11.5, color: Colors.white).copyWith(
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Pasar tidak ditemukan',
            style: _ms(size: 16, weight: FontWeight.bold),
          ),
          Text(
            'Coba kata kunci lain',
            style: _ms(size: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}