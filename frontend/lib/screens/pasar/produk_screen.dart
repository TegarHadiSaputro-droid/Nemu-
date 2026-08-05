import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/screens/pasar/checkout_screen.dart';

const Color _pGreen  = Color(0xFF007C3F);
const Color _pYellow = Color(0xFFD9DF36);
const Color _pDark   = Color(0xFF0F1B11);

TextStyle _ps({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _pDark,
  double? height,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

String _pRupiah(int val) {
  final s = val.toString().split('').reversed.join();
  final groups = <String>[];
  for (var i = 0; i < s.length; i += 3) {
    groups.add(s.substring(i, i + 3 > s.length ? s.length : i + 3));
  }
  return 'Rp ${groups.join('.').split('').reversed.join()}';
}

// ─────────────────────────────────────────────
//  ProdukDetailScreen
// ─────────────────────────────────────────────
class ProdukDetailScreen extends StatefulWidget {
  final PasarProduk produk;
  final PasarGerai gerai;
  final String namaMarket;

  const ProdukDetailScreen({
    super.key,
    required this.produk,
    required this.gerai,
    required this.namaMarket,
  });

  @override
  State<ProdukDetailScreen> createState() => _ProdukDetailScreenState();
}

class _ProdukDetailScreenState extends State<ProdukDetailScreen>
    with SingleTickerProviderStateMixin {
  int _qty = 1;
  final CartManager _cart = CartManager.instance;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _changeQty(int delta) {
    final next = _qty + delta;
    if (next < 1) return;
    HapticFeedback.selectionClick();
    setState(() => _qty = next);
  }

  void _addToCart() {
    HapticFeedback.mediumImpact();
    _cart.tambah(widget.produk, _qty, widget.gerai.nama, widget.namaMarket);
    _bounceCtrl.reset();
    _bounceCtrl.forward();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.produk.nama} ×$_qty ditambahkan!',
          style: _ps(size: 13, color: Colors.white),
        ),
        backgroundColor: _pGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        action: SnackBarAction(
          label: 'Checkout',
          textColor: _pYellow,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produk;
    final totalHarga = p.hargaSekarang * _qty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(p),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Nama & harga ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.nama,
                                      style: _ps(
                                          size: 22, weight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _pGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Segar',
                                        style: _ps(
                                            size: 11,
                                            weight: FontWeight.w600,
                                            color: _pGreen)),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_pRupiah(p.hargaSekarang),
                                    style: _ps(
                                        size: 22,
                                        weight: FontWeight.bold,
                                        color: _pGreen)),
                                Text('per ${p.satuan}',
                                    style: _ps(size: 11, color: Colors.black45)),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        // ── Info Lapak ──
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _pGreen.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.storefront_rounded,
                                    color: _pGreen, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.gerai.nama,
                                        style: _ps(
                                            size: 14,
                                            weight: FontWeight.bold)),
                                    Text(widget.namaMarket,
                                        style: _ps(
                                            size: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.verified_rounded,
                                  color: _pGreen, size: 18),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Deskripsi ──
                        Text('Deskripsi Produk',
                            style: _ps(size: 14, weight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(p.deskripsi,
                            style: _ps(
                                size: 13,
                                color: Colors.black54,
                                weight: FontWeight.normal,
                                height: 1.6)),

                        const SizedBox(height: 20),

                        // ── Info tambahan ──
                        _buildInfoRow(Icons.eco_rounded,
                            'Produk segar pasar tradisional', _pGreen),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.local_shipping_rounded,
                            'Dikirim langsung oleh pedagang', Colors.orange),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.security_rounded,
                            'Dijamin uang kembali jika tidak sesuai',
                            Colors.blue),

                        const SizedBox(height: 30),

                        // ── Stepper Qty ──
                        Text('Jumlah',
                            style: _ps(size: 14, weight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _qtyBtn(Icons.remove_rounded,
                                () => _changeQty(-1), _qty <= 1),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text('$_qty',
                                  style: _ps(
                                      size: 22, weight: FontWeight.bold)),
                            ),
                            _qtyBtn(Icons.add_rounded,
                                () => _changeQty(1), false),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Total',
                                    style:
                                        _ps(size: 11, color: Colors.black45)),
                                Text(_pRupiah(totalHarga),
                                    style: _ps(
                                        size: 18,
                                        weight: FontWeight.bold,
                                        color: _pGreen)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Bar ──
          _buildBottomBar(totalHarga),
        ],
      ),
    );
  }

  Widget _buildAppBar(PasarProduk p) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8)
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _pDark, size: 18),
          ),
        ),
      ),
      actions: [
        ValueListenableBuilder<List<CartItem>>(
          valueListenable: _cart.items,
          builder: (_, items, __) {
            final total = items.fold(0, (s, i) => s + i.qty);
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Icon(Icons.shopping_cart_outlined,
                          color: _pDark, size: 20),
                    ),
                    if (total > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('$total',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_pGreen.withOpacity(0.08), _pYellow.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _bounceAnim,
              child: Text(p.emoji,
                  style: const TextStyle(fontSize: 100)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(text, style: _ps(size: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade100 : _pGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disabled ? Colors.grey.shade300 : _pGreen.withOpacity(0.3),
          ),
        ),
        child: Icon(icon,
            size: 18,
            color: disabled ? Colors.grey.shade400 : _pGreen),
      ),
    );
  }

  Widget _buildBottomBar(int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          // Keranjang button
          GestureDetector(
            onTap: _addToCart,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _pGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _pGreen.withOpacity(0.3)),
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  color: _pGreen, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Beli sekarang
          Expanded(
            child: GestureDetector(
              onTap: () {
                _addToCart();
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CheckoutScreen()),
                    );
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A851), _pGreen],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _pGreen.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Center(
                  child: Text('Beli Sekarang',
                      style: _ps(
                          size: 15,
                          weight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
