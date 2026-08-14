import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/auth_service.dart';

// ─────────────────────────────────────────────
//  Warna Palette (konsisten dengan home_screen.dart)
// ─────────────────────────────────────────────
const Color _selGreen   = Color(0xFF007C3F);
const Color _selDark    = Color(0xFF0F1B11);
const Color _selAmber   = Color(0xFFF59E0B);
const Color _selOrange  = Color(0xFFEA580C);

TextStyle _ms({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _selDark,
  double? height,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

// ─────────────────────────────────────────────
//  SellerDashboardBody
//  Dipanggil dari HomeScreen saat _isSeller == true
// ─────────────────────────────────────────────
class SellerDashboardBody extends StatefulWidget {
  final String userName;
  final String? photoUrl;

  const SellerDashboardBody({
    super.key,
    required this.userName,
    this.photoUrl,
  });

  @override
  State<SellerDashboardBody> createState() => _SellerDashboardBodyState();
}

class _SellerDashboardBodyState extends State<SellerDashboardBody>
    with TickerProviderStateMixin {

  // ── Animasi controller untuk metric cards entrance ──
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceAnim;

  // ── Data Gerai dari Firestore (stream) ──
  Map<String, dynamic>? _geraiData;
  StreamSubscription<DocumentSnapshot>? _geraiSub;

  // ── Produk yang dijual — sekarang diambil real-time dari Firestore ──
  Stream<QuerySnapshot>? _productsStream;

  // ── Mock driver yang sudah terdaftar di gerai ──
  final List<_SellerDriver> _assignedDrivers = [];

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);
    _entranceCtrl.forward();

    _listenGerai();
    _initProductsStream();
  }

  void _listenGerai() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _geraiSub = FirebaseFirestore.instance
        .collection('seller')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (mounted) {
        setState(() => _geraiData = snap.data());
      }
    });
  }

  void _initProductsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _productsStream = FirebaseFirestore.instance
        .collection('seller')
        .doc(uid)
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _geraiSub?.cancel();
    super.dispose();
  }

  String get _storeName {
    final name = _geraiData?['namaToko'] as String?;
    return (name != null && name.isNotEmpty) ? name : '${widget.userName}\'s Gerai';
  }

  String get _pasarName => (_geraiData?['namaPasar'] as String?) ?? 'Pasar Tradisional';

  CollectionReference<Map<String, dynamic>>? get _productsCollection {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('seller')
        .doc(uid)
        .collection('products');
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _selGreen,
      backgroundColor: Colors.white,
      onRefresh: _handleRefresh,
      child: FadeTransition(
        opacity: _entranceAnim,
        // Align + LayoutBuilder di sini memaksa konten selalu menempel ke atas,
        // bahkan kalau widget ini dibungkus Center() oleh parent (mis. saat
        // daftar produk kosong sehingga tinggi konten jadi pendek).
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 1. Header Toko
                      _buildStoreHeader(),
                      const SizedBox(height: 16),

                      // 2. Alert Pesanan Baru (real-time dari Firestore)
                      _buildOrderAlertSection(),
                      const SizedBox(height: 20),

                      // 3. Produk yang Dijual (real-time dari Firestore)
                      _buildProductsSection(),
                      const SizedBox(height: 32),

                      // 3b. Placeholder Tambah Driver
                      _buildAddDriverSection(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  // ──────────────────────────────────────────
  //  1. STORE HEADER
  // ──────────────────────────────────────────
  Widget _buildStoreHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [_selGreen, Color(0xFF00A852)]),
                  boxShadow: [BoxShadow(color: _selGreen.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
                  image: widget.photoUrl != null
                      ? DecorationImage(image: NetworkImage(widget.photoUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: widget.photoUrl == null
                    ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 26)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _storeName,
                            style: _ms(size: 16, weight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_selGreen, Color(0xFF00A852)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, color: Colors.white, size: 10),
                              const SizedBox(width: 3),
                              Text('Nemu+', style: _ms(size: 9, weight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: Colors.black38),
                        const SizedBox(width: 3),
                        Text(_pasarName, style: _ms(size: 11, color: Colors.black45)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          // Toggle Buka/Tutup
          StreamBuilder<bool>(
            stream: AuthService.storeOpenStatusStream(),
            builder: (context, snapshot) {
              final isOpen = snapshot.data ?? true;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isOpen ? _selGreen.withValues(alpha: 0.10) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOpen ? Icons.store_rounded : Icons.store_mall_directory_outlined,
                      color: isOpen ? _selGreen : Colors.grey.shade400,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOpen ? 'Toko Sedang Buka' : 'Toko Sedang Tutup',
                          style: _ms(size: 13, weight: FontWeight.bold, color: isOpen ? _selGreen : Colors.grey.shade600),
                        ),
                        Text(
                          isOpen ? 'Pembeli dapat melihat & memesan produkmu' : 'Produkmu disembunyikan sementara',
                          style: _ms(size: 10, color: Colors.black38),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      AuthService.updateStoreOpenStatus(!isOpen);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 52,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isOpen ? _selGreen : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [if (isOpen) BoxShadow(color: _selGreen.withValues(alpha: 0.35), blurRadius: 8)],
                      ),
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            left: isOpen ? 26 : 2,
                            top: 2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  2. ALERT PESANAN BARU
  // ──────────────────────────────────────────
  Widget _buildOrderAlertSection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: uid)
          .where('status', whereIn: ['menunggu_konfirmasi', 'dikemas', 'dalam_pengantaran'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text('Pesanan Baru Masuk', style: _ms(size: 14, weight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red.shade500, borderRadius: BorderRadius.circular(20)),
                  child: Text('${docs.length}', style: _ms(size: 10, weight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) => _buildRealOrderCard(doc)),
          ],
        );
      },
    );
  }

  Widget _buildRealOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final orderId = (data['orderCode'] as String?) ?? doc.id;
    final buyerName = (data['buyerName'] as String?) ?? 'Pembeli';
    final items = (data['itemsSummary'] as String?) ?? '';
    final totalPrice = (data['totalPrice'] as num?)?.toInt() ?? 0;
    final status = (data['status'] as String?) ?? 'menunggu_konfirmasi';

    final bool isWaiting = status == 'menunggu_konfirmasi';
    final bool isPackaging = status == 'dikemas';

    final Color accent = isWaiting
        ? Colors.orange
        : (isPackaging ? _selAmber : _selGreen);

    final String badgeText = isWaiting
        ? '⏳ Menunggu Konfirmasi'
        : (isPackaging ? '⏳ Sedang Dikemas' : '🛵 Dalam Pengantaran');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.receipt_long_rounded, size: 14, color: accent),
                ),
                const SizedBox(width: 8),
                Text(orderId, style: _ms(size: 12, weight: FontWeight.bold, color: accent)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(badgeText, style: _ms(size: 9, weight: FontWeight.bold, color: accent)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 14, color: Colors.black38),
                    const SizedBox(width: 6),
                    Text(buyerName, style: _ms(size: 12, weight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.schedule_rounded, size: 12, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text('Real-time', style: _ms(size: 10, color: Colors.black38)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(items, style: _ms(size: 11, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Total: Rp${_formatRupiah(totalPrice)}', style: _ms(size: 14, weight: FontWeight.bold, color: _selGreen)),
                    const Spacer(),
                    if (isWaiting) ...[
                      OutlinedButton(
                        onPressed: () => _handleRejectOrder(doc.reference, orderId, buyerName),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Tolak', style: _ms(size: 11, weight: FontWeight.bold, color: Colors.red.shade600)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _handleAcceptOrder(doc.reference, orderId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Terima ✓', style: _ms(size: 11, weight: FontWeight.bold, color: Colors.white)),
                      ),
                    ] else if (isPackaging)
                      ElevatedButton(
                        onPressed: () => _updateOrderStatus(
                          doc.reference,
                          'dalam_pengantaran',
                          successMessage: 'Pesanan $orderId diserahkan ke kurir!',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selAmber,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Selesai Mengemas / Serahkan ke Kurir', style: _ms(size: 11, weight: FontWeight.bold, color: Colors.white)),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _updateOrderStatus(
                          doc.reference,
                          'selesai',
                          successMessage: 'Pesanan $orderId telah diselesaikan!',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Selesaikan Transaksi (Selesai)', style: _ms(size: 11, weight: FontWeight.bold, color: Colors.white)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Update status pesanan langsung ke Firestore (data real) ──
  Future<void> _updateOrderStatus(
    DocumentReference ref,
    String newStatus, {
    String? successMessage,
  }) async {
    HapticFeedback.mediumImpact();
    try {
      await ref.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage, style: _ms(size: 12, color: Colors.white)),
            backgroundColor: _selGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui pesanan: $e', style: _ms(size: 12, color: Colors.white)),
            backgroundColor: Colors.red.shade500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _handleAcceptOrder(DocumentReference ref, String orderId) {
    _updateOrderStatus(
      ref,
      'dikemas',
      successMessage: 'Pesanan $orderId diterima!',
    );
  }

  void _handleRejectOrder(DocumentReference ref, String orderId, String buyerName) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tolak Pesanan?', style: _ms(size: 17, weight: FontWeight.bold)),
        content: Text('$orderId dari $buyerName akan dibatalkan.', style: _ms(size: 13, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: _ms(size: 13, color: Colors.black54))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateOrderStatus(
                ref,
                'dibatalkan',
                successMessage: 'Pesanan $orderId ditolak.',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Ya, Tolak', style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  3. PRODUK YANG DIJUAL (real-time dari Firestore)
  // ──────────────────────────────────────────
  Widget _buildProductsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _productsStream,
      builder: (context, snapshot) {
        final products = (snapshot.hasData)
            ? snapshot.data!.docs
                .map((d) => _SellerProduct.fromDoc(d))
                .toList()
            : <_SellerProduct>[];
        final preview = products.take(4).toList();
        final isLoading = !snapshot.hasData && !snapshot.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _sellerSectionTitle('Produk Dijual', '${products.length} produk aktif di geraimu'),
                ),
                if (kDebugMode) ...[
                  GestureDetector(
                    onTap: _seedDummyProducts,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 13, color: Colors.orange.shade700),
                          const SizedBox(width: 3),
                          Text('Seed', style: _ms(size: 11, weight: FontWeight.bold, color: Colors.orange.shade700)),
                        ],
                      ),
                    ),
                  ),
                ],
                GestureDetector(
                  onTap: _showAllProductsSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Selengkapnya', style: _ms(size: 11, weight: FontWeight.bold, color: _selGreen)),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: _selGreen),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: _selGreen),
                  ),
                ),
              )
            else if (preview.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Text('Belum ada produk. Tambahkan produk pertamamu!',
                      style: _ms(size: 12, color: Colors.black38), textAlign: TextAlign.center),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 190,
                ),
                itemCount: preview.length,
                itemBuilder: (context, index) => _buildProductGridTile(preview[index]),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProductGridTile(_SellerProduct product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 84,
                decoration: BoxDecoration(
                  color: _selGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: product.imageUrl.trim().isEmpty
                      ? Center(
                          child: Icon(
                            Icons.shopping_basket_rounded,
                            size: 36,
                            color: _selGreen.withValues(alpha: 0.4),
                          ),
                        )
                      : Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _selGreen.withValues(alpha: 0.5)),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size: 30,
                              color: _selGreen.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                  ),
                  child: Text('Stok ${product.stock}', style: _ms(size: 9, weight: FontWeight.bold, color: _selGreen)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(product.name, style: _ms(size: 13, weight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(product.unit, style: _ms(size: 10, color: Colors.black38)),
          const SizedBox(height: 6),
          Text('Rp${_formatRupiah(product.price)}', style: _ms(size: 14, weight: FontWeight.bold, color: _selGreen)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  3c. HALAMAN KELOLA SEMUA PRODUK (real-time, StreamBuilder)
  // ──────────────────────────────────────────
  void _showAllProductsSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _productsStream,
                            builder: (context, snap) {
                              final count = snap.data?.docs.length ?? 0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kelola Produk', style: _ms(size: 17, weight: FontWeight.bold)),
                                  Text('$count produk terdaftar', style: _ms(size: 11, color: Colors.black45)),
                                ],
                              );
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAddEditProductDialog(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text('Tambah', style: _ms(size: 12, weight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _productsStream,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(
                            child: Text('Gagal memuat produk.', style: _ms(size: 12, color: Colors.black38)),
                          );
                        }
                        if (!snap.hasData) {
                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: _selGreen),
                            ),
                          );
                        }
                        final products = snap.data!.docs.map((d) => _SellerProduct.fromDoc(d)).toList();
                        if (products.isEmpty) {
                          return Center(
                            child: Text('Belum ada produk.', style: _ms(size: 12, color: Colors.black38)),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _buildManageProductTile(products[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildManageProductTile(_SellerProduct product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _selGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl.trim().isEmpty
                  ? Center(
                      child: Icon(
                        Icons.shopping_basket_rounded,
                        size: 20,
                        color: _selGreen.withValues(alpha: 0.4),
                      ),
                    )
                  : Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _selGreen.withValues(alpha: 0.5)),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          size: 18,
                          color: _selGreen.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: _ms(size: 13, weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Stok: ${product.stock} • ${product.unit}', style: _ms(size: 10, color: Colors.black38)),
                const SizedBox(height: 2),
                Text('Rp${_formatRupiah(product.price)}', style: _ms(size: 12, weight: FontWeight.bold, color: _selGreen)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showAddEditProductDialog(existing: product),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.edit_rounded, size: 16, color: Colors.blue.shade600),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _confirmDeleteProduct(product),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  3d. TAMBAH / EDIT PRODUK — sekarang disimpan ke Firestore
  // ──────────────────────────────────────────
  void _showAddEditProductDialog({_SellerProduct? existing}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return _ProductFormDialog(
          existing: existing,
          selGreen: _selGreen,
          textStyle: _ms,
          onSave: (newProduct) => _saveProduct(existing: existing, newProduct: newProduct),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curvedAnim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );
      },
    );
  }

  // ── DEBUG ONLY: seed produk dummy untuk testing kelola produk ──
  Future<void> _seedDummyProducts() async {
    final col = _productsCollection;
    if (col == null) return;

    final dummyProducts = [
      {
        'name': 'Bawang Merah',
        'imageUrl': 'https://images.unsplash.com/photo-1580201092675-a0a6a6cafbb1',
        'unit': 'per kg',
        'price': 32000,
        'stock': 25,
      },
      {
        'name': 'Cabai Rawit Merah',
        'imageUrl': 'https://images.unsplash.com/photo-1583119912267-cc97c911e416',
        'unit': 'per kg',
        'price': 45000,
        'stock': 15,
      },
      {
        'name': 'Tomat Segar',
        'imageUrl': 'https://images.unsplash.com/photo-1546470427-e5ac89c8ba4d',
        'unit': 'per kg',
        'price': 12000,
        'stock': 40,
      },
      {
        'name': 'Telur Ayam',
        'imageUrl': '',
        'unit': 'per 1/2 kg',
        'price': 15000,
        'stock': 30,
      },
      {
        'name': 'Beras Premium',
        'imageUrl': '',
        'unit': 'per 5 kg',
        'price': 68000,
        'stock': 10,
      },
    ];

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final p in dummyProducts) {
        final ref = col.doc();
        batch.set(ref, {
          ...p,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${dummyProducts.length} produk dummy ditambahkan',
              style: _ms(size: 12, color: Colors.white)),
          backgroundColor: _selGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal seed produk: $e', style: _ms(size: 12, color: Colors.white)),
          backgroundColor: Colors.red.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<void> _saveProduct({
    required _SellerProduct? existing,
    required _SellerProduct newProduct,
  }) async {
    final col = _productsCollection;
    if (col == null) return;

    try {
      if (existing != null && existing.id != null) {
        await col.doc(existing.id).update(newProduct.toMap());
      } else {
        await col.add({
          ...newProduct.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            existing != null ? 'Produk diperbarui' : 'Produk ditambahkan',
            style: _ms(size: 12, color: Colors.white),
          ),
          backgroundColor: _selGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan produk: $e', style: _ms(size: 12, color: Colors.white)),
          backgroundColor: Colors.red.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  void _confirmDeleteProduct(_SellerProduct product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Produk?', style: _ms(size: 16, weight: FontWeight.bold)),
        content: Text('${product.name} akan dihapus dari daftar produkmu.', style: _ms(size: 13, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: _ms(size: 13, color: Colors.black54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Ya, Hapus', style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(_SellerProduct product) async {
    final col = _productsCollection;
    if (col == null || product.id == null) return;

    try {
      await col.doc(product.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product.name} dihapus', style: _ms(size: 12, color: Colors.white)),
          backgroundColor: Colors.red.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menghapus produk: $e', style: _ms(size: 12, color: Colors.white)),
          backgroundColor: Colors.red.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  // ──────────────────────────────────────────
  //  4b. PLACEHOLDER TAMBAH DRIVER
  // ──────────────────────────────────────────
  Widget _buildAddDriverSection() {
    return GestureDetector(
      onTap: _showAddDriverDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1.5, style: BorderStyle.solid),
        ),
        child: _assignedDrivers.isEmpty
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _selGreen.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: _selGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tambah Driver untuk Gerai', style: _ms(size: 13, weight: FontWeight.bold)),
                        Text('Cari driver berdasarkan nama atau email', style: _ms(size: 10, color: Colors.black38)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.black26),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Driver Gerai', style: _ms(size: 13, weight: FontWeight.bold)),
                      const Spacer(),
                      Icon(Icons.add_circle_rounded, color: _selGreen, size: 20),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._assignedDrivers.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _selGreen.withValues(alpha: 0.12),
                              child: Text(d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                                  style: _ms(size: 12, weight: FontWeight.bold, color: _selGreen)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.name, style: _ms(size: 12, weight: FontWeight.w600)),
                                  Text(d.email, style: _ms(size: 10, color: Colors.black38)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
      ),
    );
  }

  void _showAddDriverDialog() {
    HapticFeedback.selectionClick();
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tambah Driver', style: _ms(size: 17, weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Cari driver berdasarkan nama atau email untuk ditambahkan ke geraimu',
                            style: _ms(size: 11, color: Colors.black45)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Nama atau email driver...',
                            hintStyle: _ms(size: 13, color: Colors.black38),
                            prefixIcon: const Icon(Icons.search_rounded, color: Colors.black38),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: (_) => _showComingSoon('Cari Driver'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(Icons.local_shipping_outlined, size: 40, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text('Hasil pencarian driver akan\nmuncul di sini',
                                    textAlign: TextAlign.center,
                                    style: _ms(size: 11, color: Colors.black38)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showComingSoon('Tambah Driver');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text('Cari & Tambahkan', style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showComingSoon(String fitur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$fitur — Segera hadir!', style: _ms(size: 12, color: Colors.white)),
      backgroundColor: _selGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ──────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────
  Widget _sellerSectionTitle(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _ms(size: 15, weight: FontWeight.bold, color: Colors.white)),
        Text(sub, style: _ms(size: 11, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  String _formatRupiah(int value) {
    if (value >= 1000000) {
      final juta = value / 1000000;
      return juta == juta.truncateToDouble() ? '${juta.toInt()}jt' : '${juta.toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      final ribu = value / 1000;
      return ribu == ribu.truncateToDouble() ? '${ribu.toInt()}rb' : '${ribu.toStringAsFixed(0)}rb';
    }
    return value.toString();
  }
}

// ─────────────────────────────────────────────
//  Model Classes
// ─────────────────────────────────────────────
class _SellerProduct {
  final String? id; // null = belum tersimpan di Firestore
  final String name, imageUrl, unit;
  final int price, stock;

  const _SellerProduct({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.unit,
    required this.price,
    required this.stock,
  });

  factory _SellerProduct.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return _SellerProduct(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      imageUrl: (d['imageUrl'] as String?) ?? '',
      unit: (d['unit'] as String?) ?? '',
      price: (d['price'] as num?)?.toInt() ?? 0,
      stock: (d['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'imageUrl': imageUrl,
        'unit': unit,
        'price': price,
        'stock': stock,
      };
}

class _SellerDriver {
  final String name, email;
  const _SellerDriver({required this.name, required this.email});
}

// ─────────────────────────────────────────────
//  Dialog Tambah/Edit Produk
// ─────────────────────────────────────────────
class _ProductFormDialog extends StatefulWidget {
  final _SellerProduct? existing;
  final Color selGreen;
  final TextStyle Function({double size, FontWeight weight, Color color, double? height}) textStyle;
  final void Function(_SellerProduct product) onSave;

  const _ProductFormDialog({
    required this.existing,
    required this.selGreen,
    required this.textStyle,
    required this.onSave,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController imageUrlCtrl;
  late final TextEditingController unitCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController stockCtrl;
  final formKey = GlobalKey<FormState>();

  bool _imageLoadFailed = false;
  String _lastCheckedUrl = '';
  bool _isSaving = false;

  bool get isEdit => widget.existing != null;

  bool _looksLikeDirectImageUrl(String url) {
    if (url.isEmpty) return true;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }
    final path = uri.path.toLowerCase();
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.avif', '.bmp'];
    final hasImageExtension = imageExtensions.any((ext) => path.endsWith(ext));
    const knownImageCdnHosts = ['images.unsplash.com', 'cdn.pixabay.com', 'images.pexels.com'];
    final isKnownCdn = knownImageCdnHosts.any((host) => uri.host.endsWith(host));
    return hasImageExtension || isKnownCdn;
  }

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    imageUrlCtrl = TextEditingController(text: widget.existing?.imageUrl ?? '');
    unitCtrl = TextEditingController(text: widget.existing?.unit ?? 'per kg');
    priceCtrl = TextEditingController(text: widget.existing != null ? widget.existing!.price.toString() : '');
    stockCtrl = TextEditingController(text: widget.existing != null ? widget.existing!.stock.toString() : '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    imageUrlCtrl.dispose();
    unitCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final selGreen = widget.selGreen;
    final ms = widget.textStyle;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit Produk' : 'Tambah Produk', style: ms(size: 16, weight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Preview foto dari URL
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: selGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageUrlCtrl.text.trim().isEmpty
                        ? Center(
                            child: Icon(Icons.image_outlined, size: 32, color: selGreen.withValues(alpha: 0.4)),
                          )
                        : !_looksLikeDirectImageUrl(imageUrlCtrl.text.trim())
                            ? Center(
                                child: Icon(Icons.image_not_supported_rounded, size: 28, color: selGreen.withValues(alpha: 0.4)),
                              )
                            : Image.network(
                                imageUrlCtrl.text.trim(),
                                key: ValueKey(imageUrlCtrl.text.trim()),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: selGreen.withValues(alpha: 0.5)),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  final url = imageUrlCtrl.text.trim();
                                  if (_lastCheckedUrl != url) {
                                    _lastCheckedUrl = url;
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _safeSetState(() => _imageLoadFailed = true);
                                    });
                                  }
                                  return Center(
                                    child: Icon(Icons.image_not_supported_rounded, size: 28, color: selGreen.withValues(alpha: 0.4)),
                                  );
                                },
                              ),
                  ),
                ),
                if (_imageLoadFailed) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 15, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Link ini bukan link gambar langsung, jadi tidak bisa dimuat. Buka gambarnya, klik kanan, lalu pilih "Salin alamat gambar" (Copy image address) — bukan menyalin link halaman.',
                            style: ms(size: 10.5, color: Colors.orange.shade800, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: imageUrlCtrl,
                  keyboardType: TextInputType.url,
                  onChanged: (value) => _safeSetState(() {
                    final trimmed = value.trim();
                    _imageLoadFailed = trimmed.isNotEmpty && !_looksLikeDirectImageUrl(trimmed);
                    _lastCheckedUrl = '';
                  }),
                  decoration: InputDecoration(
                    labelText: 'URL Foto Produk',
                    labelStyle: ms(size: 12),
                    hintText: 'https://...',
                    hintStyle: ms(size: 11, color: Colors.black26),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Produk',
                    labelStyle: ms(size: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: unitCtrl,
                  decoration: InputDecoration(
                    labelText: 'Satuan (contoh: per kg)',
                    labelStyle: ms(size: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga (Rp)',
                          labelStyle: ms(size: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => (int.tryParse(v ?? '') == null) ? 'Harus angka' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Stok',
                          labelStyle: ms(size: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => (int.tryParse(v ?? '') == null) ? 'Harus angka' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: Text('Batal', style: ms(size: 13, color: Colors.black54)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (!formKey.currentState!.validate()) return;

                              final newProduct = _SellerProduct(
                                id: widget.existing?.id,
                                name: nameCtrl.text.trim(),
                                imageUrl: imageUrlCtrl.text.trim(),
                                unit: unitCtrl.text.trim(),
                                price: int.parse(priceCtrl.text.trim()),
                                stock: int.parse(stockCtrl.text.trim()),
                              );

                              setState(() => _isSaving = true);
                              Navigator.pop(context);
                              widget.onSave(newProduct);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isEdit ? 'Simpan' : 'Tambahkan', style: ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}