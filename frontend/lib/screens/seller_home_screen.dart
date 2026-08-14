import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/store_service.dart';

// ─────────────────────────────────────────────
//  Warna Palette (konsisten dengan home_screen.dart)
// ─────────────────────────────────────────────
const Color _selGreen  = Color(0xFF007C3F);
const Color _selDark   = Color(0xFF0F1B11);
const Color _selAmber  = Color(0xFFF59E0B);
const Color _selOrange = Color(0xFFEA580C);

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

// Pilihan pasar yang tersedia untuk penjual baru
const List<String> _pasarOptions = [
  'Pasar Sepinggan',
  'Pasar Klandasan',
  'Pasar Pandansari',
];

// ─────────────────────────────────────────────
//  SellerDashboardBody
//  Dipanggil dari HomeScreen2 saat seller sudah login
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

  // ── Animasi entrance ──
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceAnim;

  // ── State toko ──
  String? _storeId;
  Map<String, dynamic>? _storeData;
  bool _checkingStore = true; // sedang cek Firestore saat pertama buka

  // ── Stream subscription ──
  StreamSubscription<QuerySnapshot>? _storeSub;

  // ── Mock orders (tetap dipertahankan selama pesanan real belum aktif) ──
  final List<_SellerOrder> _pendingOrders = [
    _SellerOrder(
      id: 'ORD-2847',
      buyerName: 'Ibu Sari',
      items: 'Cabai Merah 1kg, Bawang Merah 500g',
      total: 56000,
      eta: '± 25 mnt',
    ),
    _SellerOrder(
      id: 'ORD-2851',
      buyerName: 'Pak Rendi',
      items: 'Tomat 2kg, Wortel 1kg',
      total: 38000,
      eta: '± 40 mnt',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);
    _entranceCtrl.forward();

    _listenMyStore();
  }

  /// Subscribe ke stream toko milik user ini.
  /// - Jika tidak ada dokumen → tampilkan form registrasi gerai.
  /// - Jika ada → simpan _storeId & _storeData.
  void _listenMyStore() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _checkingStore = false);
      return;
    }

    _storeSub = StoreService.myStoreStream(uid).listen((snapshot) {
      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        // Belum punya toko — tampilkan form registrasi (hanya sekali)
        setState(() {
          _storeId = null;
          _storeData = null;
          _checkingStore = false;
        });
        // Tunda sedikit agar widget sudah terbuild, baru tampilkan modal
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _storeId == null) {
            _showRegisterStoreSheet(required: true);
          }
        });
      } else {
        final doc = snapshot.docs.first;
        setState(() {
          _storeId = doc.id;
          _storeData = doc.data() as Map<String, dynamic>?;
          _checkingStore = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _storeSub?.cancel();
    super.dispose();
  }

  // ── Getters nama & pasar dari Firestore ──
  String get _storeName {
    final name = _storeData?['store_name'] as String?;
    return (name != null && name.isNotEmpty) ? name : '${widget.userName}\'s Gerai';
  }

  String get _pasarName =>
      (_storeData?['market_section'] as String?) ?? 'Pasar Tradisional';

  String get _storeDescription =>
      (_storeData?['description'] as String?) ?? '';

  @override
  Widget build(BuildContext context) {
    if (_checkingStore) {
      return const Center(
        child: CircularProgressIndicator(color: _selGreen),
      );
    }

    return RefreshIndicator(
      color: _selGreen,
      backgroundColor: Colors.white,
      onRefresh: _handleRefresh,
      child: FadeTransition(
        opacity: _entranceAnim,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Toko
              _buildStoreHeader(),
              const SizedBox(height: 16),

              // 2. Alert Pesanan Baru
              if (_pendingOrders.isNotEmpty) ...[
                _buildOrderAlertSection(),
                const SizedBox(height: 20),
              ],

              // 3. Katalog Produk (Firestore real-time)
              _buildProductsSection(),
              const SizedBox(height: 14),

              // 3b. Placeholder Tambah Driver
              _buildAddDriverSection(),
              const SizedBox(height: 20),

              // 4. Quick Action Grid
              _buildQuickActions(),
            ],
          ),
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
                        Expanded(
                          child: Text(
                            _pasarName,
                            style: _ms(size: 11, color: Colors.black45),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Tombol Edit Toko ──
              if (_storeId != null)
                GestureDetector(
                  onTap: _showEditStoreSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded, color: _selGreen, size: 16),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('simulated_orders')
          .where('status', whereIn: ['dikemas', 'dalam_pengantaran'])
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

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
                  child: Text('${docs.length + _pendingOrders.length}', style: _ms(size: 10, weight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) => _buildSimulatedOrderCard(doc)),
            ..._pendingOrders.map((order) => _buildOrderCard(order)),
          ],
        );
      },
    );
  }

  Widget _buildSimulatedOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final orderId = data['id'] ?? 'ORD-XXXX';
    final buyerName = data['buyerName'] ?? 'Pembeli';
    final items = data['items'] ?? '';
    final totalPrice = (data['totalPrice'] as num?)?.toInt() ?? 0;
    final status = data['status'] ?? 'dikemas';
    final isPackaging = status == 'dikemas';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPackaging ? _selAmber.withValues(alpha: 0.4) : _selGreen.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPackaging ? _selAmber : _selGreen).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (isPackaging ? _selAmber : _selGreen).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: (isPackaging ? _selAmber : _selGreen).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.receipt_long_rounded, size: 14, color: isPackaging ? _selAmber : _selGreen),
                ),
                const SizedBox(width: 8),
                Text(orderId, style: _ms(size: 12, weight: FontWeight.bold, color: isPackaging ? _selAmber : _selGreen)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPackaging ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isPackaging ? Colors.orange.shade200 : Colors.green.shade200),
                  ),
                  child: Text(
                    isPackaging ? '⏳ Sedang Dikemas' : '🛵 Dalam Pengantaran',
                    style: _ms(
                      size: 9,
                      weight: FontWeight.bold,
                      color: isPackaging ? Colors.orange.shade700 : Colors.green.shade700,
                    ),
                  ),
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
                    if (isPackaging)
                      ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await doc.reference.update({'status': 'dalam_pengantaran'});
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pesanan $orderId diserahkan ke kurir!', style: _ms(size: 12, color: Colors.white)),
                              backgroundColor: _selGreen,
                            ),
                          );
                        },
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
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await doc.reference.update({'status': 'selesai'});
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pesanan $orderId telah diselesaikan!', style: _ms(size: 12, color: Colors.white)),
                              backgroundColor: _selGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Selesaikan Transaksi', style: _ms(size: 11, weight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildOrderCard(_SellerOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _selAmber.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: _selAmber.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _selAmber.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: _selAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.receipt_long_rounded, size: 14, color: _selAmber),
                ),
                const SizedBox(width: 8),
                Text(order.id, style: _ms(size: 12, weight: FontWeight.bold, color: _selAmber)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text('⏳ Menunggu Konfirmasi', style: _ms(size: 9, weight: FontWeight.bold, color: Colors.orange.shade700)),
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
                    Text(order.buyerName, style: _ms(size: 12, weight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.schedule_rounded, size: 12, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(order.eta, style: _ms(size: 10, color: Colors.black38)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(order.items, style: _ms(size: 11, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Total: Rp${_formatRupiah(order.total)}', style: _ms(size: 14, weight: FontWeight.bold, color: _selGreen)),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => _handleRejectOrder(order),
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
                      onPressed: () => _handleAcceptOrder(order),
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAcceptOrder(_SellerOrder order) {
    HapticFeedback.mediumImpact();
    setState(() => _pendingOrders.remove(order));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('Pesanan ${order.id} diterima!', style: _ms(size: 12, color: Colors.white)),
      ]),
      backgroundColor: _selGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _handleRejectOrder(_SellerOrder order) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tolak Pesanan?', style: _ms(size: 17, weight: FontWeight.bold)),
        content: Text('${order.id} dari ${order.buyerName} akan dibatalkan.', style: _ms(size: 13, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: _ms(size: 13, color: Colors.black54))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _pendingOrders.remove(order));
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
  //  3. KATALOG PENJUALAN — StreamBuilder Firestore
  // ──────────────────────────────────────────
  Widget _buildProductsSection() {
    if (_storeId == null) {
      // Toko belum terdaftar — ajak seller daftar dulu
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sellerSectionTitle('Katalog Penjualan Saya', 'Daftarkan toko untuk mulai berjualan'),
          const SizedBox(height: 12),
          _buildEmptyStoreCard(),
        ],
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: StoreService.myProductsStream(_storeId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sellerSectionTitle('Katalog Penjualan Saya', 'Memuat produk...'),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator(color: _selGreen)),
            ],
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _sellerSectionTitle(
                    'Katalog Penjualan Saya',
                    '${docs.length} produk aktif di geraimu',
                  ),
                ),
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
                        Text('Kelola', style: _ms(size: 11, weight: FontWeight.bold, color: _selGreen)),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: _selGreen),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              _buildEmptyProductCard()
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
                itemCount: docs.length > 4 ? 4 : docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildProductGridTile(data);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyStoreCard() {
    return GestureDetector(
      onTap: () => _showRegisterStoreSheet(required: false),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _selGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_business_rounded, color: _selGreen, size: 32),
            ),
            const SizedBox(height: 14),
            Text('Daftarkan Toko Anda', style: _ms(size: 14, weight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Lengkapi profil toko Anda untuk mulai berjualan dan menjangkau pembeli.',
              style: _ms(size: 11, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_selGreen, Color(0xFF00A852)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('+ Daftarkan Sekarang', style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProductCard() {
    return GestureDetector(
      onTap: () => _showAddEditProductDialog(),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
          border: Border.all(color: _selGreen.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            children: [
              Text('📦', style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text('Belum ada produk.', style: _ms(size: 13, weight: FontWeight.bold)),
              Text('Ketuk untuk menambahkan produk pertamamu!',
                  style: _ms(size: 11, color: Colors.black38), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGridTile(Map<String, dynamic> data) {
    final name = data['product_name'] as String? ?? 'Produk';
    final icon = data['category'] as String? ?? '🛒';
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final stock = (data['stock'] as num?)?.toInt() ?? 0;

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
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 42))),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stock == 0 ? Colors.red.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                  ),
                  child: Text(
                    stock == 0 ? 'Habis' : 'Stok $stock',
                    style: _ms(size: 9, weight: FontWeight.bold, color: stock == 0 ? Colors.red.shade600 : _selGreen),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(name, style: _ms(size: 13, weight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(StoreService.formatRupiah(price), style: _ms(size: 14, weight: FontWeight.bold, color: _selGreen)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  MODAL: REGISTRASI GERAI (PERTAMA KALI)
  // ──────────────────────────────────────────
  void _showRegisterStoreSheet({bool required = false}) {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedPasar = _pasarOptions.first;
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isDismissible: !required,
      enableDrag: !required,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _selGreen.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_business_rounded, color: _selGreen, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Daftarkan Toko Anda', style: _ms(size: 17, weight: FontWeight.bold)),
                                  Text('Lengkapi info toko untuk mulai berjualan', style: _ms(size: 11, color: Colors.black45)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Form(
                          key: formKey,
                          child: Column(
                            children: [
                              // Nama Toko
                              TextFormField(
                                controller: nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Nama Toko / Gerai *',
                                  labelStyle: _ms(size: 13, color: Colors.black54),
                                  hintText: 'contoh: Gerai Bu Eko',
                                  hintStyle: _ms(size: 13, color: Colors.black26),
                                  prefixIcon: const Icon(Icons.storefront_rounded, color: _selGreen, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _selGreen, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama toko wajib diisi' : null,
                              ),
                              const SizedBox(height: 14),

                              // Dropdown Sektor Pasar
                              DropdownButtonFormField<String>(
                                initialValue: selectedPasar,
                                decoration: InputDecoration(
                                  labelText: 'Sektor Pasar *',
                                  labelStyle: _ms(size: 13, color: Colors.black54),
                                  prefixIcon: const Icon(Icons.location_on_rounded, color: _selGreen, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _selGreen, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                ),
                                style: _ms(size: 14),
                                items: _pasarOptions.map((p) => DropdownMenuItem(value: p, child: Text(p, style: _ms(size: 13)))).toList(),
                                onChanged: (v) {
                                  if (v != null) setModal(() => selectedPasar = v);
                                },
                              ),
                              const SizedBox(height: 14),

                              // Deskripsi
                              TextFormField(
                                controller: descCtrl,
                                maxLines: 3,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: 'Deskripsi Toko (opsional)',
                                  labelStyle: _ms(size: 13, color: Colors.black54),
                                  hintText: 'ceritakan tentang tokomu...',
                                  hintStyle: _ms(size: 13, color: Colors.black26),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _selGreen, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.all(14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tombol Daftar
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModal(() => isLoading = true);

                                try {
                                  final uid = StoreService.currentUid;
                                  await StoreService.createStore(
                                    ownerUid: uid,
                                    storeName: nameCtrl.text.trim(),
                                    marketSection: selectedPasar,
                                    description: descCtrl.text.trim(),
                                  );

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Row(children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Toko berhasil didaftarkan! 🎉', style: _ms(size: 12, color: Colors.white)),
                                    ]),
                                    backgroundColor: _selGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 3),
                                  ));
                                } catch (e) {
                                  setModal(() => isLoading = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Gagal mendaftarkan toko: $e', style: _ms(size: 12, color: Colors.white)),
                                    backgroundColor: Colors.red.shade600,
                                  ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text('Daftarkan Toko Sekarang', style: _ms(size: 14, weight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ──────────────────────────────────────────
  //  MODAL: EDIT TOKO
  // ──────────────────────────────────────────
  void _showEditStoreSheet() {
    HapticFeedback.selectionClick();
    final nameCtrl = TextEditingController(text: _storeName);
    final descCtrl = TextEditingController(text: _storeDescription);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.edit_rounded, color: Colors.blue.shade600, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Edit Toko Saya', style: _ms(size: 17, weight: FontWeight.bold)),
                                Text('Perbarui nama dan deskripsi toko', style: _ms(size: 11, color: Colors.black45)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Form(
                          key: formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Nama Toko / Gerai *',
                                  labelStyle: _ms(size: 13, color: Colors.black54),
                                  prefixIcon: const Icon(Icons.storefront_rounded, color: _selGreen, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _selGreen, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama toko wajib diisi' : null,
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: descCtrl,
                                maxLines: 3,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: 'Deskripsi Toko',
                                  labelStyle: _ms(size: 13, color: Colors.black54),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: _selGreen, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.all(14),
                                ),
                              ),

                              const SizedBox(height: 6),
                              // Info: sektor pasar tidak bisa diubah sendiri
                              Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 13, color: Colors.black38),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Sektor pasar: $_pasarName (tidak dapat diubah)',
                                      style: _ms(size: 10, color: Colors.black38),
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

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading || _storeId == null
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModal(() => isLoading = true);

                                try {
                                  await StoreService.updateStore(
                                    _storeId!,
                                    storeName: nameCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                  );

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Row(children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Profil toko berhasil diperbarui!', style: _ms(size: 12, color: Colors.white)),
                                    ]),
                                    backgroundColor: _selGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 2),
                                  ));
                                } catch (e) {
                                  setModal(() => isLoading = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Gagal memperbarui: $e', style: _ms(size: 12, color: Colors.white)),
                                    backgroundColor: Colors.red.shade600,
                                  ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Simpan Perubahan', style: _ms(size: 14, weight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ──────────────────────────────────────────
  //  BOTTOM SHEET: KELOLA SEMUA PRODUK (Firestore)
  // ──────────────────────────────────────────
  void _showAllProductsSheet() {
    if (_storeId == null) {
      _showRegisterStoreSheet(required: false);
      return;
    }
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
          builder: (ctx2, scrollController) {
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kelola Produk', style: _ms(size: 17, weight: FontWeight.bold)),
                              Text('Tambah, edit, atau hapus produk geraimu', style: _ms(size: 11, color: Colors.black45)),
                            ],
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
                      stream: StoreService.myProductsStream(_storeId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: _selGreen));
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('📦', style: const TextStyle(fontSize: 48)),
                                  const SizedBox(height: 12),
                                  Text('Belum ada produk', style: _ms(size: 14, weight: FontWeight.bold)),
                                  Text('Ketuk "Tambah" untuk menambahkan produk pertamamu',
                                      style: _ms(size: 11, color: Colors.black38), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: docs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return _buildManageProductTile(doc.id, data);
                          },
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

  Widget _buildManageProductTile(String docId, Map<String, dynamic> data) {
    final name = data['product_name'] as String? ?? 'Produk';
    final icon = data['category'] as String? ?? '🛒';
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final stock = (data['stock'] as num?)?.toInt() ?? 0;

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
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: _ms(size: 13, weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Stok: $stock', style: _ms(size: 10, color: Colors.black38)),
                const SizedBox(height: 2),
                Text(StoreService.formatRupiah(price), style: _ms(size: 12, weight: FontWeight.bold, color: _selGreen)),
              ],
            ),
          ),
          // Edit
          GestureDetector(
            onTap: () => _showAddEditProductDialog(existingId: docId, existingData: data),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.edit_rounded, size: 16, color: Colors.blue.shade600),
            ),
          ),
          const SizedBox(width: 8),
          // Hapus
          GestureDetector(
            onTap: () => _confirmDeleteProduct(docId, name),
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
  //  DIALOG: TAMBAH / EDIT PRODUK (Firestore)
  // ──────────────────────────────────────────
  void _showAddEditProductDialog({String? existingId, Map<String, dynamic>? existingData}) {
    if (_storeId == null) {
      _showRegisterStoreSheet(required: false);
      return;
    }

    final isEdit = existingId != null;
    final nameCtrl = TextEditingController(text: existingData?['product_name'] ?? '');
    final iconCtrl = TextEditingController(text: existingData?['category'] ?? '🛒');
    final priceCtrl = TextEditingController(text: existingData != null ? existingData['price'].toString() : '');
    final stockCtrl = TextEditingController(text: existingData != null ? existingData['stock'].toString() : '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk', style: _ms(size: 16, weight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: TextFormField(
                          controller: iconCtrl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22),
                          decoration: InputDecoration(
                            labelText: 'Ikon',
                            labelStyle: _ms(size: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Nama Produk *',
                            labelStyle: _ms(size: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Harga (Rp) *',
                            labelStyle: _ms(size: 12),
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
                            labelText: 'Stok *',
                            labelStyle: _ms(size: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          validator: (v) => (int.tryParse(v ?? '') == null) ? 'Harus angka' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: _ms(size: 13, color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialog(() => isLoading = true);

                      try {
                        final uid = StoreService.currentUid;
                        final emojiVal = iconCtrl.text.trim().isEmpty ? '🛒' : iconCtrl.text.trim();

                        if (isEdit) {
                          await StoreService.updateProduct(
                            existingId,
                            productName: nameCtrl.text.trim(),
                            price: int.parse(priceCtrl.text.trim()),
                            stock: int.parse(stockCtrl.text.trim()),
                            category: emojiVal,
                          );
                        } else {
                          await StoreService.addProduct(
                            storeId: _storeId!,
                            ownerUid: uid,
                            productName: nameCtrl.text.trim(),
                            price: int.parse(priceCtrl.text.trim()),
                            stock: int.parse(stockCtrl.text.trim()),
                            category: emojiVal,
                          );
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(isEdit ? 'Produk berhasil diperbarui ✓' : 'Produk berhasil ditambahkan ✓',
                              style: _ms(size: 12, color: Colors.white)),
                          backgroundColor: _selGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ));
                      } catch (e) {
                        setDialog(() => isLoading = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Gagal: $e', style: _ms(size: 12, color: Colors.white)),
                          backgroundColor: Colors.red.shade600,
                        ));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Simpan' : 'Tambahkan', style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDeleteProduct(String docId, String name) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Produk?', style: _ms(size: 16, weight: FontWeight.bold)),
        content: Text('$name akan dihapus dari daftar produkmu secara permanen.', style: _ms(size: 13, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: _ms(size: 13, color: Colors.black54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await StoreService.deleteProduct(docId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$name berhasil dihapus', style: _ms(size: 12, color: Colors.white)),
                  backgroundColor: Colors.red.shade500,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Gagal menghapus: $e', style: _ms(size: 12, color: Colors.white)),
                  backgroundColor: Colors.red.shade600,
                ));
              }
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

  // ──────────────────────────────────────────
  //  3b. PLACEHOLDER TAMBAH DRIVER
  // ──────────────────────────────────────────
  final List<_SellerDriver> _assignedDrivers = [];

  Widget _buildAddDriverSection() {
    return GestureDetector(
      onTap: _showAddDriverDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1.5),
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
                  const Icon(Icons.chevron_right_rounded, color: Colors.black26),
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
                                    textAlign: TextAlign.center, style: _ms(size: 11, color: Colors.black38)),
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

  // ──────────────────────────────────────────
  //  5. QUICK ACTIONS
  // ──────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(icon: Icons.add_box_rounded, label: 'Tambah\nProduk', color: _selGreen, onTap: () => _showAddEditProductDialog()),
      _QuickAction(icon: Icons.tune_rounded, label: 'Kelola\nStok', color: const Color(0xFF1565C0), onTap: () => _showAllProductsSheet()),
      _QuickAction(icon: Icons.local_shipping_rounded, label: 'Status\nPengiriman', color: _selOrange, onTap: () => _showComingSoon('Status Pengiriman')),
      _QuickAction(icon: Icons.analytics_outlined, label: 'Laporan\nLengkap', color: Colors.deepPurple, onTap: () => _showComingSoon('Laporan Lengkap')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sellerSectionTitle('Aksi Cepat', 'Kelola geraimu dengan mudah'),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) => Expanded(
            child: GestureDetector(
              onTap: a.onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: a.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(a.icon, color: a.color, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(a.label, style: _ms(size: 9, weight: FontWeight.bold, color: _selDark), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          )).toList(),
        ),
      ],
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
//  Model Classes (internal)
// ─────────────────────────────────────────────
class _SellerOrder {
  final String id, buyerName, items, eta;
  final int total;
  _SellerOrder({required this.id, required this.buyerName, required this.items, required this.total, required this.eta});
}

class _SellerDriver {
  final String name, email;
  const _SellerDriver({required this.name, required this.email});
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}