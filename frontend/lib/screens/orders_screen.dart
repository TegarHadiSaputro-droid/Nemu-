import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/address_manager.dart';
<<<<<<< HEAD
import 'package:frontend/services/orders_manager.dart';
import 'package:frontend/services/order_tracking_service.dart';
=======
import 'package:frontend/models/orders_manager.dart';
>>>>>>> 4084a683add0349e9b8fda954e8b38c68013c6d2
import 'package:frontend/widgets/address_editor_sheet.dart';
import 'package:frontend/widgets/live_tracking_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

// ─────────────────────────────────────────────
//  Color Palette (sesuai AppColors Nemu)
// ─────────────────────────────────────────────
const Color _green = Color(0xFF007C3F);
const Color _yellow = Color(0xFFD9DF36);
const Color _dark = Color(0xFF0F1B11);
const Color _surface = Color(0xFFF5F7F0);

TextStyle _manrope({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _dark,
  double? height,
}) => GoogleFonts.manrope(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

// ─────────────────────────────────────────────
//  Model: Order History (dipetakan langsung dari
//  dokumen Firestore collection('orders'))
// ─────────────────────────────────────────────
class OrderHistoryItem {
  final String docId;
  final String id; // orderCode
  final String storeName;
  final String marketName;
  final String date;
  final String items;
  final int totalPrice;
  final String statusLabel;
  final Color statusColor;
  final String rawStatus;
  double? ratingStore;
  double? ratingMarket;

  OrderHistoryItem({
    required this.docId,
    required this.id,
    required this.storeName,
    required this.marketName,
    required this.date,
    required this.items,
    required this.totalPrice,
    required this.statusLabel,
    required this.statusColor,
    required this.rawStatus,
    this.ratingStore,
    this.ratingMarket,
  });

  factory OrderHistoryItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = (data['status'] as String?) ?? kStatusMenungguKonfirmasi;

    String label;
    Color color;
    switch (status) {
      case kStatusMenungguKonfirmasi:
        label = 'Menunggu Konfirmasi';
        color = Colors.orange;
        break;
      case kStatusDikemas:
        label = 'Diproses';
        color = Colors.blue;
        break;
      case kStatusDalamPengantaran:
        label = 'Diantar';
        color = Colors.orange;
        break;
      case kStatusSelesai:
        label = 'Selesai';
        color = _green;
        break;
      case kStatusDibatalkan:
        label = 'Dibatalkan';
        color = Colors.red;
        break;
      default:
        label = status;
        color = Colors.grey;
    }

    final createdAt = data['createdAt'];
    String dateLabel = 'Hari ini';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      dateLabel = isToday
          ? 'Hari ini, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
          : '${dt.day}/${dt.month}/${dt.year}';
    }

    return OrderHistoryItem(
      docId: doc.id,
      id: (data['orderCode'] as String?) ?? doc.id,
      storeName: (data['namaGerai'] as String?) ?? 'Gerai',
      marketName: (data['namaMarket'] as String?) ?? '',
      date: dateLabel,
      items: (data['itemsSummary'] as String?) ?? '',
      totalPrice: (data['totalPrice'] as num?)?.toInt() ?? 0,
      statusLabel: label,
      statusColor: color,
      rawStatus: status,
    );
  }
}

// ─────────────────────────────────────────────
//  OrdersScreen
// ─────────────────────────────────────────────
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──
  late AnimationController _progressAnim;
  late AnimationController _pulseAnim;
  late AnimationController _kurirCardAnim;
  late Animation<double> _pulseAnimation;

<<<<<<< HEAD
  // ── State ──
  int _currentStep = 1; // 0=Diterima, 1=Diproses, 2=Diantar, 3=Selesai

  // Dynamic state management
  // `_activeOrder` == null => Empty State (tidak ada pesanan aktif)
  // `_orderHistory` menyimpan pesanan yang sudah selesai / riwayat
  // Keduanya sekarang sumbernya dari OrdersManager.instance -- diisi begitu
  // checkout_screen.dart manggil OrdersManager.instance.placeOrder(...).
  List<OrderHistoryItem> _orderHistory = [];
  OrderHistoryItem? _activeOrder;

  // ── Broadcast lokasi device Pembeli SELAMA status == diantar, supaya
  // Driver bisa lacak posisi Pembeli buat antar yang akurat. Dikelola lewat
  // subscription terpisah dari StreamBuilder di build() supaya bisa
  // start/stop stream GPS sebagai efek samping begitu status berubah,
  // bukan di dalam builder (yang dipanggil ulang tiap frame).
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _orderStatusSub;
  StreamSubscription<Position>? _myLocationSub;
  String? _lastKnownStatus;

=======
>>>>>>> 4084a683add0349e9b8fda954e8b38c68013c6d2
  @override
  void initState() {
    super.initState();
    _listenOrderStatusForLocationSharing();

    _progressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _kurirCardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _progressAnim.dispose();
    _pulseAnim.dispose();
    _kurirCardAnim.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────
  // EMPTY STATE: Tidak ada pesanan aktif
  // ──────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 72, color: _yellow),
          const SizedBox(height: 12),
          Text(
            'Belum ada pesanan aktif nih, yuk belanja di pasar favoritmu!',
            textAlign: TextAlign.center,
            style: _manrope(size: 14, weight: FontWeight.w700, color: _dark),
          ),
          const SizedBox(height: 12),
          Text(
            'Temukan sayur, buah, dan kebutuhan sehari-hari dari penjual lokal.',
            textAlign: TextAlign.center,
            style: _manrope(size: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 190,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Jelajahi Pasar',
                style: _manrope(
                  size: 14,
                  weight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  void _listenOrderStatusForLocationSharing() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _orderStatusSub = FirebaseFirestore.instance
        .collection('simulated_orders')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      final status = snap.data()?['status'] as String?;
      if (status == _lastKnownStatus) return;
      _lastKnownStatus = status;

      if (status == OrderStatus.diantar) {
        _startSharingMyLocation(uid);
      } else {
        _stopSharingMyLocation();
      }
    });
  }

  Future<void> _startSharingMyLocation(String orderDocId) async {
    if (_myLocationSub != null) return; // udah jalan
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied ||
            req == LocationPermission.deniedForever) {
          return; // nggak bisa share lokasi, biarin driver pakai alamat teks aja
        }
      }
      _myLocationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15, // update tiap gerak ~15m, hemat baterai & write
        ),
      ).listen((pos) {
        OrderTrackingService.updateBuyerLiveLocation(orderDocId, pos);
      });
    } catch (_) {
      // GPS pembeli nggak tersedia -- driver tetap bisa antar pakai alamat teks.
    }
  }

  void _stopSharingMyLocation() {
    _myLocationSub?.cancel();
    _myLocationSub = null;
  }

  void _onActiveOrderChanged() {
    if (mounted) setState(() => _activeOrder = OrdersManager.instance.activeOrder.value);
  }

  void _onHistoryChanged() {
    if (mounted) setState(() => _orderHistory = List.of(OrdersManager.instance.history.value));
  }

  @override
  void dispose() {
    OrdersManager.instance.activeOrder.removeListener(_onActiveOrderChanged);
    OrdersManager.instance.history.removeListener(_onHistoryChanged);
    _orderStatusSub?.cancel();
    _myLocationSub?.cancel();
    _progressAnim.dispose();
    _pulseAnim.dispose();
    _kurirCardAnim.dispose();
    super.dispose();
  }

=======
>>>>>>> 4084a683add0349e9b8fda954e8b38c68013c6d2
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

<<<<<<< HEAD
    return StreamBuilder<DocumentSnapshot>(
      stream: uid == null
          ? const Stream.empty()
          : FirebaseFirestore.instance.collection('simulated_orders').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final status = data?['status'] as String?;
        final hasActiveOrder = data != null && status != OrderStatus.selesai;

        // 0=Diterima (implisit begitu order dibuat), 1=Diproses/Menunggu
        // Driver, 2=Diantar (driver menuju toko ATAU sudah bawa barang),
        // 3=Selesai.
        int currentStep = 1;
        if (status == OrderStatus.menujuPenjual || status == OrderStatus.diantar) {
          currentStep = 2;
        } else if (status == OrderStatus.selesai) {
          currentStep = 3;
        }

        final driverUid = data?['driverUid'] as String?;
        final driverLoc = LiveLatLng.fromMap(data?['driverLocation'] as Map<String, dynamic>?);
        final sellerLoc = LiveLatLng.fromMap(data?['sellerLocation'] as Map<String, dynamic>?);

        final OrderHistoryItem? activeOrder = hasActiveOrder
            ? OrderHistoryItem(
                id: data['id'] ?? 'ORD-0000',
                storeName: data['storeName'] ?? 'Gerai Bu Eko',
                marketName: data['marketName'] ?? 'Pasar Sepinggan',
                date: 'Hari ini',
                items: data['items'] ?? '',
                totalPrice: data['totalPrice'] ?? 0,
                statusLabel: OrderTrackingService.statusLabel(status),
                statusColor: currentStep >= 2 ? Colors.orange : Colors.blue,
              )
            : null;

=======
    if (uid == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFD9DF36),
        body: Center(
          child: Text('Silakan login untuk melihat pesanan.', style: _manrope(size: 13, color: _dark)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: OrdersManager.instance.activeOrdersStream(),
      builder: (context, activeSnap) {
        final activeDocs = activeSnap.data?.docs ?? [];
        final activeOrders = activeDocs.map(OrderHistoryItem.fromDoc).toList();
        // Ambil pesanan aktif paling baru untuk ditampilkan di live tracker
        final OrderHistoryItem? activeOrder = activeOrders.isNotEmpty ? activeOrders.first : null;

        int currentStep = 1; // default: Diproses / dikemas
        if (activeOrder != null) {
          if (activeOrder.rawStatus == kStatusDalamPengantaran) {
            currentStep = 2;
          } else if (activeOrder.rawStatus == kStatusDikemas) {
            currentStep = 1;
          } else if (activeOrder.rawStatus == kStatusMenungguKonfirmasi) {
            currentStep = 0;
          }
        }

>>>>>>> 4084a683add0349e9b8fda954e8b38c68013c6d2
        return Scaffold(
          backgroundColor: const Color(0xFFD9DF36),
          body: Stack(
            children: [
              // ── Base Gradient (identik Beranda) ──
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFD9DF36), Color(0xFF007C3F)],
                  ),
                ),
              ),

              // ── Blob Dekorasi Standar ──
              Positioned(top: -40, right: -50, child: _blob(200, Colors.white.withOpacity(0.12))),
              Positioned(top: 80, left: -60, child: _blob(160, Colors.white.withOpacity(0.10))),
              Positioned(top: 220, right: 20, child: _blob(80, Colors.white.withOpacity(0.08))),
              Positioned(top: 300, left: 30, child: _blob(18, Colors.white.withOpacity(0.20))),
              Positioned(top: 340, right: 60, child: _blob(10, Colors.white.withOpacity(0.18))),
              Positioned(bottom: 200, right: -40, child: _blob(150, const Color(0xFFD9DF36).withOpacity(0.18))),
              Positioned(bottom: 350, left: 10, child: _blob(14, Colors.white.withOpacity(0.15))),

              // ── Content ──
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header: Judul + Alamat ──
                    SliverToBoxAdapter(child: _buildHeader()),

                    // Conditional: show empty state when no active order, otherwise show tracker + kurir
                    if (activeOrder == null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                          child: _buildEmptyState(),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _buildLiveTracker(activeOrder, currentStep, status),
                        ),
                      ),
                      if (driverUid != null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: _buildKurirCard(driverUid),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: _buildLiveMapCard(
                              status: status,
                              driverLoc: driverLoc,
                              sellerLoc: sellerLoc,
                            ),
                          ),
                        ),
                      ],
                    ],

                    // ── Riwayat Pesanan (StreamBuilder terpisah, realtime) ──
                    SliverToBoxAdapter(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: OrdersManager.instance.orderHistoryStream(),
                        builder: (context, historySnap) {
                          final historyDocs = historySnap.data?.docs ?? [];
                          final orderHistory = historyDocs.map(OrderHistoryItem.fromDoc).toList();

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.history_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Riwayat Pesanan',
                                  style: _manrope(
                                    size: 16,
                                    weight: FontWeight.bold,
                                    color: _dark,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${orderHistory.length} pesanan',
                                    style: _manrope(
                                      size: 11,
                                      weight: FontWeight.w600,
                                      color: _dark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: OrdersManager.instance.orderHistoryStream(),
                      builder: (context, historySnap) {
                        final historyDocs = historySnap.data?.docs ?? [];
                        final orderHistory = historyDocs.map(OrderHistoryItem.fromDoc).toList();

                        if (orderHistory.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              child: Center(
                                child: Text(
                                  'Belum ada riwayat pesanan.',
                                  style: _manrope(size: 12, color: Colors.black45),
                                ),
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                i == orderHistory.length - 1 ? 24 : 10,
                              ),
                              child: _buildHistoryCard(orderHistory[i]),
                            ),
                            childCount: orderHistory.length,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────
  //  HEADER: Judul + Alamat Pengiriman (Clean & Jelas dengan Border)
  // ──────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _dark.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: _green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Pesanan Saya',
                  style: _manrope(
                    size: 20,
                    weight: FontWeight.w800,
                    color: _dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pantau status pengirimanmu secara real-time',
              style: _manrope(
                size: 12,
                color: _dark.withOpacity(0.7),
                weight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Alamat Card
            ValueListenableBuilder<DeliveryAddress?>(
              valueListenable: AddressManager.instance.address,
              builder: (context, address, _) {
                return GestureDetector(
                  onTap: _showChangeAddressSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _green.withOpacity(0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _green.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: _green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kirim ke Rumah',
                                style: _manrope(
                                  size: 10,
                                  color: Colors.black45,
                                  weight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                address?.text ?? 'Belum ada alamat, tap untuk isi',
                                style: _manrope(
                                  size: 12,
                                  weight: FontWeight.bold,
                                  color: _dark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Ubah',
                        style: _manrope(
                          size: 11,
                          weight: FontWeight.bold,
                          color: Colors.white,
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
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  //  LIVE TRACKER: Status Pengiriman (Tanpa Emoji)
  // ──────────────────────────────────────────
  Widget _buildLiveTracker(OrderHistoryItem activeOrder, int currentStep, String? status) {
    final steps = [
      _TrackStep(icon: Icons.receipt_long_rounded, label: 'Diterima'),
      _TrackStep(icon: Icons.inventory_2_rounded, label: 'Diproses'),
      _TrackStep(icon: Icons.two_wheeler_rounded, label: 'Diantar'),
      _TrackStep(icon: Icons.check_circle_rounded, label: 'Selesai'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Status Pengiriman',
                style: _manrope(size: 14, weight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LIVE',
                  style: _manrope(
                    size: 10,
                    weight: FontWeight.bold,
                    color: _green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${activeOrder.id} · ${activeOrder.storeName}, ${activeOrder.marketName}',
            style: _manrope(size: 11, color: Colors.black45),
          ),
          const SizedBox(height: 20),

          // Step Tracker Visual
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, _) {
              return Row(
                children: List.generate(steps.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    // Connector line
                    final stepIdx = i ~/ 2;
                    final isDone = stepIdx < currentStep;
                    final progress = isDone
                        ? 1.0
                        : (stepIdx == currentStep - 1
                              ? _progressAnim.value
                              : 0.0);
                    return Expanded(
                      child: Stack(
                        children: [
                          Container(height: 3, color: Colors.grey.shade200),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 3,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_green, Color(0xFF4CAF50)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final stepIdx = i ~/ 2;
                  final isDone = stepIdx <= currentStep;
                  final isActive = stepIdx == currentStep;
                  final step = steps[stepIdx];

                  return GestureDetector(
                    onTap: null, // Driven in real-time by database status
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      width: isActive ? 50 : 38,
                      height: isActive ? 50 : 38,
                      decoration: BoxDecoration(
                        color: isDone ? _green : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: _green.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Icon(
                          step.icon,
                          color: isDone ? Colors.white : Colors.grey.shade400,
                          size: isActive ? 24 : 18,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          // Step Labels
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.asMap().entries.map((e) {
              final isActive = e.key == currentStep;
              return Expanded(
                child: Text(
                  e.value.label,
                  textAlign: TextAlign.center,
                  style: _manrope(
                    size: 9.5,
                    weight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? _green : Colors.black38,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
<<<<<<< HEAD
          Builder(builder: (context) {
            late final IconData icon;
            late final String title;
            late final String subtitle;
            final infoColor = currentStep == 1 ? Colors.blue : _green;

            switch (status) {
              case OrderStatus.menungguDriver:
                icon = Icons.search_rounded;
                title = 'Menunggu Driver...';
                subtitle = 'Sistem sedang mencarikan driver terdekat untuk pesananmu';
                break;
              case OrderStatus.menujuPenjual:
                icon = Icons.storefront_rounded;
                title = 'Driver menuju lokasi penjual';
                subtitle = 'Driver sedang menjemput pesananmu di toko';
                break;
              case OrderStatus.diantar:
                icon = Icons.two_wheeler_rounded;
                title = 'Barang segera diantarkan!';
                subtitle = 'Driver sudah bawa pesananmu, otw ke alamatmu';
                break;
              default:
                icon = Icons.inventory_2_rounded;
                title = 'Pesanan Anda sedang dikemas oleh pedagang';
                subtitle = 'Estimasi siap: 5–10 menit lagi';
            }

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: infoColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: infoColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: infoColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: _manrope(size: 12, weight: FontWeight.bold, color: _dark),
                        ),
                        Text(
                          subtitle,
                          style: _manrope(size: 11, color: Colors.black54),
                        ),
                      ],
                    ),
=======
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentStep <= 1 ? Colors.blue.withOpacity(0.06) : _green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: currentStep <= 1 ? Colors.blue.withOpacity(0.2) : _green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  currentStep <= 1 ? Icons.inventory_2_rounded : Icons.two_wheeler_rounded,
                  color: currentStep <= 1 ? Colors.blue : _green,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentStep == 0
                            ? 'Menunggu konfirmasi dari penjual'
                            : currentStep == 1
                                ? 'Pesanan Anda sedang dikemas oleh pedagang'
                                : 'Pesanan Anda sedang dalam pengantaran oleh kurir',
                        style: _manrope(
                          size: 12,
                          weight: FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                      Text(
                        currentStep == 0
                            ? 'Mohon tunggu sebentar'
                            : currentStep == 1
                                ? 'Estimasi siap: 5–10 menit lagi'
                                : 'Estimasi tiba: 8–12 menit lagi',
                        style: _manrope(size: 11, color: Colors.black54),
                      ),
                    ],
>>>>>>> 4084a683add0349e9b8fda954e8b38c68013c6d2
                  ),
                  if (status == OrderStatus.menungguDriver)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                    )
                  else
                    const Icon(Icons.access_time_rounded, color: Colors.black38, size: 16),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  KURIR CARD: Profil Pengirim (Gradasi Orange Gelap & Tanpa Emoji)
  // ──────────────────────────────────────────
  Widget _buildKurirCard(String driverUid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(driverUid).snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data();
        final name = (d?['name'] as String?) ?? 'Driver';
        final photoUrl = d?['photoUrl'] as String?;
        final rating = (d?['driverRating'] as num?)?.toDouble();
        final deliveries = (d?['driverDeliveries'] as num?) ?? 0;
        return _kurirCardBody(
          driverUid: driverUid,
          name: name,
          photoUrl: photoUrl,
          rating: rating,
          deliveries: deliveries,
        );
      },
    );
  }

  Widget _kurirCardBody({
    required String driverUid,
    required String name,
    String? photoUrl,
    double? rating,
    required num deliveries,
  }) {
    return GestureDetector(
      onTap: () => _showKurirDetailSheet(
        name: name,
        photoUrl: photoUrl,
        rating: rating,
        deliveries: deliveries,
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _kurirCardAnim, curve: Curves.easeOut),
            ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF8C00),
                Color(0xFFD35400),
              ], // Orange to Dark Orange
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD35400).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar Kurir (foto asli kalau ada, fallback ke inisial)
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      color: Colors.white.withOpacity(0.2),
                      image: photoUrl != null
                          ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: photoUrl == null
                        ? Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: _manrope(size: 22, weight: FontWeight.bold, color: Colors.white),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD35400),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 8,
                        color: Color(0xFFD35400),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Info Kurir
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: _manrope(
                              size: 14,
                              weight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'KURIR',
                            style: _manrope(
                              size: 8,
                              weight: FontWeight.bold,
                              color: const Color(0xFFD35400),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sedang mengantar pesananmu',
                      style: _manrope(
                        size: 10,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _kurirStat(
                          Icons.star_rounded,
                          rating != null ? rating.toStringAsFixed(1) : '-',
                          'Rating',
                        ),
                        const SizedBox(width: 14),
                        _kurirStat(
                          Icons.local_shipping_rounded,
                          '$deliveries',
                          'Antar',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lihat Detail Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  //  LIVE MAP: Posisi Driver Real-time
  // ──────────────────────────────────────────
  Widget _buildLiveMapCard({
    required String? status,
    required LiveLatLng? driverLoc,
    required LiveLatLng? sellerLoc,
  }) {
    if (driverLoc == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(Icons.gps_not_fixed_rounded, size: 18, color: Colors.black38),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Menunggu sinyal GPS driver...',
                style: _manrope(size: 11.5, color: Colors.black45),
              ),
            ),
          ],
        ),
      );
    }

    // Selama driver masih menuju toko, tujuan yang relevan buat Pembeli
    // lihat adalah lokasi toko. Begitu barang sudah diambil (status
    // 'diantar'), tujuannya berubah jadi alamat Pembeli sendiri.
    final buyerAddress = AddressManager.instance.address.value;
    final buyerLoc = (buyerAddress?.hasCoordinates ?? false)
        ? LiveLatLng(lat: buyerAddress!.lat!, lng: buyerAddress.lng!)
        : null;

    final bool headingToBuyer = status == OrderStatus.diantar;
    final LiveLatLng? destination = headingToBuyer ? (buyerLoc ?? sellerLoc) : sellerLoc;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_rounded, size: 16, color: _green),
              const SizedBox(width: 6),
              Text('Lacak Driver', style: _manrope(size: 13, weight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          if (destination != null)
            LiveTrackingMap(
              from: driverLoc,
              fromLabel: 'Driver',
              to: destination,
              toLabel: headingToBuyer ? 'Rumahmu' : 'Toko',
            )
          else
            Text(
              'Alamatmu belum ada titik koordinat -- isi lewat "Ganti Alamat" biar peta lebih akurat.',
              style: _manrope(size: 11, color: Colors.black45),
            ),
        ],
      ),
    );
  }

  Widget _kurirStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              value,
              style: _manrope(
                size: 12,
                weight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: _manrope(size: 9, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  //  HISTORY CARD: Riwayat Pesanan
  // ──────────────────────────────────────────
  Widget _buildHistoryCard(OrderHistoryItem order) {
    final hasRated = order.ratingStore != null && order.ratingMarket != null;
    final isCancelled = order.statusLabel == 'Dibatalkan';

    return GestureDetector(
      onTap: isCancelled ? null : () => _showOrderDetailSheet(order),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCancelled
                ? Colors.red.withOpacity(0.15)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? Colors.red.withOpacity(0.1)
                        : _green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCancelled
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline,
                    color: order.statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: _manrope(size: 13, weight: FontWeight.bold),
                      ),
                      Text(
                        order.date,
                        style: _manrope(size: 10, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: _manrope(
                      size: 10,
                      weight: FontWeight.bold,
                      color: order.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 10),

            // Info Toko & Pasar
            Row(
              children: [
                Expanded(
                  child: _historyInfoChip(
                    Icons.storefront_rounded,
                    order.storeName,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _historyInfoChip(
                    Icons.store_mall_directory_rounded,
                    order.marketName,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Items
            Text(
              order.items,
              style: _manrope(size: 11, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Bottom Row: Harga + Rating/Action
            Row(
              children: [
                Text(
                  'Rp${_formatPrice(order.totalPrice)}',
                  style: _manrope(
                    size: 14,
                    weight: FontWeight.bold,
                    color: _green,
                  ),
                ),
                const Spacer(),
                if (!isCancelled)
                  hasRated
                      ? Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Sudah dinilai',
                              style: _manrope(size: 10, color: Colors.black45),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: () => _showRatingModal(order),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF007C3F), Color(0xFF4CAF50)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_outline_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Beri Nilai',
                                  style: _manrope(
                                    size: 10,
                                    weight: FontWeight.bold,
                                    color: Colors.white,
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
      ),
    );
  }

  Widget _historyInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: _manrope(size: 10, weight: FontWeight.w600, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  SHEETS & MODALS
  // ──────────────────────────────────────────

  void _showChangeAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddressEditorSheet(),
    );
  }

  /// Sheet: Detail Kurir (Tanpa Emoji)
  void _showKurirDetailSheet({
    required String name,
    String? photoUrl,
    double? rating,
    required num deliveries,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheet(
        title: 'Profil Driver',
        child: Column(
          children: [
            // Avatar besar (foto asli / inisial)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD35400), width: 3),
                color: const Color(0xFFD35400).withOpacity(0.1),
                image: photoUrl != null
                    ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: photoUrl == null
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: _manrope(size: 32, weight: FontWeight.bold, color: const Color(0xFFD35400)),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: _manrope(size: 18, weight: FontWeight.bold),
            ),
            Text(
              'Driver Nemu',
              style: _manrope(size: 12, color: Colors.black45),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _kurirStatBox(Icons.star_rounded, rating != null ? rating.toStringAsFixed(1) : '-', 'Rating'),
                _kurirStatBox(
                  Icons.local_shipping_rounded,
                  '$deliveries',
                  'Pengantaran',
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone_rounded, size: 16),
                label: Text(
                  'Hubungi Kurir',
                  style: _manrope(
                    size: 13,
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD35400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kurirStatBox(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFFD35400)),
        const SizedBox(height: 4),
        Text(
          value,
          style: _manrope(size: 16, weight: FontWeight.bold, color: _dark),
        ),
        Text(label, style: _manrope(size: 10, color: Colors.black45)),
      ],
    );
  }

  /// Sheet: Detail Riwayat Pesanan (Tanpa Emoji)
  void _showOrderDetailSheet(OrderHistoryItem order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheet(
        title: 'Detail Pesanan ${order.id}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(
              Icons.confirmation_number_rounded,
              'Nomor Pesanan',
              order.id,
            ),
            _detailRow(Icons.calendar_today_rounded, 'Tanggal', order.date),
            _detailRow(Icons.storefront_rounded, 'Gerai', order.storeName),
            _detailRow(
              Icons.store_mall_directory_rounded,
              'Pasar',
              order.marketName,
            ),
            _detailRow(Icons.shopping_bag_rounded, 'Produk', order.items),
            _detailRow(
              Icons.payments_rounded,
              'Total',
              'Rp${_formatPrice(order.totalPrice)}',
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            if (order.ratingStore == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star_rounded, size: 16),
                  label: Text(
                    'Beri Penilaian',
                    style: _manrope(
                      size: 13,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showRatingModal(order);
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gerai: ${order.ratingStore!.toStringAsFixed(1)}★  |  '
                      'Pasar: ${order.ratingMarket!.toStringAsFixed(1)}★',
                      style: _manrope(size: 12, weight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _green),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: _manrope(size: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: _manrope(size: 12, weight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Modal: Rating Gerai & Pasar
  /// CATATAN: rating masih disimpan lokal di objek (tidak dipersist ke
  /// Firestore). Kalau mau permanen, tambahkan write ke field
  /// 'ratingStore' / 'ratingMarket' pada dokumen order terkait di sini.
  void _showRatingModal(OrderHistoryItem order) {
    double ratingStore = 0;
    double ratingMarket = 0;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Beri Penilaian',
                  style: _manrope(size: 18, weight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bagaimana pengalamanmu?',
                  style: _manrope(size: 12, color: Colors.black45),
                ),
                const SizedBox(height: 20),

                _ratingSection(
                  icon: Icons.storefront_rounded,
                  title: 'Gerai: ${order.storeName}',
                  rating: ratingStore,
                  onChanged: (v) => setDialogState(() => ratingStore = v),
                ),
                const SizedBox(height: 16),

                _ratingSection(
                  icon: Icons.store_mall_directory_rounded,
                  title: 'Pasar: ${order.marketName}',
                  rating: ratingMarket,
                  onChanged: (v) => setDialogState(() => ratingMarket = v),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Batal',
                          style: _manrope(size: 13, color: Colors.black45),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: ratingStore > 0 && ratingMarket > 0
                            ? () async {
                                order.ratingStore = ratingStore;
                                order.ratingMarket = ratingMarket;
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('orders')
                                      .doc(order.docId)
                                      .update({
                                    'ratingStore': ratingStore,
                                    'ratingMarket': ratingMarket,
                                  });
                                } catch (_) {
                                  // Abaikan jika gagal, UI lokal tetap terupdate
                                }
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Terima kasih atas penilaianmu!',
                                      style: _manrope(
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: _green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                        ),
                        child: Text(
                          'Kirim Penilaian',
                          style: _manrope(
                            size: 13,
                            weight: FontWeight.bold,
                            color: ratingStore > 0 && ratingMarket > 0
                                ? Colors.white
                                : Colors.black38,
                          ),
                        ),
                      ),
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

  Widget _ratingSection({
    required IconData icon,
    required String title,
    required double rating,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: _manrope(size: 12, weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => onChanged(i + 1.0),
                child: AnimatedScale(
                  scale: rating > i ? 1.25 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      rating > i
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: rating > i ? Colors.amber : Colors.grey.shade300,
                      size: 32,
                    ),
                  ),
                ),
              );
            }),
          ),
          if (rating > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Center(
                child: Text(
                  _ratingLabel(rating.toInt()),
                  style: _manrope(
                    size: 11,
                    weight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Bagus';
      case 5:
        return 'Sangat Memuaskan';
      default:
        return '';
    }
  }

  // ──────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────
  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

// ─────────────────────────────────────────────
//  Reusable Bottom Sheet Wrapper
// ─────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: _manrope(size: 16, weight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Data Model
// ─────────────────────────────────────────────
class _TrackStep {
  final IconData icon;
  final String label;
  const _TrackStep({required this.icon, required this.label});
}