import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
//  Model: Order History
// ─────────────────────────────────────────────
class OrderHistoryItem {
  final String id;
  final String storeName;
  final String marketName;
  final String date;
  final String items;
  final int totalPrice;
  final String statusLabel;
  final Color statusColor;
  double? ratingStore;
  double? ratingMarket;

  OrderHistoryItem({
    required this.id,
    required this.storeName,
    required this.marketName,
    required this.date,
    required this.items,
    required this.totalPrice,
    required this.statusLabel,
    required this.statusColor,
    this.ratingStore,
    this.ratingMarket,
  });
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

  // ── State ──
  int _currentStep = 1; // 0=Diterima, 1=Diproses, 2=Diantar, 3=Selesai
  String _activeAddress = 'Jl. Mawar No. 12, Balikpapan Selatan';

  // Dynamic state management
  // `_activeOrder` == null => Empty State (tidak ada pesanan aktif)
  // `_orderHistory` menyimpan pesanan yang sudah selesai / riwayat
  List<OrderHistoryItem> _orderHistory = [];
  OrderHistoryItem? _activeOrder;

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _progressAnim.dispose();
    _pulseAnim.dispose();
    _kurirCardAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Positioned(
            top: -40,
            right: -50,
            child: _blob(200, Colors.white.withOpacity(0.12)),
          ),
          Positioned(
            top: 80,
            left: -60,
            child: _blob(160, Colors.white.withOpacity(0.10)),
          ),
          Positioned(
            top: 220,
            right: 20,
            child: _blob(80, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            top: 300,
            left: 30,
            child: _blob(18, Colors.white.withOpacity(0.20)),
          ),
          Positioned(
            top: 340,
            right: 60,
            child: _blob(10, Colors.white.withOpacity(0.18)),
          ),
          Positioned(
            bottom: 200,
            right: -40,
            child: _blob(150, const Color(0xFFD9DF36).withOpacity(0.18)),
          ),
          Positioned(
            bottom: 350,
            left: 10,
            child: _blob(14, Colors.white.withOpacity(0.15)),
          ),

          // ── Content ──
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header: Judul + Alamat (Tajam & Terbaca dengan Card Container + Border) ──
                SliverToBoxAdapter(child: _buildHeader()),

                // Conditional: show empty state when no active order, otherwise show tracker + kurir
                if (_activeOrder == null)
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
                      child: _buildLiveTracker(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildKurirCard(),
                    ),
                  ),
                ],

                // ── Riwayat Pesanan ──
                SliverToBoxAdapter(
                  child: Padding(
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
                            '${_orderHistory.length} pesanan',
                            style: _manrope(
                              size: 11,
                              weight: FontWeight.w600,
                              color: _dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        i == _orderHistory.length - 1 ? 24 : 10,
                      ),
                      child: _buildHistoryCard(_orderHistory[i]),
                    ),
                    childCount: _orderHistory.length,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            GestureDetector(
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
                            _activeAddress,
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
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  //  LIVE TRACKER: Status Pengiriman (Tanpa Emoji)
  // ──────────────────────────────────────────
  Widget _buildLiveTracker() {
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
            _activeOrder != null
                ? '${_activeOrder!.id} · ${_activeOrder!.storeName}, ${_activeOrder!.marketName}'
                : '-',
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
                    final isDone = stepIdx < _currentStep;
                    final progress = isDone
                        ? 1.0
                        : (stepIdx == _currentStep - 1
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
                  final isDone = stepIdx <= _currentStep;
                  final isActive = stepIdx == _currentStep;
                  final step = steps[stepIdx];

                  return GestureDetector(
                    onTap: () => setState(() => _currentStep = stepIdx),
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
              final isActive = e.key == _currentStep;
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.two_wheeler_rounded, color: _green, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sedang dalam perjalanan ke rumah!',
                        style: _manrope(
                          size: 12,
                          weight: FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                      Text(
                        'Estimasi tiba: 8–12 menit lagi',
                        style: _manrope(size: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  color: Colors.black38,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  KURIR CARD: Profil Pengirim (Gradasi Orange Gelap & Tanpa Emoji)
  // ──────────────────────────────────────────
  Widget _buildKurirCard() {
    return GestureDetector(
      onTap: _showKurirDetailSheet,
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
              // Avatar Kurir Icon
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
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
                        Text(
                          'Pak Budi Santoso',
                          style: _manrope(
                            size: 14,
                            weight: FontWeight.bold,
                            color: Colors.white,
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
                      '"Antar cepat, sayur tetap segar!"',
                      style: _manrope(
                        size: 10,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _kurirStat(Icons.star_rounded, '4.9', 'Rating'),
                        const SizedBox(width: 14),
                        _kurirStat(
                          Icons.local_shipping_rounded,
                          '1.2K',
                          'Antar',
                        ),
                        const SizedBox(width: 14),
                        _kurirStat(Icons.cake_rounded, '34 th', 'Umur'),
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

  /// Sheet: Ubah Alamat
  void _showChangeAddressSheet() {
    final addresses = [
      'Jl. Mawar No. 12, Balikpapan Selatan',
      'Jl. Melati No. 5, Balikpapan Utara',
      'Jl. Kenanga Blok A-3, Balikpapan Barat',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheet(
        title: 'Pilih Alamat Pengiriman',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...addresses.map(
              (addr) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 2,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: _green,
                    size: 18,
                  ),
                ),
                title: Text(
                  addr,
                  style: _manrope(size: 13, weight: FontWeight.w600),
                ),
                trailing: addr == _activeAddress
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: _green,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  setState(() => _activeAddress = addr);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                label: Text(
                  'Tambah Alamat Baru',
                  style: _manrope(
                    size: 13,
                    weight: FontWeight.bold,
                    color: _green,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: const BorderSide(color: _green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sheet: Detail Kurir (Tanpa Emoji)
  void _showKurirDetailSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheet(
        title: 'Profil Kurir',
        child: Column(
          children: [
            // Avatar besar Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD35400), width: 3),
                color: const Color(0xFFD35400).withOpacity(0.1),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 54,
                  color: Color(0xFFD35400),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pak Budi Santoso',
              style: _manrope(size: 18, weight: FontWeight.bold),
            ),
            Text(
              '34 tahun · Kurir Aktif sejak 2022',
              style: _manrope(size: 12, color: Colors.black45),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD35400).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"Antar cepat, sayur tetap segar! Kepuasan pelanggan adalah prioritas saya."',
                style: _manrope(size: 12, color: _dark, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _kurirStatBox(Icons.star_rounded, '4.9', 'Rating'),
                _kurirStatBox(
                  Icons.local_shipping_rounded,
                  '1.234',
                  'Pengantaran',
                ),
                _kurirStatBox(Icons.verified_rounded, '99%', 'On-time'),
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

  /// Modal: Rating Gerai & Pasar (Tanpa Emoji)
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

                // Rating Gerai
                _ratingSection(
                  icon: Icons.storefront_rounded,
                  title: 'Gerai: ${order.storeName}',
                  rating: ratingStore,
                  onChanged: (v) => setDialogState(() => ratingStore = v),
                ),
                const SizedBox(height: 16),

                // Rating Pasar
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
                            ? () {
                                setState(() {
                                  order.ratingStore = ratingStore;
                                  order.ratingMarket = ratingMarket;
                                });
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
