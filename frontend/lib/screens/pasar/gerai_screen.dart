import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/screens/pasar/toko_screen.dart';

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

  List<PasarGerai> get _filteredGerai => widget.market.gerai
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
                child: _filteredGerai.isEmpty
                    ? _buildEmpty()
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _filteredGerai.length,
                        itemBuilder: (_, i) => _buildGeraiCard(_filteredGerai[i]),
                      ),
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
                  style: _gs(size: 13, color: _gDark.withOpacity(0.65))),
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
                color: Colors.black.withOpacity(0.08),
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

  Widget _buildGeraiCard(PasarGerai gerai) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TokoPasarScreen(market: widget.market, gerai: gerai),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto gerai (Visual / Emoji)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _gGreen.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Center(
                  child: Text(
                    gerai.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            // Info gerai
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gerai.nama,
                    style: _gs(size: 14, weight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    gerai.deskripsi,
                    style: _gs(size: 10.5, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 3),
                      Text(
                        gerai.rating.toString(),
                        style: _gs(size: 11.5, weight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${gerai.ulasan} Ulasan)',
                        style: _gs(size: 9.5, color: Colors.black38),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

