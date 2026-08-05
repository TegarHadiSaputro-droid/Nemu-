import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/screens/pasar/produk_screen.dart';
import 'package:frontend/screens/pasar/checkout_screen.dart';

const Color _tGreen  = Color(0xFF007C3F);
const Color _tYellow = Color(0xFFD9DF36);
const Color _tDark   = Color(0xFF0F1B11);

TextStyle _ts({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _tDark,
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

String _rupiah(int val) {
  final s = val.toString().split('').reversed.join();
  final groups = <String>[];
  for (var i = 0; i < s.length; i += 3) {
    groups.add(s.substring(i, i + 3 > s.length ? s.length : i + 3));
  }
  return 'Rp ${groups.join('.').split('').reversed.join()}';
}

// ─────────────────────────────────────────────
//  TokoPasarScreen (Menampilkan jualan per gerai)
// ─────────────────────────────────────────────
class TokoPasarScreen extends StatefulWidget {
  final PasarMarket market;
  final PasarGerai gerai;

  const TokoPasarScreen({
    super.key,
    required this.market,
    required this.gerai,
  });

  @override
  State<TokoPasarScreen> createState() => _TokoPasarScreenState();
}

class _TokoPasarScreenState extends State<TokoPasarScreen> {
  final CartManager _cart = CartManager.instance;

  @override
  Widget build(BuildContext context) {
    final products = widget.gerai.produk;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F0),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildProdukRow(products[i]),
                    childCount: products.length,
                  ),
                ),
              ),
            ],
          ),
          // ── Bottom Bar Keranjang / Checkout ──
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: _buildCartBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _tGreen,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_tYellow, _tGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
              child: Row(
                children: [
                  // Foto Gerai (Emoji besar di kiri)
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: Center(
                      child: Text(widget.gerai.emoji, style: const TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Deskripsi & Nama Gerai
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.gerai.nama,
                          style: _ts(size: 20, weight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.gerai.deskripsi,
                          style: _ts(size: 12, color: Colors.white.withOpacity(0.9)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.gerai.rating} (${widget.gerai.ulasan} ulasan)',
                              style: _ts(size: 11, weight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProdukRow(PasarProduk p) {
    Color dotColor = Colors.grey.shade400;
    if (p.statusHarga == true) {
      dotColor = const Color(0xFFFF3B30); // Naik (Merah)
    } else if (p.statusHarga == false) {
      dotColor = const Color(0xFF22C55E); // Turun (Hijau)
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProdukDetailScreen(
              produk: p,
              gerai: widget.gerai,
              namaMarket: widget.market.nama,
            ),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Kiri: Foto lombok/produk (emoji)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _tGreen.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(p.emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 14),

            // Kanan: Info produk
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.nama} (${p.satuan})',
                    style: _ts(size: 14, weight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Dot warna penentu status harga
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kemarin: ${_rupiah(p.hargaKemarin)}',
                            style: _ts(size: 11, color: Colors.black45),
                          ),
                          Text(
                            'Sekarang: ${_rupiah(p.hargaSekarang)}',
                            style: _ts(size: 13, weight: FontWeight.bold, color: _tGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tombol tambah cepat
            GestureDetector(
              onTap: () {
                _cart.tambah(p, 1, widget.gerai.nama, widget.market.nama);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${p.nama} ditambahkan ke keranjang',
                        style: _ts(size: 12, color: Colors.white)),
                    backgroundColor: _tGreen,
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  ),
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _tGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBottomBar() {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: _cart.items,
      builder: (_, items, __) {
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
              color: _tGreen,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: _tGreen.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_rounded,
                        color: Colors.white, size: 22),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_cart.totalQty}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
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
                    Text('${_cart.totalQty} item',
                        style: _ts(size: 11, color: Colors.white70)),
                    Text(_rupiah(_cart.totalHarga),
                        style: _ts(size: 13, weight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const Spacer(),
                Text('Checkout', style: _ts(size: 14, weight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}


