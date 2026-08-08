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
  };

  static const Map<String, String> _marketImages = {
    'p1': 'assets/products/pasar_sepinggan.jpg',
  };

  static const Map<String, Color> _accentColors = {
    'p1': Color(0xFF22C55E),
    'p2': Color(0xFF0EA5E9),
    'p3': Color(0xFF8B5CF6),
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

  Widget _buildPasarCard(PasarMarket market) {
    final accent = _accentColors[market.id] ?? _green;
    final emoji = _emojis[market.id] ?? '🏪';
    final imagePath = _marketImages[market.id];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GeraiScreen(market: market)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Kiri: Foto Pasar (Emoji / Colored container) ──
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: imagePath == null
                    ? LinearGradient(
                        colors: [
                          accent.withOpacity(0.2),
                          accent.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: imagePath != null
                    ? DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                      )
                    : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.15), width: 1.5),
              ),
              child: imagePath == null
                  ? Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 42)),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // ── Kanan: Info Pasar ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    market.nama,
                    style: _ms(size: 15, weight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        market.rating.toString(),
                        style: _ms(size: 12, weight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${market.gerai.length} Gerai)',
                        style: _ms(size: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _infoRow(
                    Icons.location_on_rounded,
                    market.alamat,
                    Colors.redAccent,
                  ),
                  const SizedBox(height: 4),
                  _infoRow(
                    Icons.access_time_rounded,
                    'Buka: ${market.jamBuka}',
                    _green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: _ms(size: 11, color: Colors.black54),
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
