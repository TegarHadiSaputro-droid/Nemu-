import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/auth_service.dart';

// ─────────────────────────────────────────────
//  Warna Palette (konsisten dengan home_screen.dart)
// ─────────────────────────────────────────────
const Color _selYellow  = Color(0xFFD9DF36);
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

  // ── Animasi bar chart ──
  late AnimationController _chartCtrl;
  late Animation<double> _chartAnim;

  // ── Tab aktif pada periode pendapatan (0=Hari Ini, 1=Minggu, 2=Bulan) ──
  int _revenuePeriod = 0;

  // ── Data Gerai dari Firestore (stream) ──
  Map<String, dynamic>? _geraiData;
  StreamSubscription<DocumentSnapshot>? _geraiSub;

  // ── Mock data — akan diganti dengan data real dari backend ──
  final List<int> _salesData = [320000, 480000, 210000, 650000, 890000, 420000, 760000];
  final List<String> _salesDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  // Mock orders yang menunggu konfirmasi
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

  // Mock produk terlaris
  final List<_TopProduct> _topProducts = const [
    _TopProduct(name: 'Cabai Merah', icon: '🌶️', sold: 48, revenue: 2016000, trend: true),
    _TopProduct(name: 'Bawang Merah', icon: '🧅', sold: 36, revenue: 1008000, trend: true),
    _TopProduct(name: 'Tomat Segar', icon: '🍅', sold: 29, revenue: 348000, trend: false),
    _TopProduct(name: 'Daging Ayam', icon: '🍗', sold: 22, revenue: 792000, trend: true),
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

    _chartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _chartAnim = CurvedAnimation(parent: _chartCtrl, curve: Curves.easeOutCubic);
    _chartCtrl.forward();

    _listenGerai();
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

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _chartCtrl.dispose();
    _geraiSub?.cancel();
    super.dispose();
  }

  String get _storeName {
    final name = _geraiData?['namaToko'] as String?;
    return (name != null && name.isNotEmpty) ? name : '${widget.userName}\'s Gerai';
  }

  String get _pasarName => (_geraiData?['namaPasar'] as String?) ?? 'Pasar Tradisional';

  int get _currentRevenue {
    switch (_revenuePeriod) {
      case 0: return 760000;
      case 1: return 4730000;
      case 2: return 18200000;
      default: return 760000;
    }
  }

  int get _prevRevenue {
    switch (_revenuePeriod) {
      case 0: return 680000;
      case 1: return 4100000;
      case 2: return 15800000;
      default: return 680000;
    }
  }

  @override
  Widget build(BuildContext context) {
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

              // 3. Metrics Cards
              _buildMetricsSection(),
              const SizedBox(height: 20),

              // 4. Grafik Penjualan Mini
              _buildSalesTrendSection(),
              const SizedBox(height: 20),

              // 5. Quick Action Grid
              _buildQuickActions(),
              const SizedBox(height: 20),

              // 6. Produk Terlaris
              _buildTopProductsSection(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    _chartCtrl.reset();
    _chartCtrl.forward();
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pesanan $orderId diserahkan ke kurir!', style: _ms(size: 12, color: Colors.white)),
                                backgroundColor: _selGreen,
                              ),
                            );
                          }
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pesanan $orderId telah diselesaikan!', style: _ms(size: 12, color: Colors.white)),
                                backgroundColor: _selGreen,
                              ),
                            );
                          }
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
  //  3. METRICS SECTION
  // ──────────────────────────────────────────
  Widget _buildMetricsSection() {
    final revenueChange = _currentRevenue - _prevRevenue;
    final revenueUp = revenueChange >= 0;
    final changePct = (_prevRevenue > 0)
        ? ((revenueChange / _prevRevenue) * 100).abs().toStringAsFixed(1)
        : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sellerSectionTitle('Ringkasan Penjualan', 'Statistik bisnis geraimu'),
        const SizedBox(height: 12),
        Row(
          children: ['Hari Ini', 'Minggu', 'Bulan'].asMap().entries.map((e) {
            final active = e.key == _revenuePeriod;
            return GestureDetector(
              onTap: () => setState(() => _revenuePeriod = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)] : [],
                ),
                child: Text(e.value, style: _ms(size: 11, weight: FontWeight.bold, color: active ? _selGreen : Colors.white)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildRevenueCard(revenueUp, changePct),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMiniMetricCard(
              icon: Icons.inbox_rounded, iconColor: _selOrange,
              label: 'Pesanan\nMenunggu', value: '${_pendingOrders.length}',
              sub: 'pesanan baru', hasBadge: _pendingOrders.isNotEmpty,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildMiniMetricCard(
              icon: Icons.star_rounded, iconColor: _selAmber,
              label: 'Rating\nGerai', value: '4.8', sub: '(134 ulasan)',
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildMiniMetricCard(
              icon: Icons.inventory_2_rounded, iconColor: _selGreen,
              label: 'Produk\nAktif', value: '24', sub: 'item terdaftar',
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueCard(bool revenueUp, String changePct) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: _selGreen.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.monetization_on_rounded, color: _selGreen, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text('Total Pendapatan', style: _ms(size: 12, color: Colors.black45, weight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Rp${_formatRupiah(_currentRevenue)}', style: _ms(size: 26, weight: FontWeight.bold, color: _selDark)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: revenueUp ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            revenueUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            size: 13,
                            color: revenueUp ? _selGreen : Colors.red.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text('$changePct%', style: _ms(size: 10, weight: FontWeight.bold, color: revenueUp ? _selGreen : Colors.red.shade600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('vs periode sebelumnya', style: _ms(size: 10, color: Colors.black38)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_selGreen.withValues(alpha: 0.15), _selYellow.withValues(alpha: 0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('💰', style: TextStyle(fontSize: 30))),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
    bool hasBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              if (hasBadge) ...[
                const Spacer(),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF3B30), shape: BoxShape.circle)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: _ms(size: 22, weight: FontWeight.bold, color: _selDark)),
          const SizedBox(height: 2),
          Text(label, style: _ms(size: 10, color: Colors.black45, height: 1.3)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  4. SALES TREND (BAR CHART)
  // ──────────────────────────────────────────
  Widget _buildSalesTrendSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: _selGreen.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bar_chart_rounded, color: _selGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tren Penjualan', style: _ms(size: 14, weight: FontWeight.bold)),
                  Text('7 hari terakhir', style: _ms(size: 10, color: Colors.black38)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.green.shade500, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('LIVE', style: _ms(size: 9, weight: FontWeight.bold, color: Colors.green.shade700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _chartAnim,
            builder: (context, _) {
              return SizedBox(
                height: 120,
                child: CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: _SellerBarChartPainter(
                    values: _salesData,
                    labels: _salesDays,
                    animationValue: _chartAnim.value,
                    barColor: _selGreen,
                    accentColor: _selYellow,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  5. QUICK ACTIONS
  // ──────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(icon: Icons.add_box_rounded, label: 'Tambah\nProduk', color: _selGreen, onTap: () => _showComingSoon('Tambah Produk')),
      _QuickAction(icon: Icons.tune_rounded, label: 'Kelola\nStok', color: const Color(0xFF1565C0), onTap: () => _showComingSoon('Kelola Stok')),
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
  //  6. PRODUK TERLARIS
  // ──────────────────────────────────────────
  Widget _buildTopProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sellerSectionTitle('Produk Terlaris', 'Item paling laku minggu ini'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: _topProducts.asMap().entries.map((entry) {
              return _buildProductRankTile(entry.key + 1, entry.value, entry.key == _topProducts.length - 1);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductRankTile(int rank, _TopProduct product, bool isLast) {
    const rankColors = [Color(0xFFF5A623), Color(0xFFB0BEC5), Color(0xFFBF8970), Color(0xFF9E9E9E)];
    final rankColor = rank <= rankColors.length ? rankColors[rank - 1] : Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: rankColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: Text('#$rank', style: _ms(size: 10, weight: FontWeight.bold, color: rankColor))),
          ),
          const SizedBox(width: 12),
          Text(product.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: _ms(size: 13, weight: FontWeight.bold)),
                Text('${product.sold} terjual', style: _ms(size: 10, color: Colors.black38)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rp${_formatRupiah(product.revenue)}', style: _ms(size: 12, weight: FontWeight.bold, color: _selGreen)),
              Row(
                children: [
                  Icon(product.trend ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 12, color: product.trend ? _selGreen : Colors.red.shade400),
                  const SizedBox(width: 3),
                  Text(product.trend ? 'Naik' : 'Turun',
                      style: _ms(size: 9, color: product.trend ? _selGreen : Colors.red.shade400, weight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
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
//  CustomPainter — Bar Chart Penjualan
// ─────────────────────────────────────────────
class _SellerBarChartPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  final double animationValue;
  final Color barColor;
  final Color accentColor;

  _SellerBarChartPainter({
    required this.values,
    required this.labels,
    required this.animationValue,
    required this.barColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce(math.max).toDouble();
    final range = maxVal == 0 ? 1.0 : maxVal;

    const labelHeight = 18.0;
    const barAreaHeight = 90.0;
    const barSpacing = 8.0;
    final barWidth = (size.width - barSpacing * (values.length - 1)) / values.length;
    final todayIndex = values.length - 1;

    for (int i = 0; i < values.length; i++) {
      final x = i * (barWidth + barSpacing);
      final normalizedHeight = values[i] / range;
      final barHeight = normalizedHeight * barAreaHeight * animationValue;
      final barTop = barAreaHeight - barHeight;
      final isToday = i == todayIndex;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barTop, barWidth, barHeight),
        const Radius.circular(6),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isToday
              ? [accentColor, barColor]
              : [barColor.withValues(alpha: 0.7), barColor.withValues(alpha: 0.4)],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 9,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? barColor : Colors.grey.shade400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth);

      textPainter.paint(canvas, Offset(x + (barWidth - textPainter.width) / 2, barAreaHeight + 4));

      if (isToday && barHeight > 12) {
        final valPainter = TextPainter(
          text: TextSpan(
            text: 'Rp${(values[i] / 1000).toStringAsFixed(0)}rb',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: barColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: barWidth + 20);

        valPainter.paint(canvas, Offset(x + (barWidth - valPainter.width) / 2, barTop - 14));
      }
    }
    // Suppress unused variable warning
    labelHeight.toString();
  }

  @override
  bool shouldRepaint(covariant _SellerBarChartPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue || oldDelegate.values != values;
}

// ─────────────────────────────────────────────
//  Model Classes
// ─────────────────────────────────────────────
class _SellerOrder {
  final String id, buyerName, items, eta;
  final int total;
  _SellerOrder({required this.id, required this.buyerName, required this.items, required this.total, required this.eta});
}

class _TopProduct {
  final String name, icon;
  final int sold, revenue;
  final bool trend;
  const _TopProduct({required this.name, required this.icon, required this.sold, required this.revenue, required this.trend});
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}
