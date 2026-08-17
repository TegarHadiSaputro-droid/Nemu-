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
//  Model kecil untuk satu ulasan (dipetakan dari
//  dokumen collection('orders') yang sudah dirating)
// ─────────────────────────────────────────────
class _ReviewItem {
  final int rating;
  final String comment;
  final DateTime? date;

  _ReviewItem({required this.rating, required this.comment, this.date});

  factory _ReviewItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final createdAt = data['created_at'] ?? data['createdAt'] ?? data['timestamp'];
    return _ReviewItem(
      rating: (data['ratingStore'] as num?)?.toInt() ?? 0,
      comment: (data['commentStore'] as String?)?.trim() ?? '',
      date: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: _buildProductSliver(storeName, marketSection, isOpen),
                  ),

                  // ── Ulasan Pembeli (rating & komentar gerai, real-time) ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      child: _buildReviewsSection(),
                    ),
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

  // ──────────────────────────────────────────
  //  ULASAN PEMBELI
  //  Ambil dari collection('orders') milik toko ini yang sudah
  //  dirating (ratingStore > 0). Query pakai widget.storeId LANGSUNG
  //  -- ini persis sama dengan field store_id yang ditulis ke dokumen
  //  order dari OrdersScreen._submitStoreRating(), jadi begitu pembeli
  //  kasih rating di sana, otomatis muncul di sini juga (real-time).
  // ──────────────────────────────────────────
  Widget _buildReviewsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('store_id', isEqualTo: widget.storeId)
          .where('ratingStore', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Kasus paling umum: query butuh composite index (store_id +
          // ratingStore) yang belum dibuat di Firestore. Errornya berisi
          // link langsung untuk generate index tsb -- cek di console/log.
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gagal memuat ulasan: ${snapshot.error}',
                    style: _fts(size: 11.5, color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _ftGreen),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final reviews = docs
            .map((d) => _ReviewItem.fromDoc(d))
            .where((r) => r.comment.isNotEmpty) // cuma yang ada komentarnya
            .toList()
          ..sort((a, b) {
            if (a.date == null || b.date == null) return 0;
            return b.date!.compareTo(a.date!); // terbaru dulu
          });

        final ratingCount = docs.length;
        final avgRating = ratingCount > 0
            ? docs.fold<int>(
                    0, (sum, d) => sum + ((d.data()['ratingStore'] as num?)?.toInt() ?? 0)) /
                ratingCount
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                Text('Ulasan Pembeli', style: _fts(size: 15, weight: FontWeight.bold)),
                const Spacer(),
                if (ratingCount > 0) ...[
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 3),
                  Text(avgRating.toStringAsFixed(1),
                      style: _fts(size: 13, weight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Text('($ratingCount)', style: _fts(size: 12, color: Colors.black45)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 18, color: Colors.black38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Belum ada ulasan untuk toko ini.',
                        style: _fts(size: 12.5, color: Colors.black45),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: reviews.map((r) => _buildReviewCard(r)).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(_ReviewItem review) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 15,
                )),
              ),
              const Spacer(),
              if (review.date != null)
                Text(
                  '${review.date!.day}/${review.date!.month}/${review.date!.year}',
                  style: _fts(size: 10.5, color: Colors.black38),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: _fts(size: 12.5, color: Colors.black87),
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