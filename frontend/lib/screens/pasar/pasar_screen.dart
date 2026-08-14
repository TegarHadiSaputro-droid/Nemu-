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
    'p1': 'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', // Pasar Sepinggan
    'p2': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRWL__NIHl6U-AMt-_sC9dDY3sgDuKx-SFKm7NnwkbsQtPiwNeHo4SwRl8&s=10', // Pasar Klandasan
    'p3': 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxMTEhUTExMWFhUXGBobGRgYGBoeHhseHRsdGB0gGR8dHyggICInHRoYITEhJSkrLi4uGh8zODMsNygtLisBCgoKDg0OGxAQGy0lICYtLS8uLS0tLS0vLS0tLy0tLS0tLy0vLS0tLy0tLS0tLS0tLS8tLS0rLS0tLS0tLS0tLf/AABEIAPsAyQMBIgACEQEDEQH/xAAcAAACAwEBAQEAAAAAAAAAAAAEBQIDBgEHAAj/xABLEAACAQIEAwYCBgcECAQHAAABAhEDIQAEEjEFQVEGEyJhcYEykUJSobHB0RQVI2JykvAHM1PhFlRjgrLC0vEkQ5OiF1Vzo6TT4//EABoBAAMBAQEBAAAAAAAAAAAAAAECAwAEBQb/xAAxEQACAgEDAgMHBAEFAAAAAAAAAQIRAxIhMQRBE1HwIjJhcYGRoQXB0eGxBhQVQlL/2gAMAwEAAhEDEQA/ADgtoc2Ca6M8x0mzMB0e4KGwn6vmWJi4ZFj7RQAdMCzTBUfBz2mQMBXDDvdMdbmdGe6TCd/i8Kk8FtDOxV3wKcRXQAT/AH0hVFj0m2j3+f4gJXe7L7l2v/K/1XPnfpBFhFCn/Nz9V8xU5Rl5N5//AKA7v/f0hAlWEwT0oOhQu4/Ncw//AJb+8wnyfW3vDe9/9V/6E9V4nqO+X9QOTFcAy8fzWJhF+RwOWzD3f8AFuPCe+/lRXnDlXm4TWXP2xhg3QYXvGxKZlZP+5U+r8ScHlH+VjLPbxwWTsq22HcsLTHVWm4B0mFlF8HAoUt+/8AR6nfp/D0dwehwB8YHU4fPwEHnBkGe1uQm+j2AJlS9YSN5B94M8XA8ZQfnzy0nRl4ln0eiOfw5CLNi4Vg2QuOSp5Ac9v3aVFB0/Vf3RCXvaKgKgAJDf7f8AHTPmzp+qBXO18/Vk1YVs38v/AKI9U/G3z9Ow7HzP4H79r2LDWt7fB6f2j+PoOgQOhOOe4gjc/Yj/AF+9L7q7CwjK5nQeHHkYW1Da9F7wgUD1u3sQ5eXO/eyaWnl1jJZO6VwOhwPuKmk4TFAhDgY5Vw9m8CHnFa4gDkYcT1QqjkR3IhSFhdTB+n5A7xVLpP5D69uNv1v7fCFHRs3+fnHnTZqjOJ6XU4+HgF7wCHT0O8h7SkQu57R0e33nAJgFH0e8/JHc8QPmYY2z0eN9CDbz8/6vv+wG9nx1Ii0J/wA6L/T+u9pMbF06oPcoxb/AC9/8f5/1P/9k=', // Pasar Pandansari
    'p4': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR1SAUQY7ADtQTT8c4BfaL994YPzf6vpkjgQ3HdE8hjnw&s=10', // Pasar Baru
    'p5': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ76vKNMGKyfVdX-ez3cRHO6tb1zHfs0RRMkvCuUhZVcA&s=10', // Pasar Segar
    'p6': 'data:image/jpeg;base64,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', // Pasar Balikpapan Permai
    'p7': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_PIXPBXZbvfrDTwtxLkKnoo3nS9UbGtCYHS3o2A46XQ&s=10', // Pasar Manggar
    'p8': '', // Pasar Butun
    'p9': 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAA0JCgsKCA0LCgsODg0PEyAVExISEyccHhcgLikxMC4pLSwzOko+MzZGNywtQFdBRkxOUlNSMj5aYVpQYEpRUk8BDg4OExETJhUVJk81LTVPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT//AABEIAKQA9gMBIgACEQEDEQH/xAAbAAABBQEBAAAAAAAAAAAAAAADAAECBAUGB//EAEcQAAIBAwIDBAcFBAYIBwAAAAECAwAEERIhBRMxQSJRYQYUMnGBkSOhscFSYtHh8BUzQvEkglOSQ3KD/8QAGAEBAQEBAQAAAAAAAAAAAAAAAQACAwT/xAAkEQACAgICAgEFAQAAAAAAAAAAAQIRAxIhMQRBE1HwIjJhcYGRoQXB0eGxBhQVQlL/2gAMAwEAAhEDEQA/ADgtoc2Ca6M8x0mzMB0e4KGwn6vmWJi4ZFj7RQAdMCzTBUfBz2mQMBXDDvdMdbmdGe6TCd/i8Kk8FtDOxV3wKcRXQAT/AH0hVFj0m2j3+f4gJXe7L7l2v/K/1XPnfpBFhFCn/Nz9V8xU5Rl5N5//AKA7v/f0hAlWEwT0oOhQu4/Ncw//AJb+8wnyfW3vDe9/9V/6E9V4nqO+X9QOTFcAy8fzWJhF+RwOWzD3f8AFuPCe+/lRXnDlXm4TWXP2xhg3QYXvGxKZlZP+5U+r8ScHlH+VjLPbxwWTsq22HcsLTHVWm4B0mFlF8HAoUt+/8AR6nfp/D0dwehwB8YHU4fPwEHnBkGe1uQm+j2AJlS9YSN5B94M8XA8ZQfnzy0nRl4ln0eiOfw5CLNi4Vg2QuOSp5Ac9v3aVFB0/Vf3RCXvaKgKgAJDf7f8AHTPmzp+qBXO18/Vk1YVs38v/AKI9U/G3z9Ow7HzP4H79r2LDWt7fB6f2j+PoOgQOhOOe4gjc/Yj/AF+9L7q7CwjK5nQeHHkYW1Da9F7wgUD1u3sQ5eXO/eyaWnl1jJZO6VwOhwPuKmk4TFAhDgY5Vw9m8CHnFa4gDkYcT1QqjkR3IhSFhdTB+n5A7xVLpP5D69uNv1v7fCFHRs3+fnHnTZqjOJ6XU4+HgF7wCHT0O8h7SkQu57R0e33nAJgFH0e8/JHc8QPmYY2z0eN9CDbz8/6vv+wG9nx1Ii0J/wA6L/T+u9pMbF06oPcoxb/AC9/8f5/1P/9k=', // Pasar Kebun Sayur
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