import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/driver_service.dart';
import 'package:frontend/services/order_tracking_service.dart';
import 'package:frontend/services/store_service.dart';
import 'package:frontend/widgets/live_tracking_map.dart';
import 'package:frontend/models/orders_manager.dart';
import 'package:frontend/screens/inbox_screen.dart';

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

// Pilihan pasar yang tersedia untuk penjual
const List<String> _pasarOptions = [
  'Pasar Pandansari',
  'Pasar Klandasan',
  'Pasar Sepinggan',
  'Pasar Baru',
  'Pasar Segar',
  'Pasar Balikpapan Permai',
  'Pasar Manggar',
  'Pasar Butun',
  'Pasar Kebun Sayur',
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

  // ── State gerai (dari Firestore koleksi 'stores') ──
  StreamSubscription<QuerySnapshot>? _storeSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sellerSub;
  Map<String, dynamic>? _storeData;
  String? _storeId;
  bool _isLoadingStore = true;

  // ── Driver yang sudah accept undangan dari gerai ini (realtime) ──
  List<_SellerDriver> _assignedDrivers = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _driversSub;

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
    _listenAssignedDrivers();
  }

  /// Mendengarkan data toko milik user yang sedang login dari koleksi `stores`
  void _listenMyStore() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingStore = false);
      return;
    }

    _storeSub = StoreService.myStoreStream(uid).listen((snap) {
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        if (mounted) {
          setState(() {
            _storeId = doc.id;
            _storeData = doc.data() as Map<String, dynamic>?;
            _isLoadingStore = false;
          });
        }
      } else {
        // Fallback jika baru terdaftar di seller/{uid}
        _listenSellerFallback(uid);
      }
    }, onError: (e) {
      debugPrint('Gagal memuat toko dari collection stores: $e');
      _listenSellerFallback(uid);
    });
  }

  void _listenSellerFallback(String uid) {
    _sellerSub?.cancel();
    _sellerSub = FirebaseFirestore.instance
        .collection('seller')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (mounted) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          setState(() {
            _storeId = (data['store_id'] as String?) ?? uid;
            _storeData = {
              'store_name': data['store_name'] ?? data['name'],
              'market_type': data['market_type'] ?? data['market_section'] ?? 'Pasar Pandansari',
              'is_open': data['isOpen'] ?? true,
              'description': data['description'] ?? '',
              'owner_id': uid,
            };
            _isLoadingStore = false;
          });
        } else {
          setState(() {
            _storeId = null;
            _storeData = null;
            _isLoadingStore = false;
          });
        }
      }
    }, onError: (e) {
      debugPrint('Gagal memuat seller data: $e');
      if (mounted) setState(() => _isLoadingStore = false);
    });
  }

  void _listenAssignedDrivers() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _driversSub = FirebaseFirestore.instance
        .collectionGroup('inbox')
        .where('type', isEqualTo: 'driver_invite')
        .where('status', isEqualTo: 'accepted')
        .where('fromUid', isEqualTo: uid)
        .snapshots()
        .listen((snap) async {
      final drivers = await Future.wait(snap.docs.map((doc) async {
        final driverUid = doc.reference.parent.parent?.id;
        if (driverUid == null) return null;

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(driverUid)
            .get();
        final data = userDoc.data();

        return _SellerDriver(
          name: (data?['name'] as String?) ?? 'Driver',
          email: (data?['email'] as String?) ?? '-',
          photoUrl: data?['photoUrl'] as String?,
        );
      }));

      if (mounted) {
        setState(() {
          _assignedDrivers = drivers.whereType<_SellerDriver>().toList();
        });
      }
    }, onError: (e) {
      debugPrint('Gagal memuat daftar driver: $e');
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _storeSub?.cancel();
    _sellerSub?.cancel();
    _driversSub?.cancel();
    super.dispose();
  }

  // ── Getters info toko ──
  String get _storeName {
    final name = _storeData?['store_name'] as String?;
    return (name != null && name.isNotEmpty) ? name : '${widget.userName}\'s Gerai';
  }

  String get _marketType =>
      (_storeData?['market_type'] as String?) ??
      (_storeData?['market_section'] as String?) ??
      'Pasar Pandansari';

  String get _storeDescription =>
      (_storeData?['description'] as String?) ?? '';

  bool get _isOpen =>
      (_storeData?['is_open'] as bool?) ??
      (_storeData?['isOpen'] as bool?) ??
      (_storeData?['is_active'] as bool?) ??
      true;

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStore) {
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
                    children: [
                      // 1. Header Toko / Daftarkan Toko jika belum punya
                      if (_storeId != null)
                        _buildStoreHeader()
                      else
                        _buildEmptyStoreCard(),
                      const SizedBox(height: 16),

                      // 2. Alert Pesanan Baru (real-time dari Firestore)
                      if (_storeId != null) ...[
                        _buildOrderAlertSection(),
                        const SizedBox(height: 20),
                      ],

                      // 3. Quick Actions
                      if (_storeId != null) ...[
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                      ],

                      // 4. Katalog Barang Saya (real-time dari Firestore)
                      _buildProductsSection(),
                      const SizedBox(height: 28),

                      // 5. Driver Gerai
                      if (_storeId != null)
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
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
                  boxShadow: [
                    BoxShadow(
                      color: _selGreen.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
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
                            _marketType,
                            style: _ms(size: 11, color: Colors.black45),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Tombol Edit Toko (Profil Gerai Saya) ──
              GestureDetector(
                onTap: _showEditStoreSheet,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, color: _selGreen, size: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          // Toggle Status Toko: Buka / Tutup
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isOpen ? _selGreen.withValues(alpha: 0.10) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isOpen ? Icons.store_rounded : Icons.store_mall_directory_outlined,
                  color: _isOpen ? _selGreen : Colors.grey.shade400,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOpen ? 'Toko Sedang Buka' : 'Toko Sedang Tutup',
                      style: _ms(
                        size: 13,
                        weight: FontWeight.bold,
                        color: _isOpen ? _selGreen : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _isOpen
                          ? 'Pembeli dapat melihat & memesan produkmu'
                          : 'Produkmu disembunyikan sementara dari pembeli',
                      style: _ms(size: 10, color: Colors.black38),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _toggleStoreOpenStatus,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 52,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _isOpen ? _selGreen : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [if (_isOpen) BoxShadow(color: _selGreen.withValues(alpha: 0.35), blurRadius: 8)],
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        left: _isOpen ? 26 : 2,
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
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStoreOpenStatus() async {
    if (_storeId == null) return;
    HapticFeedback.selectionClick();
    final newStatus = !_isOpen;
    try {
      await StoreService.setStoreOpenStatus(_storeId!, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            newStatus ? 'Toko berhasil DIBUKA ✓' : 'Toko berhasil DITUTUP sementara',
            style: _ms(size: 12, color: Colors.white),
          ),
          backgroundColor: newStatus ? _selGreen : Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengubah status toko: $e', style: _ms(size: 12, color: Colors.white)),
          backgroundColor: Colors.red.shade600,
        ));
      }
    }
  }

  // ──────────────────────────────────────────
  //  2. PESANAN MASUK (PENDING ORDERS)
  //  Real-time dari Firestore collection 'orders'
  //  Filter: store_id / seller_id / owner_id == _storeId / uid & status == 'pending'
  // ──────────────────────────────────────────
  Widget _buildOrderAlertSection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_storeId == null && uid == null) return const SizedBox.shrink();

    final queryStoreId = _storeId ?? uid ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Pesanan Menunggu Konfirmasi (Pending) ──
        _buildPendingOrdersStream(queryStoreId, uid),
        const SizedBox(height: 12),
        // ── Pesanan Sedang Diproses (Accepted) ──
        _buildAcceptedOrdersStream(queryStoreId, uid),
      ],
    );
  }

  Widget _buildPendingOrdersStream(String storeId, String? uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: OrdersManager.instance.pendingOrdersForStoreStream(
        storeId,
        sellerUid: uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyOrderState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Pesanan Masuk
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
                Text(
                  'Pesanan Masuk',
                  style: _ms(size: 14, weight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${docs.length}',
                    style: _ms(size: 10, weight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) => _buildPendingOrderCard(doc)),
          ],
        );
      },
    );
  }

  Widget _buildAcceptedOrdersStream(String storeId, String? uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: OrdersManager.instance.processingOrdersForStoreStream(
        storeId,
        sellerUid: uid,
      ),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sedang Diproses',
                  style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...docs.map((doc) => _buildAcceptedOrderCard(doc)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyOrderState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum ada pesanan masuk',
                  style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pesanan dari pembeli akan muncul di sini secara real-time',
                  style: _ms(size: 11, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrderCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final orderId = (data['orderCode'] as String?) ?? doc.id;
    final buyerId = (data['buyerId'] as String?) ?? (data['buyer_id'] as String?) ?? '';
    final buyerName = (data['buyer_name'] as String?) ??
        (data['buyerName'] as String?) ?? 'Pembeli';
    final alamatPengiriman = (data['alamatPengiriman'] as String?) ?? (data['address'] as String?) ?? '';
    final itemsSummary = (data['itemsSummary'] as String?) ?? '';
    final totalPrice = (data['total_price'] as num?)?.toInt() ??
        (data['totalPrice'] as num?)?.toInt() ?? 0;
    final catatan = (data['catatan'] as String?) ?? '';
    final itemsList = (data['items'] as List<dynamic>?) ?? [];
    final createdAt = data['created_at'] ?? data['createdAt'];

    String timeLabel = 'Baru saja';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) {
        timeLabel = 'Baru saja';
      } else if (diff.inHours < 1) {
        timeLabel = '${diff.inMinutes} mnt lalu';
      } else {
        timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _selAmber.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _selAmber.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header order card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _selAmber.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _selAmber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, size: 14, color: _selAmber),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    orderId,
                    style: _ms(size: 12, weight: FontWeight.bold, color: _selAmber),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _selAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _selAmber.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '⏳ Menunggu Konfirmasi',
                    style: _ms(size: 9, weight: FontWeight.bold, color: _selAmber),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pembeli & waktu
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 14, color: Colors.black38),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        buyerName,
                        style: _ms(size: 12, weight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.schedule_rounded, size: 12, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(timeLabel, style: _ms(size: 10, color: Colors.black38)),
                  ],
                ),
                const SizedBox(height: 8),

                // Rincian item
                if (itemsList.isNotEmpty) ...[
                  ...itemsList.take(3).map((item) {
                    final m = item as Map<String, dynamic>;
                    final nama = (m['product_name'] as String?) ?? (m['nama'] as String?) ?? '-';
                    final qty = (m['quantity'] as num?)?.toInt() ?? (m['qty'] as num?)?.toInt() ?? 0;
                    final harga = (m['price'] as num?)?.toInt() ?? (m['hargaSatuan'] as num?)?.toInt() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(right: 6, top: 2),
                            decoration: BoxDecoration(
                              color: _selGreen.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$nama x$qty',
                              style: _ms(size: 11, color: Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Rp${StoreService.formatRupiah(harga * qty)}',
                            style: _ms(size: 11, weight: FontWeight.w600, color: _selDark),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (itemsList.length > 3)
                    Text(
                      '+${itemsList.length - 3} item lainnya',
                      style: _ms(size: 10, color: Colors.black38),
                    ),
                ] else if (itemsSummary.isNotEmpty)
                  Text(
                    itemsSummary,
                    style: _ms(size: 11, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                // Catatan & Alamat pembeli
                if (alamatPengiriman.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Colors.black45),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          alamatPengiriman,
                          style: _ms(size: 11, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_rounded, size: 13, color: Colors.blue.shade400),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            catatan,
                            style: _ms(size: 11, color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 10),

                // Total harga
                Row(
                  children: [
                    Text('Total Pembayaran', style: _ms(size: 12, color: Colors.black54)),
                    const Spacer(),
                    Text(
                      'Rp${StoreService.formatRupiah(totalPrice)}',
                      style: _ms(size: 15, weight: FontWeight.bold, color: _selGreen),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tombol Accept & Decline
                Row(
                  children: [
                    // Tombol Tolak (Decline)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeclineOrder(
                          doc.id,
                          orderId,
                          buyerId: buyerId,
                          storeName: _storeName,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text('Tolak', style: _ms(size: 12, weight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol Terima (Accept)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptOrder(
                          doc.id,
                          orderId,
                          buyerId: buyerId,
                          storeName: _storeName,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text('Terima Pesanan', style: _ms(size: 12, weight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
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

  Widget _buildAcceptedOrderCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final orderId = (data['orderCode'] as String?) ?? doc.id;
    final buyerName = (data['buyer_name'] as String?) ?? (data['buyerName'] as String?) ?? 'Pembeli';
    final itemsSummary = (data['itemsSummary'] as String?) ?? '';
    final totalPrice = (data['total_price'] as num?)?.toInt() ??
        (data['totalPrice'] as num?)?.toInt() ?? 0;
    final status = data['status'] as String? ?? kStatusAccepted;

    Color badgeColor;
    String badgeLabel;
    if (status == kStatusDikemas) {
      badgeColor = _selAmber;
      badgeLabel = '📦 Dikemas';
    } else {
      badgeColor = _selGreen;
      badgeLabel = '✅ Diterima';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderId, style: _ms(size: 12, weight: FontWeight.bold, color: badgeColor)),
                const SizedBox(height: 2),
                Text(buyerName, style: _ms(size: 11, color: Colors.black54)),
                if (itemsSummary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    itemsSummary,
                    style: _ms(size: 10.5, color: Colors.black38),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badgeLabel, style: _ms(size: 9, weight: FontWeight.bold, color: badgeColor)),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp${StoreService.formatRupiah(totalPrice)}',
                style: _ms(size: 13, weight: FontWeight.bold, color: _selGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(
    String docId,
    String orderId, {
    String? buyerId,
    String? storeName,
  }) async {
    HapticFeedback.mediumImpact();
    try {
      await OrdersManager.instance.acceptOrder(
        docId,
        buyerId: buyerId,
        storeName: storeName ?? _storeName,
        orderCode: orderId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan $orderId berhasil diterima & diproses ✓', style: _ms(size: 12, color: Colors.white)),
          backgroundColor: _selGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menerima pesanan: $e', style: _ms(size: 12, color: Colors.white)),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _confirmDeclineOrder(
    String docId,
    String orderId, {
    String? buyerId,
    String? storeName,
  }) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tolak Pesanan?', style: _ms(size: 16, weight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah kamu yakin ingin menolak pesanan $orderId? Pembeli akan mendapat notifikasi bahwa pesanannya ditolak.',
              style: _ms(size: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan (opsional)',
                hintStyle: _ms(size: 12, color: Colors.black38),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: _ms(size: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal', style: _ms(size: 13, color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Ya, Tolak', style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    HapticFeedback.mediumImpact();
    try {
      await OrdersManager.instance.rejectOrder(
        docId,
        buyerId: buyerId,
        storeName: storeName ?? _storeName,
        orderCode: orderId,
        reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan $orderId ditolak.', style: _ms(size: 12, color: Colors.white)),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      // Navigasi ke inbox_screen.dart dengan notifikasi penolakan
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const InboxScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menolak pesanan: $e', style: _ms(size: 12, color: Colors.white)),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _showTrackDriverSheet({
    required LiveLatLng driverLoc,
    required LiveLatLng? destination,
    required String destinationLabel,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Posisi Driver Saat Ini', style: _ms(size: 15, weight: FontWeight.bold)),
            const SizedBox(height: 12),
            LiveTrackingMap(
              from: driverLoc,
              fromLabel: 'Driver',
              to: destination ?? driverLoc,
              toLabel: destinationLabel,
              height: 260,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  //  3. QUICK ACTIONS
  // ──────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.add_box_rounded,
        label: 'Tambah\nProduk',
        color: _selGreen,
        onTap: () => _showAddEditProductDialog(),
      ),
      _QuickAction(
        icon: Icons.inventory_2_rounded,
        label: 'Katalog\nBarang',
        color: const Color(0xFF1565C0),
        onTap: () => _showAllProductsSheet(),
      ),
      _QuickAction(
        icon: Icons.store_rounded,
        label: 'Profil\nGerai',
        color: _selOrange,
        onTap: () => _showEditStoreSheet(),
      ),
      _QuickAction(
        icon: Icons.person_add_rounded,
        label: 'Undang\nDriver',
        color: Colors.deepPurple,
        onTap: () => _showAddDriverDialog(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sellerSectionTitle('Aksi Cepat', 'Kelola tokomu secara praktis'),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.icon, color: a.color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      style: _ms(size: 10, weight: FontWeight.bold, color: _selDark),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  //  4. KATALOG BARANG SAYA — StreamBuilder Firestore
  // ──────────────────────────────────────────
  Widget _buildProductsSection() {
    if (_storeId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: StoreService.myProductsStream(_storeId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sellerSectionTitle('Katalog Barang Saya', 'Memuat daftar dagangan...'),
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
                    'Katalog Barang Saya',
                    '${docs.length} produk aktif di ${widget.userName}',
                  ),
                ),
                // Tombol + Tambah Produk
                GestureDetector(
                  onTap: () => _showAddEditProductDialog(),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _selGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _selGreen.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('Tambah', style: _ms(size: 11, weight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                // Tombol Kelola
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
                        const Icon(Icons.arrow_forward_rounded, size: 13, color: _selGreen),
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
                  mainAxisExtent: 200,
                ),
                itemCount: docs.length > 4 ? 4 : docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildProductGridTile(doc.id, data);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyStoreCard() {
    return GestureDetector(
      onTap: () => _showRegisterStoreSheet(),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
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
            Text('Buka Gerai & Pilih Pasar', style: _ms(size: 16, weight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Daftarkan nama tokomu, pilih pasar tempatmu berjualan, dan mulai tambahkan barang dagangan.',
              style: _ms(size: 12, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_selGreen, Color(0xFF00A852)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _selGreen.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('+ Buka Gerai Sekarang', style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
                ],
              ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            )
          ],
          border: Border.all(color: _selGreen.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Column(
            children: [
              const Text('📦', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text('Belum ada produk dagangan.', style: _ms(size: 13, weight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Ketuk di sini untuk menambahkan produk pertamamu!',
                style: _ms(size: 11, color: Colors.black38),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGridTile(String docId, Map<String, dynamic> data) {
    final name = data['product_name'] as String? ?? 'Produk';
    final icon = data['category'] as String? ?? '🛒';
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final imageUrl = (data['image_url'] as String?) ?? (data['imageUrl'] as String?) ?? '';

    return GestureDetector(
      onTap: () => _showAddEditProductDialog(existingId: docId, existingData: data),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 86,
                  decoration: BoxDecoration(
                    color: _selGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageUrl.trim().isEmpty
                        ? Center(child: Text(icon, style: const TextStyle(fontSize: 38)))
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, _, _) => Center(child: Text(icon, style: const TextStyle(fontSize: 38))),
                          ),
                  ),
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
            const SizedBox(height: 2),
            Text(
              data['market_type'] as String? ?? _marketType,
              style: _ms(size: 9.5, color: Colors.black38),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    StoreService.formatRupiah(price),
                    style: _ms(size: 13, weight: FontWeight.bold, color: _selGreen),
                  ),
                ),
                Icon(Icons.edit_rounded, size: 14, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  //  MODAL: PROFIL GERAI SAYA (BUKA GERAI / REGISTRASI)
  // ──────────────────────────────────────────
  void _showRegisterStoreSheet() {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController(text: _storeData?['store_name'] ?? '');
    final descCtrl = TextEditingController(text: _storeData?['description'] ?? '');
    String selectedPasar = _pasarOptions.contains(_marketType) ? _marketType : _pasarOptions.first;
    bool storeIsOpen = _isOpen;
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
                        width: 40,
                        height: 4,
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
                                  Text('Profil Gerai Saya', style: _ms(size: 17, weight: FontWeight.bold)),
                                  Text('Lengkapi info tokomu untuk mulai berjualan', style: _ms(size: 11, color: Colors.black45)),
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
                              // store_name (Nama Gerai/Toko)
                              TextFormField(
                                controller: nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Nama Gerai / Toko *',
                                  labelStyle: _ms(size: 13, color: Colors.black54),
                                  hintText: 'contoh: Gerai Sayur Bu Eko',
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

                              // market_type (Pilihan Pasar)
                              DropdownButtonFormField<String>(
                                initialValue: selectedPasar,
                                decoration: InputDecoration(
                                  labelText: 'Pilihan Pasar *',
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

                              // is_open (Status Buka/Tutup)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      storeIsOpen ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                      color: storeIsOpen ? _selGreen : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Status Toko', style: _ms(size: 12, weight: FontWeight.bold)),
                                          Text(
                                            storeIsOpen ? 'Buka (dapat menerima pesanan)' : 'Tutup (sembunyikan produk)',
                                            style: _ms(size: 10, color: Colors.black45),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: storeIsOpen,
                                      activeThumbColor: _selGreen,
                                      onChanged: (val) => setModal(() => storeIsOpen = val),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // description (Deskripsi Toko)
                              TextFormField(
                                controller: descCtrl,
                                maxLines: 2,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  labelText: 'Deskripsi Toko (opsional)',
                                  labelStyle: _ms(size: 13, color: Colors.black54),
                                  hintText: 'Menjual aneka sayuran segar...',
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

                  // Tombol Simpan Toko
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
                                  final storeId = await StoreService.createStore(
                                    ownerUid: uid,
                                    storeName: nameCtrl.text.trim(),
                                    marketType: selectedPasar,
                                    isOpen: storeIsOpen,
                                    description: descCtrl.text.trim(),
                                  );

                                  if (mounted) {
                                    setState(() {
                                      _storeId = storeId;
                                      _storeData = {
                                        'store_name': nameCtrl.text.trim(),
                                        'market_type': selectedPasar,
                                        'is_open': storeIsOpen,
                                        'description': descCtrl.text.trim(),
                                        'owner_id': uid,
                                      };
                                    });
                                  }

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Row(children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Gerai berhasil didaftarkan! 🎉', style: _ms(size: 12, color: Colors.white)),
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
                                    content: Text('Gagal mendaftarkan gerai: $e', style: _ms(size: 12, color: Colors.white)),
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
                            : Text('Buka Gerai Sekarang', style: _ms(size: 14, weight: FontWeight.bold, color: Colors.white)),
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
  //  MODAL: EDIT PROFIL GERAI SAYA
  // ──────────────────────────────────────────
  void _showEditStoreSheet() {
    if (_storeId == null) {
      _showRegisterStoreSheet();
      return;
    }
    HapticFeedback.selectionClick();
    final nameCtrl = TextEditingController(text: _storeName);
    final descCtrl = TextEditingController(text: _storeDescription);
    String selectedPasar = _pasarOptions.contains(_marketType) ? _marketType : _pasarOptions.first;
    bool storeIsOpen = _isOpen;
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
                        width: 40,
                        height: 4,
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
                                Text('Profil Gerai Saya', style: _ms(size: 17, weight: FontWeight.bold)),
                                Text('Perbarui nama gerai, pasar, atau status', style: _ms(size: 11, color: Colors.black45)),
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
                                  labelText: 'Nama Gerai / Toko *',
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

                              DropdownButtonFormField<String>(
                                initialValue: selectedPasar,
                                decoration: InputDecoration(
                                  labelText: 'Pilihan Pasar *',
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

                              // Toggle Status Buka / Tutup
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      storeIsOpen ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                      color: storeIsOpen ? _selGreen : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Status Toko', style: _ms(size: 12, weight: FontWeight.bold)),
                                          Text(
                                            storeIsOpen ? 'Buka (Aktif menerima pesanan)' : 'Tutup (Sembunyikan produk)',
                                            style: _ms(size: 10, color: Colors.black45),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: storeIsOpen,
                                      activeThumbColor: _selGreen,
                                      onChanged: (val) => setModal(() => storeIsOpen = val),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: descCtrl,
                                maxLines: 2,
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
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModal(() => isLoading = true);

                                try {
                                  await StoreService.updateStore(
                                    _storeId!,
                                    storeName: nameCtrl.text.trim(),
                                    marketType: selectedPasar,
                                    description: descCtrl.text.trim(),
                                    isOpen: storeIsOpen,
                                  );

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Row(children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Profil gerai berhasil diperbarui!', style: _ms(size: 12, color: Colors.white)),
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
  //  MODAL: TAMBAH / EDIT PRODUK (Firestore collection 'products')
  // ──────────────────────────────────────────
  void _showAddEditProductDialog({String? existingId, Map<String, dynamic>? existingData}) {
    if (_storeId == null) {
      _showRegisterStoreSheet();
      return;
    }

    final isEdit = existingId != null;
    final nameCtrl = TextEditingController(text: existingData?['product_name'] ?? '');
    final catCtrl = TextEditingController(text: existingData?['category'] ?? '🥬');
    final priceCtrl = TextEditingController(text: existingData != null ? existingData['price'].toString() : '');
    final stockCtrl = TextEditingController(text: existingData != null ? existingData['stock'].toString() : '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEdit ? Icons.edit_note_rounded : Icons.add_box_rounded,
                  color: _selGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isEdit ? 'Edit Produk' : 'Tambah Produk Dagangan',
                style: _ms(size: 16, weight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: TextFormField(
                          controller: catCtrl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22),
                          decoration: InputDecoration(
                            labelText: 'Ikon',
                            labelStyle: _ms(size: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            hintText: 'mis. Sayur Segar',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            hintText: '15000',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            hintText: '10',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (v) => (int.tryParse(v ?? '') == null) ? 'Harus angka' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Info pasar otomatis
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Colors.black45),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pasar: $_marketType (otomatis terhubung)',
                            style: _ms(size: 10.5, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
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
                        final emojiVal = catCtrl.text.trim().isEmpty ? '🛒' : catCtrl.text.trim();

                        if (isEdit) {
                          await StoreService.updateProduct(
                            existingId,
                            productName: nameCtrl.text.trim(),
                            price: int.parse(priceCtrl.text.trim()),
                            stock: int.parse(stockCtrl.text.trim()),
                            category: emojiVal,
                            marketType: _marketType,
                          );
                        } else {
                          await StoreService.addProduct(
                            storeId: _storeId!,
                            ownerUid: uid,
                            marketType: _marketType,
                            productName: nameCtrl.text.trim(),
                            price: int.parse(priceCtrl.text.trim()),
                            stock: int.parse(stockCtrl.text.trim()),
                            category: emojiVal,
                          );
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            isEdit ? 'Produk berhasil diperbarui ✓' : 'Produk berhasil ditambahkan ke katalog ✓',
                            style: _ms(size: 12, color: Colors.white),
                          ),
                          backgroundColor: _selGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ));
                      } catch (e) {
                        setDialog(() => isLoading = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Gagal menyimpan produk: $e', style: _ms(size: 12, color: Colors.white)),
                          backgroundColor: Colors.red.shade600,
                        ));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
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

  // ──────────────────────────────────────────
  //  BOTTOM SHEET: KELOLA SEMUA PRODUK (Firestore)
  // ──────────────────────────────────────────
  void _showAllProductsSheet() {
    if (_storeId == null) {
      _showRegisterStoreSheet();
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
                              Text('Kelola Produk Dagangan', style: _ms(size: 17, weight: FontWeight.bold)),
                              Text('Semua produk aktif di $_marketType', style: _ms(size: 11, color: Colors.black45)),
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
                                  const Text('📦', style: TextStyle(fontSize: 48)),
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
    final imageUrl = (data['image_url'] as String?) ?? (data['imageUrl'] as String?) ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
              child: imageUrl.trim().isEmpty
                  ? Center(child: Text(icon, style: const TextStyle(fontSize: 22)))
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, _, _) => Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: _ms(size: 13, weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Stok: $stock • Pasar: ${data['market_type'] ?? _marketType}', style: _ms(size: 10, color: Colors.black38)),
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

  void _confirmDeleteProduct(String docId, String name) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Produk?', style: _ms(size: 16, weight: FontWeight.bold)),
        content: Text('$name akan dihapus secara permanen dari katalog tokomu.', style: _ms(size: 13, color: Colors.black54)),
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
  //  5. DRIVER SECTION
  // ──────────────────────────────────────────
  Widget _buildAddDriverSection() {
    return GestureDetector(
      onTap: _showAddDriverDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
          ],
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
                      const Icon(Icons.add_circle_rounded, color: _selGreen, size: 20),
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
                              backgroundImage: d.photoUrl != null ? NetworkImage(d.photoUrl!) : null,
                              child: d.photoUrl == null
                                  ? Text(
                                      d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                                      style: _ms(size: 12, weight: FontWeight.bold, color: _selGreen),
                                    )
                                  : null,
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
      builder: (ctx) => _AddDriverSheet(storeName: _storeName),
    );
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
}

// ─────────────────────────────────────────────
//  Model Classes (internal)
// ─────────────────────────────────────────────
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _SellerDriver {
  final String name, email;
  final String? photoUrl;
  const _SellerDriver({required this.name, required this.email, this.photoUrl});
}

// ─────────────────────────────────────────────
//  _AddDriverSheet — cari user A-Z, kirim undangan jadi driver
// ─────────────────────────────────────────────
class _AddDriverSheet extends StatefulWidget {
  final String storeName;
  const _AddDriverSheet({required this.storeName});

  @override
  State<_AddDriverSheet> createState() => _AddDriverSheetState();
}

class _AddDriverSheetState extends State<_AddDriverSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _results = [];
  bool _loading = true;
  final Set<String> _invitedThisSession = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadUsers(query: _searchCtrl.text),
    );
  }

  Future<void> _loadUsers({String? query}) async {
    setState(() => _loading = true);
    try {
      final results = await DriverService.fetchUsersAZ(searchQuery: query);
      if (mounted) setState(() { _results = results; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmInvite(QueryDocumentSnapshot<Map<String, dynamic>> user) async {
    final name = (user.data()['name'] as String?) ?? 'Pengguna';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tambahkan Driver?', style: _ms(size: 16, weight: FontWeight.bold)),
        content: Text(
          'Ingin menambahkan akun ini sebagai driver?\n\n$name',
          style: _ms(size: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: _ms(size: 13, color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Ya, Tambahkan', style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DriverService.sendDriverInvite(targetUid: user.id, storeName: widget.storeName);
      if (!mounted) return;
      setState(() => _invitedThisSession.add(user.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Undangan terkirim ke $name', style: _ms(size: 12, color: Colors.white)),
        backgroundColor: _selGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e', style: _ms(size: 12, color: Colors.white)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
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
                    Text('Cari akun berdasarkan nama atau email untuk diundang jadi driver',
                        style: _ms(size: 11, color: Colors.black45)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nama atau email...',
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
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: _selGreen))
                    : _results.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(Icons.person_search_rounded, size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 10),
                                  Text('Tidak ada akun yang cocok', style: _ms(size: 11, color: Colors.black38)),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _results.length,
                            itemBuilder: (context, i) {
                              final doc = _results[i];
                              final data = doc.data();
                              final name = (data['name'] as String?) ?? 'Pengguna';
                              final email = (data['email'] as String?) ?? '-';
                              final alreadyInvited = _invitedThisSession.contains(doc.id);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: _selGreen.withValues(alpha: 0.12),
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: _ms(size: 13, weight: FontWeight.bold, color: _selGreen),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: _ms(size: 13, weight: FontWeight.w600)),
                                          Text(email, style: _ms(size: 10.5, color: Colors.black38)),
                                        ],
                                      ),
                                    ),
                                    alreadyInvited
                                        ? Text('Terkirim', style: _ms(size: 11, weight: FontWeight.bold, color: Colors.black38))
                                        : TextButton(
                                            onPressed: () => _confirmInvite(doc),
                                            style: TextButton.styleFrom(
                                              backgroundColor: _selGreen.withValues(alpha: 0.1),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: Text('Tambahkan', style: _ms(size: 11.5, weight: FontWeight.bold, color: _selGreen)),
                                          ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}