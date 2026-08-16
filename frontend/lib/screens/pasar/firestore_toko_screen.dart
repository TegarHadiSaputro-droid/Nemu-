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

// ─────────────────────────────────────────────
//  FirestoreTokoScreen
//  Menampilkan detail toko + produk yang terdaftar di Firestore
//  untuk sisi Pembeli secara real-time.
// ─────────────────────────────────────────────
class FirestoreTokoScreen extends StatefulWidget {
  final String storeId;
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: StoreService.storeStream(widget.storeId),
      builder: (context, storeSnapshot) {
        final liveData = storeSnapshot.data?.data() as Map<String, dynamic>?;
        final currentStoreData = liveData ?? widget.storeData;

        final storeName = (currentStoreData['store_name'] as String?) ?? 'Gerai Nemu+';
        final description = (currentStoreData['description'] as String?) ?? '';
        final marketSection = (currentStoreData['market_type'] as String?) ??
            (currentStoreData['market_section'] as String?) ??
            'Pasar Tradisional';
        final isOpen = (currentStoreData['is_open'] as bool?) ??
            (currentStoreData['isOpen'] as bool?) ??
            (currentStoreData['is_active'] as bool?) ??
            true;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F0),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildAppBar(storeName, marketSection, isOpen),
                  // Banner Status Toko Tutup (jika sedang tutup)
                  if (!isOpen)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_clock_rounded, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Toko Sedang Tutup',
                                    style: _fts(size: 13, weight: FontWeight.bold, color: Colors.red.shade800),
                                  ),
                                  Text(
                                    'Penjual sedang tidak menerima pesanan saat ini. Anda dapat melihat katalog produk di bawah.',
                                    style: _fts(size: 10.5, color: Colors.red.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Header info toko
                  if (description.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
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
                                description,
                                style: _fts(size: 12, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Header Produk
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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

                  // Daftar produk (real-time)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: _buildProductSliver(storeName, marketSection, isOpen),
                  ),
                ],
              ),

              // Bottom Bar Keranjang
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: _buildCartBottomBar(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(String storeName, String marketSection, bool isOpen) {
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
                        Row(
                          children: [
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
                                  Text('Nemu+ Mitra', style: _fts(size: 10, weight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isOpen ? Colors.white : Colors.red.shade400,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isOpen ? '🟢 Buka' : '🔴 Tutup',
                                style: _fts(
                                  size: 9.5,
                                  weight: FontWeight.bold,
                                  color: isOpen ? _ftGreen : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          storeName,
                          style: _fts(size: 19, weight: FontWeight.bold, color: Colors.white),
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
                                marketSection,
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

  Widget _buildProductSliver(String storeName, String marketSection, bool isStoreOpen) {
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
                    Text('Penjual belum menambahkan produk dagangan.', style: _fts(size: 12, color: Colors.black45)),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _buildProdukRow(doc.id, data, storeName, marketSection, isStoreOpen);
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildProdukRow(
    String docId,
    Map<String, dynamic> data,
    String storeName,
    String marketSection,
    bool isStoreOpen,
  ) {
    final name = data['product_name'] as String? ?? 'Produk';
    final icon = data['category'] as String? ?? '🛒';
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final isOutOfStock = stock <= 0;
    final canBuy = isStoreOpen && !isOutOfStock;

    final tempProduk = PasarProduk(
      id: docId,
      nama: name,
      emoji: icon,
      satuan: 'unit',
      hargaKemarin: price,
      hargaSekarang: price,
      deskripsi: '',
    );

    return Opacity(
      opacity: canBuy ? 1.0 : 0.6,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _fts(size: 14, weight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    StoreService.formatRupiahFull(price),
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
            if (canBuy)
              GestureDetector(
                onTap: () {
                  final ownerId = (data['owner_id'] as String?) ??
                      (widget.storeData['owner_id'] as String?) ??
                      widget.storeId;
                  _cart.tambah(
                    tempProduk,
                    1,
                    storeName,
                    marketSection,
                    geraiId: widget.storeId,
                    sellerId: ownerId,
                  );
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
                child: Text(
                  !isStoreOpen ? 'Toko Tutup' : 'Habis',
                  style: _fts(size: 10, weight: FontWeight.bold, color: Colors.grey.shade700),
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
                    Text(StoreService.formatRupiahFull(_cart.totalHarga), style: _fts(size: 13, weight: FontWeight.bold, color: Colors.white)),
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
