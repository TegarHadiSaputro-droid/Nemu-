// driver_home_screen.dart
//
// FASE 1: Dashboard Driver (UI + akses berbasis role).
// Belum ada logic GPS real-time / navigasi / pesanan asli — itu Fase
// berikutnya. File ini fokus ke dua hal dulu:
//   1. DriverDashboardBody — tampilan dashboard driver, dengan pola yang
//      SAMA PERSIS seperti SellerDashboardBody di seller_home_screen.dart
//      (dipanggil dari HomeScreen saat _isDriver == true, TIDAK membungkus
//      Scaffold sendiri).
//   2. DriverHomeScreen — halaman standalone yang bisa langsung di-push
//      (Navigator.push) untuk testing, atau dipakai sebagai route utama.
//      Nolak akses kalau roles.driver != true di Firestore.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────
//  Warna Palette (konsisten dengan seller_home_screen.dart / home_screen.dart)
// ─────────────────────────────────────────────
const Color _drGreen = Color(0xFF007C3F);
const Color _drYellow = Color(0xFFD9DF36);
const Color _drDark = Color(0xFF0F1B11);
const Color _drAmber = Color(0xFFF59E0B);

TextStyle _md({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _drDark,
  double? height,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

// ─────────────────────────────────────────────
//  DriverDashboardBody
//  Dipanggil dari HomeScreen saat _isDriver == true (pola sama seperti
//  SellerDashboardBody). Widget ini TIDAK membungkus Scaffold sendiri —
//  cuma konten yang ditaruh di dalam Scaffold/gradient milik HomeScreen.
// ─────────────────────────────────────────────
class DriverDashboardBody extends StatefulWidget {
  final String userName;
  final String? photoUrl;

  const DriverDashboardBody({
    super.key,
    required this.userName,
    this.photoUrl,
  });

  @override
  State<DriverDashboardBody> createState() => _DriverDashboardBodyState();
}

class _DriverDashboardBodyState extends State<DriverDashboardBody>
    with TickerProviderStateMixin {
  // ── Animasi entrance, konsisten dengan SellerDashboardBody ──
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceAnim;

  // ── Data driver dari Firestore (stream) ──
  Map<String, dynamic>? _driverData;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _driverSub;

  bool _isOnline = false;
  bool _togglingOnline = false;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceAnim =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);
    _entranceCtrl.forward();

    _listenDriverData();
  }

  void _listenDriverData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _driverSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      setState(() {
        _driverData = data;
        _isOnline = (data?['driverStatus'] as String?) == 'online';
      });
    });
  }

  // Toggle online/offline. Nulis field 'driverStatus' ke users/{uid}.
  //
  // TODO (Fase GPS): begitu status jadi 'online', mulai
  // Geolocator.getPositionStream(...) dan tulis lokasinya berkala ke
  // Firestore (mis. users/{uid}.currentLocation) supaya penjual & pembeli
  // bisa lacak real-time. Begitu 'offline', hentikan stream lokasinya.
  // Belum diimplementasi di sini karena Fase 1 fokus ke UI + akses dulu.
  Future<void> _toggleOnline(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _togglingOnline = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'driverStatus': value ? 'online' : 'offline'},
        SetOptions(merge: true),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingOnline = false);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _driverSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceAnim,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildOnlineToggleCard(),
            const SizedBox(height: 16),
            _buildActiveDeliverySection(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 20),
            _buildIncomingRequestsSection(),
          ],
        ),
      ),
    );
  }

  // 1. Header — avatar + nama + label "Driver Nemu"
  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          backgroundImage:
              widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
          child: widget.photoUrl == null
              ? Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : '?',
                  style: _md(
                    size: 18,
                    weight: FontWeight.bold,
                    color: _drGreen,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: _md(size: 16, weight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Driver Nemu',
                style: _md(size: 12, color: Colors.white.withOpacity(0.85)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Kartu status Online/Offline — nanti disini juga tempat GPS dimulai
  Widget _buildOnlineToggleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_isOnline ? _drGreen : Colors.grey)
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isOnline ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                  color: _isOnline ? _drGreen : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnline ? 'Kamu sedang Online' : 'Kamu sedang Offline',
                      style: _md(size: 13.5, weight: FontWeight.bold),
                    ),
                    Text(
                      _isOnline
                          ? 'Siap menerima pesanan pengantaran'
                          : 'Nyalakan supaya bisa menerima pesanan',
                      style: _md(size: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              _togglingOnline
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Switch(
                      value: _isOnline,
                      activeColor: _drGreen,
                      onChanged: _toggleOnline,
                    ),
            ],
          ),
          if (_isOnline) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: _drAmber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'GPS harus tetap aktif selama online, supaya penjual dan pembeli bisa melacak posisimu secara real-time.',
                    style: _md(size: 11, color: Colors.black54, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 3. Pesanan aktif (dalam proses antar) — placeholder empty state.
  // Fase berikutnya: dengarkan collection order asli tempat
  // driverUid == uid && status masuk tahap "sedang diantar".
  Widget _buildActiveDeliverySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            'Belum ada pesanan yang sedang kamu antar',
            textAlign: TextAlign.center,
            style: _md(size: 13, weight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            'Kartu pesanan aktif (rute, tujuan, kontak pembeli) akan muncul di sini.',
            textAlign: TextAlign.center,
            style: _md(size: 11, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  // 4. Statistik ringkas — dibaca dari field di users/{uid}. Kalau field
  // belum ada, tampil 0 dulu (bukan mock/dummy) sampai datanya real.
  Widget _buildStatsRow() {
    final totalDelivered = (_driverData?['driverDeliveries'] as num?) ?? 0;
    final rating = (_driverData?['driverRating'] as num?)?.toDouble();

    return Row(
      children: [
        Expanded(
          child: _statBox(
            icon: Icons.inventory_2_outlined,
            value: '$totalDelivered',
            label: 'Antaran Selesai',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            icon: Icons.star_rounded,
            value: rating != null ? rating.toStringAsFixed(1) : '-',
            label: 'Rating',
          ),
        ),
      ],
    );
  }

  Widget _statBox({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: _drGreen, size: 20),
          const SizedBox(height: 6),
          Text(value, style: _md(size: 16, weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: _md(size: 10.5, color: Colors.black54)),
        ],
      ),
    );
  }

  // 5. Permintaan masuk — placeholder empty state.
  // Fase berikutnya: begitu penjual accept pesanan pembeli di
  // seller_home_screen.dart, sistem bakal cari driver online terdekat dan
  // munculkan popup permintaan di sini (accept / tolak).
  Widget _buildIncomingRequestsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none_rounded,
              color: Colors.black38, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isOnline
                  ? 'Menunggu permintaan pengantaran baru...'
                  : 'Nyalakan status Online untuk mulai menerima permintaan',
              style: _md(size: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DriverHomeScreen
//  Halaman standalone: bisa langsung di-push via Navigator buat testing,
//  atau nanti dipakai sebagai bagian dari routing utama (main.dart /
//  home_screen.dart). INI YANG NOLAK AKSES kalau roles.driver != true.
// ─────────────────────────────────────────────
class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const _DriverAccessDenied(
        message: 'Kamu harus login dulu untuk mengakses halaman ini.',
      );
    }

    // StreamBuilder supaya kalau roles.driver berubah (mis. dicabut admin),
    // halaman ini otomatis nolak akses tanpa perlu keluar-masuk manual.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _drGreen)),
          );
        }

        final data = snapshot.data?.data();
        final roles = data?['roles'] as Map<String, dynamic>?;
        final isDriver = (roles?['driver'] as bool?) ?? false;

        // ── Akses ditolak kalau belum berlabel Driver ──
        if (!isDriver) {
          return const _DriverAccessDenied(
            message:
                'Halaman ini cuma bisa diakses akun yang sudah berlabel Driver.',
          );
        }

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_drYellow, _drGreen],
              ),
            ),
            child: SafeArea(
              child: DriverDashboardBody(
                userName: (data?['name'] as String?) ?? 'Driver',
                photoUrl: data?['photoUrl'] as String?,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DriverAccessDenied extends StatelessWidget {
  final String message;
  const _DriverAccessDenied({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: _md(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.maybePop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Kembali', style: _md(size: 13, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
