import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/driver_service.dart'; // sesuaikan path kalau struktur foldermu beda
import 'package:frontend/services/order_tracking_service.dart';
import 'package:frontend/services/store_service.dart';
import 'package:frontend/widgets/live_tracking_map.dart';

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

  // ── State gerai (dari Firestore subcollection 'seller/{uid}') ──
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _geraiSub;
  Map<String, dynamic>? _geraiData;
  // _storeId adalah UID seller itu sendiri (dokumen 'seller/{uid}')
  String? _storeId;

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

  // ── Produk yang dijual — akan diganti dengan data real dari backend ──
  final List<_SellerProduct> _products = [
    const _SellerProduct(name: 'Cabai Merah', icon: '🌶️', unit: 'per kg', price: 42000, stock: 18),
    const _SellerProduct(name: 'Bawang Merah', icon: '🧅', unit: 'per kg', price: 28000, stock: 25),
    const _SellerProduct(name: 'Tomat Segar', icon: '🍅', unit: 'per kg', price: 12000, stock: 30),
    const _SellerProduct(name: 'Daging Ayam', icon: '🍗', unit: 'per kg', price: 36000, stock: 12),
    const _SellerProduct(name: 'Wortel', icon: '🥕', unit: 'per kg', price: 10000, stock: 20),
  ];

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

    _listenGerai();
    _listenAssignedDrivers();
  }

  void _listenGerai() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _storeId = uid; // dokumen seller/{uid} — storeId == uid seller
    _geraiSub = FirebaseFirestore.instance
        .collection('seller')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (mounted) {
        setState(() => _geraiData = snap.data());
      }
    }, onError: (e) {
      debugPrint('Gagal memuat data gerai: $e');
    });
  }

  // Undangan driver yang di-accept nggak nyimpen relasi seller<->driver
  // di collection terpisah — cuma nyimpen 'fromUid' (uid seller) di dalam
  // dokumen inbox si driver (users/{driverUid}/inbox/{inviteId}). Jadi
  // buat nampilin "driver-driver gerai ini", kita collectionGroup query
  // ke semua subcollection 'inbox' lintas user, saring type + status +
  // fromUid == uid seller yang sedang login.
  //
  // CATATAN: pertama kali dijalankan, Firestore kemungkinan bakal
  // nge-throw error "failed-precondition" berisi LINK ke Firebase Console
  // buat bikin composite index otomatis (soalnya ini collection group
  // query dengan beberapa filter kesetaraan sekaligus). Tinggal klik
  // link error-nya sekali, index-nya dibuatin otomatis dalam beberapa
  // menit, abis itu query ini jalan normal.
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
        // Path dokumen inbox: users/{driverUid}/inbox/{inviteId}.
        // parent.parent adalah dokumen users/{driverUid} itu sendiri.
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
    _geraiSub?.cancel();
    _driversSub?.cancel();
    super.dispose();
  }

  // ── Getters nama & pasar dari Firestore ──
  String get _storeName {
    final name = _geraiData?['store_name'] as String?;
    return (name != null && name.isNotEmpty) ? name : '${widget.userName}\'s Gerai';
  }

  String get _pasarName =>
      (_geraiData?['market_section'] as String?) ?? 'Pasar Tradisional';

  String get _storeDescription =>
      (_geraiData?['description'] as String?) ?? '';

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

              // 2. Alert Pesanan Baru (real-time dari Firestore)
              _buildOrderAlertSection(),
              const SizedBox(height: 20),

              // 3. Katalog Produk (Firestore real-time)
              _buildProductsSection(),
              const SizedBox(height: 32),

              // 3b. Placeholder Tambah Driver
              _buildAddDriverSection(),
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('simulated_orders')
          .where('status', whereIn: [
            OrderStatus.dikemas,
            OrderStatus.menungguDriver,
            OrderStatus.menujuPenjual,
            OrderStatus.diantar,
          ])
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
    final status = (data['status'] as String?) ?? OrderStatus.dikemas;
    final isPackaging = status == OrderStatus.dikemas;
    final driverName = data['driverName'] as String?;
    final driverLoc = LiveLatLng.fromMap(data['driverLocation'] as Map<String, dynamic>?);
    final sellerLoc = LiveLatLng.fromMap(data['sellerLocation'] as Map<String, dynamic>?);

    const badgeColors = {
      OrderStatus.dikemas: _selAmber,
      OrderStatus.menungguDriver: _selOrange,
      OrderStatus.menujuPenjual: Colors.blue,
      OrderStatus.diantar: _selGreen,
    };
    final badgeColor = badgeColors[status] ?? _selAmber;
    const badgeLabels = {
      OrderStatus.dikemas: '⏳ Sedang Dikemas',
      OrderStatus.menungguDriver: '📡 Mencari Driver',
      OrderStatus.menujuPenjual: '🛵 Driver Menuju Toko',
      OrderStatus.diantar: '🚚 Diantar ke Pembeli',
    };
    final badgeLabel = badgeLabels[status] ?? '⏳ Sedang Dikemas';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.12),
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
              color: badgeColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.receipt_long_rounded, size: 14, color: badgeColor),
                ),
                const SizedBox(width: 8),
                Text(orderId, style: _ms(size: 12, weight: FontWeight.bold, color: badgeColor)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeLabel,
                    style: _ms(
                      size: 9,
                      weight: FontWeight.bold,
                      color: badgeColor,
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
                          await OrderTrackingService.markReadyForDriver(
                            orderDocId: doc.id,
                            storeName: _storeName,
                            marketName: _pasarName,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pesanan $orderId dilepas ke driver, menunggu ada yang menerima...', style: _ms(size: 12, color: Colors.white)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Selesai Mengemas / Serahkan ke Kurir', style: _ms(size: 11, weight: FontWeight.bold, color: Colors.white)),
                      )
                    else if (status == OrderStatus.menungguDriver)
                      Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _selOrange),
                          ),
                          const SizedBox(width: 8),
                          Text('Menunggu driver menerima...', style: _ms(size: 11, weight: FontWeight.w600, color: _selOrange)),
                        ],
                      )
                    else ...[
                      // Driver sudah pegang order ini (menuju_penjual / diantar) --
                      // Penjual cuma memantau dari sini, bukan mengontrol lagi.
                      if (driverName != null)
                        Expanded(
                          child: Text(
                            'Driver: $driverName',
                            style: _ms(size: 11, weight: FontWeight.w600, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (driverLoc != null)
                        OutlinedButton.icon(
                          onPressed: () => _showTrackDriverSheet(
                            driverLoc: driverLoc,
                            destination: sellerLoc,
                            destinationLabel: 'Toko Kamu',
                          ),
                          icon: const Icon(Icons.map_rounded, size: 15),
                          label: Text('Lacak Driver', style: _ms(size: 11, weight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _selGreen,
                            side: BorderSide(color: _selGreen.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  void _handleAcceptOrder(_SellerOrder order) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Pesanan ${order.id} diterima!', style: _ms(size: 12, color: Colors.white)),
      backgroundColor: _selGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            onPressed: () => Navigator.pop(ctx),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ((data['image_url'] as String?) ?? (data['imageUrl'] as String?) ?? '').trim().isEmpty
                      ? Center(child: Text(icon, style: const TextStyle(fontSize: 42)))
                      : Image.network(
                          (data['image_url'] as String?) ?? (data['imageUrl'] as String?) ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Center(child: Text(icon, style: const TextStyle(fontSize: 42))),
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
    final name = data['product_name'] as String? ?? data['name'] as String? ?? 'Produk';
    final icon = data['category'] as String? ?? '🛒';
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final imageUrl = (data['image_url'] as String?) ?? (data['imageUrl'] as String?) ?? '';
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
              child: imageUrl.trim().isEmpty
                  ? Center(child: Text(icon, style: const TextStyle(fontSize: 22)))
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
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
                              backgroundImage:
                                  d.photoUrl != null ? NetworkImage(d.photoUrl!) : null,
                              child: d.photoUrl == null
                                  ? Text(d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                                      style: _ms(size: 12, weight: FontWeight.bold, color: _selGreen))
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

class _SellerOrder {
  final String id, buyerName, items, eta;
  final int total;
  _SellerOrder({required this.id, required this.buyerName, required this.items, required this.total, required this.eta});
}

class _SellerDriver {
  final String name, email;
  final String? photoUrl;
  const _SellerDriver({required this.name, required this.email, this.photoUrl});
}

class _SellerProduct {
  final String name, icon, unit;
  final int price, stock;
  const _SellerProduct({required this.name, required this.icon, required this.unit, required this.price, required this.stock});
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

// ─────────────────────────────────────────────
//  Data class untuk produk Firestore (beda dari _SellerProduct lokal)
// ─────────────────────────────────────────────
class _FirestoreProduct {
  final String? id;
  final String name, imageUrl, unit;
  final int price, stock;
  const _FirestoreProduct({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.unit,
    required this.price,
    required this.stock,
  });

  factory _FirestoreProduct.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return _FirestoreProduct(
      id: doc.id,
      name: (d['name'] as String?) ?? (d['product_name'] as String?) ?? '',
      imageUrl: (d['imageUrl'] as String?) ?? (d['image_url'] as String?) ?? '',
      unit: (d['unit'] as String?) ?? 'kg',
      price: (d['price'] as num?)?.toInt() ?? 0,
      stock: (d['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'product_name': name,
        'image_url': imageUrl,
        'unit': unit,
        'price': price,
        'stock': stock,
      };
}

// ─────────────────────────────────────────────
//  Dialog Tambah/Edit Produk
// ─────────────────────────────────────────────
class _ProductFormDialog extends StatefulWidget {
  final _FirestoreProduct? existing;
  final Color selGreen;
  final TextStyle Function({double size, FontWeight weight, Color color, double? height}) textStyle;
  final void Function(_FirestoreProduct product) onSave;

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

                              final newProduct = _FirestoreProduct(
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