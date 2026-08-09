import 'dart:async';
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

  // ── Produk yang dijual — akan diganti dengan data real dari backend ──
  final List<_SellerProduct> _products = [
    const _SellerProduct(name: 'Cabai Merah', icon: '🌶️', unit: 'per kg', price: 42000, stock: 18),
    const _SellerProduct(name: 'Bawang Merah', icon: '🧅', unit: 'per kg', price: 28000, stock: 25),
    const _SellerProduct(name: 'Tomat Segar', icon: '🍅', unit: 'per kg', price: 12000, stock: 30),
    const _SellerProduct(name: 'Daging Ayam', icon: '🍗', unit: 'per kg', price: 36000, stock: 12),
    const _SellerProduct(name: 'Wortel', icon: '🥕', unit: 'per kg', price: 10000, stock: 20),
  ];

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
    _geraiSub?.cancel();
    super.dispose();
  }

  String get _storeName {
    final name = _geraiData?['namaToko'] as String?;
    return (name != null && name.isNotEmpty) ? name : '${widget.userName}\'s Gerai';
  }

  String get _pasarName => (_geraiData?['namaPasar'] as String?) ?? 'Pasar Tradisional';

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

              // 3. Produk yang Dijual (menggantikan Ringkasan Penjualan)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text('Pesanan Baru Masuk', style: _ms(size: 14, weight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.shade500, borderRadius: BorderRadius.circular(20)),
              child: Text('${_pendingOrders.length}', style: _ms(size: 10, weight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._pendingOrders.map((order) => _buildOrderCard(order)),
      ],
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
  //  3. PRODUK YANG DIJUAL (menggantikan Ringkasan Penjualan)
  // ──────────────────────────────────────────
  Widget _buildProductsSection() {
    final preview = _products.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _sellerSectionTitle('Produk Dijual', '${_products.length} produk aktif di geraimu'),
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
        if (preview.isEmpty)
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
                child: Center(child: Text(product.icon, style: const TextStyle(fontSize: 42))),
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
  //  3c. HALAMAN KELOLA SEMUA PRODUK
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
            return StatefulBuilder(
              builder: (context, setSheetState) {
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
                                  Text('${_products.length} produk terdaftar', style: _ms(size: 11, color: Colors.black45)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showAddEditProductDialog(onDone: () => setSheetState(() {})),
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
                        child: _products.isEmpty
                            ? Center(
                                child: Text('Belum ada produk.', style: _ms(size: 12, color: Colors.black38)),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                itemCount: _products.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final product = _products[index];
                                  return _buildManageProductTile(product, onChanged: () => setSheetState(() {}));
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
      },
    );
  }

  Widget _buildManageProductTile(_SellerProduct product, {required VoidCallback onChanged}) {
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
            child: Center(child: Text(product.icon, style: const TextStyle(fontSize: 22))),
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
            onTap: () => _showAddEditProductDialog(existing: product, onDone: onChanged),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.edit_rounded, size: 16, color: Colors.blue.shade600),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _confirmDeleteProduct(product, onChanged: onChanged),
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
  //  3d. TAMBAH / EDIT PRODUK (fungsional, data lokal)
  // ──────────────────────────────────────────
  void _showAddEditProductDialog({_SellerProduct? existing, VoidCallback? onDone}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final iconCtrl = TextEditingController(text: existing?.icon ?? '🛒');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'per kg');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toString() : '');
    final stockCtrl = TextEditingController(text: existing != null ? existing.stock.toString() : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                        decoration: InputDecoration(
                          labelText: 'Emoji',
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
                        decoration: InputDecoration(
                          labelText: 'Nama Produk',
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
                TextFormField(
                  controller: unitCtrl,
                  decoration: InputDecoration(
                    labelText: 'Satuan (contoh: per kg)',
                    labelStyle: _ms(size: 12),
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
                          labelText: 'Stok',
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
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              final newProduct = _SellerProduct(
                name: nameCtrl.text.trim(),
                icon: iconCtrl.text.trim().isEmpty ? '🛒' : iconCtrl.text.trim(),
                unit: unitCtrl.text.trim(),
                price: int.parse(priceCtrl.text.trim()),
                stock: int.parse(stockCtrl.text.trim()),
              );

              setState(() {
                if (isEdit) {
                  final idx = _products.indexOf(existing!);
                  if (idx != -1) _products[idx] = newProduct;
                } else {
                  _products.add(newProduct);
                }
              });

              Navigator.pop(ctx);
              onDone?.call();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isEdit ? 'Produk diperbarui' : 'Produk ditambahkan', style: _ms(size: 12, color: Colors.white)),
                backgroundColor: _selGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isEdit ? 'Simpan' : 'Tambahkan', style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(_SellerProduct product, {required VoidCallback onChanged}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Produk?', style: _ms(size: 16, weight: FontWeight.bold)),
        content: Text('${product.name} akan dihapus dari daftar produkmu.', style: _ms(size: 13, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: _ms(size: 13, color: Colors.black54))),
          ElevatedButton(
            onPressed: () {
              setState(() => _products.remove(product));
              Navigator.pop(ctx);
              onChanged();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${product.name} dihapus', style: _ms(size: 12, color: Colors.white)),
                backgroundColor: Colors.red.shade500,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ));
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
class _SellerOrder {
  final String id, buyerName, items, eta;
  final int total;
  _SellerOrder({required this.id, required this.buyerName, required this.items, required this.total, required this.eta});
}

class _SellerProduct {
  final String name, icon, unit;
  final int price, stock;
  const _SellerProduct({required this.name, required this.icon, required this.unit, required this.price, required this.stock});
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