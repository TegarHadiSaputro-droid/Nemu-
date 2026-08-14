import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/screens/pasar/checkout_screen.dart';
import 'package:frontend/services/store_service.dart';

// ─────────────────────────────────────────────
//  Warna (konsisten dengan pasar screens)
// ─────────────────────────────────────────────
const Color _ftGreen  = Color(0xFF007C3F);
const Color _ftYellow = Color(0xFFD9DF36);
const Color _ftDark   = Color(0xFF0F1B11);

TextStyle _fts({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _ftDark,
}) => GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

String _rupiahFull(int val) {
  final s = val.toString().split('').reversed.join();
  final groups = <String>[];
  for (var i = 0; i < s.length; i += 3) {
    groups.add(s.substring(i, i + 3 > s.length ? s.length : i + 3));
  }
  return 'Rp ${groups.join('.').split('').reversed.join()}';
}

// ─────────────────────────────────────────────
//  FirestoreTokoScreen
//  Menampilkan detail toko + produk yang terdaftar di Firestore
//  untuk sisi Pembeli. Dipanggil dari GeraiScreen saat pembeli
//  menekan gerai yang didaftarkan oleh Penjual (Nemu+).
// ─────────────────────────────────────────────
class FirestoreTokoScreen extends StatefulWidget {
  /// ID dokumen di koleksi `stores`
  final String storeId;

  /// Data awal toko (diteruskan dari GeraiScreen untuk menghindari
  /// fetch ulang, tapi produk tetap di-load via StreamBuilder).
  final Map<String, dynamic> storeData;

  const FirestoreTokoScreen({
    super.key,
    required this.storeId,
    required this.storeData,
  });

  @override
  State<FirestoreTokoScreen> createState() => _FirestoreTokoScreenState();
}

class _FirestoreTokoScreenState extends State<FirestoreTokoScreen> {
  final CartManager _cart = CartManager.instance;

  String get _storeName => widget.storeData['store_name'] as String? ?? 'Toko';
  String get _description => widget.storeData['description'] as String? ?? '';
  String get _marketSection => widget.storeData['market_section'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F0),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              // Header info toko (update real-time via StreamBuilder)
              SliverToBoxAdapter(child: _buildStoreInfoBanner()),
              // Daftar produk (real-time)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _ftGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Produk Tersedia', style: _fts(size: 15, weight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: _buildProductSliver(),
              ),
            ],
          ),
          // ── Bottom Bar Keranjang ──
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
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _ftGreen,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_ftYellow, _ftGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
              child: Row(
                children: [
                  // Avatar toko
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Center(
                      child: Text('🏪', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge Nemu+
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, color: Colors.white, size: 11),
                              const SizedBox(width: 4),
                              Text('Nemu+ Terverifikasi', style: _fts(size: 10, weight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _storeName,
                          style: _fts(size: 20, weight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white70, size: 13),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                _marketSection,
                                style: _fts(size: 11, color: Colors.white.withValues(alpha: 0.9)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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

  Widget _buildStoreInfoBanner() {
    if (_description.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ftGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ftGreen.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _ftGreen.withValues(alpha: 0.7), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _description,
              style: _fts(size: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSliver() {
    return StreamBuilder<QuerySnapshot>(
      stream: StoreService.storeProductsStream(widget.storeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: _ftGreen)),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    const Text('📦', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('Belum ada produk', style: _fts(size: 15, weight: FontWeight.bold)),
                    Text('Penjual belum menambahkan produk.', style: _fts(size: 12, color: Colors.black45)),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _buildProdukRow(data);
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildProdukRow(Map<String, dynamic> data) {
    final name = data['product_name'] as String? ?? 'Produk';
    final icon = data['category'] as String? ?? '🛒';
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final isOutOfStock = stock == 0;

    // Buat PasarProduk "sementara" agar bisa masuk ke CartManager yang sudah ada
    final tempProduk = PasarProduk(
      id: '${widget.storeId}_${name.replaceAll(' ', '_')}',
      nama: name,
      emoji: icon,
      satuan: 'unit',
      hargaKemarin: price,
      hargaSekarang: price,
      deskripsi: '',
    );

    return GestureDetector(
      onTap: isOutOfStock
          ? null
          : () {
              _cart.tambah(tempProduk, 1, _storeName, _marketSection);
              setState(() {});
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name ditambahkan ke keranjang', style: _fts(size: 12, color: Colors.white)),
                  backgroundColor: _ftGreen,
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                ),
              );
            },
      child: Opacity(
        opacity: isOutOfStock ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              // Emoji / ikon produk
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _ftGreen.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(width: 14),
              // Info produk
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: _fts(size: 14, weight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _rupiahFull(price),
                      style: _fts(size: 13, weight: FontWeight.bold, color: _ftGreen),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOutOfStock ? Colors.red.shade400 : Colors.green.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isOutOfStock ? 'Stok Habis' : 'Stok: $stock',
                          style: _fts(size: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tombol + Tambah
              if (!isOutOfStock)
                GestureDetector(
                  onTap: () {
                    _cart.tambah(tempProduk, 1, _storeName, _marketSection);
                    setState(() {});
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name ditambahkan ke keranjang', style: _fts(size: 12, color: Colors.white)),
                        backgroundColor: _ftGreen,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _ftGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Habis', style: _fts(size: 10, weight: FontWeight.bold, color: Colors.grey)),
                ),
            ],
          ),
        ),
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
              color: _ftGreen,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _ftGreen.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))
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
                    Text('${_cart.totalQty} item', style: _fts(size: 11, color: Colors.white70)),
                    Text(_rupiahFull(_cart.totalHarga), style: _fts(size: 13, weight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const Spacer(),
                Text('Checkout', style: _fts(size: 14, weight: FontWeight.bold, color: Colors.white)),
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
