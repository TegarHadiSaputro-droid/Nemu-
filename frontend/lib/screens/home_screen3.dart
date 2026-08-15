// home_screen3.dart
//
// Dashboard DRIVER -- pasangan home_screen.dart (Pembeli) & home_screen2.dart
// (Penjual). Class utamanya HomeScreen3, dipanggil dari router utama
// (mis. main.dart) begitu roles.driver == true, SAMA seperti HomeScreen2
// dipanggil untuk roles.seller.
//
// HomeScreen3 SENDIRI yang menolak akses kalau roles.driver != true --
// jadi walau ada yang salah dispatch di router, halaman ini tetap aman
// diakses langsung (defense in depth, bukan cuma andalin router).
//
// Alur pesanan yang ditangani di sini (lihat order_tracking_service.dart
// buat detail state machine-nya):
//   1. Online  -> GPS jalan terus (getPositionStream), lokasi ditulis ke
//      users/{uid}.currentLocation supaya kelihatan "aktif" ke sistem.
//   2. Ada permintaan baru (status menunggu_driver) -> popup, Terima/Lewati.
//   3. Terima -> fase "menuju_penjual": GPS device ini SEKALIGUS ditulis ke
//      order aktif (driverLocation) tiap ~5 detik supaya Penjual & Pembeli
//      bisa lacak. Tombol "Sudah Ambil Barang" begitu sampai di toko.
//   4. Fase "diantar": peta + jarak ke alamat Pembeli (pakai lokasi live
//      Pembeli kalau ada, fallback ke titik alamat tersimpan), tombol buka
//      navigasi eksternal, dan tombol selesaikan pesanan (wajib foto bukti).
//   5. Foto diupload ke Firebase Storage, order ditandai selesai.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/order_tracking_service.dart';
import 'package:frontend/widgets/live_tracking_map.dart';
import 'package:frontend/Profile/account.dart';
import 'package:frontend/widgets/bottom_navbar.dart';

// ─────────────────────────────────────────────
//  Warna Palette (konsisten dengan seller_home_screen.dart / home_screen.dart)
// ─────────────────────────────────────────────
const Color _drGreen = Color(0xFF007C3F);
const Color _drYellow = Color(0xFFD9DF36);
const Color _drDark = Color(0xFF0F1B11);
const Color _drAmber = Color(0xFFF59E0B);
const Color _drBlue = Color(0xFF0071FF);

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
//  HomeScreen3
//  Halaman utama Driver. Menolak akses kalau roles.driver != true.
//  UI shell-nya COPY PERSIS dari home_screen2.dart (HomeScreen2/Penjual):
//  gradient + dekorasi blob/dot + NemuBottomNavbar di bawah.
// ─────────────────────────────────────────────
class HomeScreen3 extends StatefulWidget {
  const HomeScreen3({super.key});

  @override
  State<HomeScreen3> createState() => _HomeScreen3State();
}

class _HomeScreen3State extends State<HomeScreen3> with TickerProviderStateMixin {
  int _navIndex = 0;

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
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _drGreen)),
          );
        }

        final data = snapshot.data?.data();
        final roles = data?['roles'] as Map<String, dynamic>?;
        final isDriver = (roles?['driver'] as bool?) ?? false;

        if (!isDriver) {
          return const _DriverAccessDenied(
            message: 'Halaman ini cuma bisa diakses akun yang sudah berlabel Driver.',
          );
        }

        final userName = (data?['name'] as String?) ?? 'Driver';
        final photoUrl = data?['photoUrl'] as String?;

        return Scaffold(
          body: Stack(
            children: [
              // ── Base Gradient ──
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_drYellow, _drGreen],
                  ),
                ),
              ),

              // ── Dekorasi Playful Background (copy persis dari home_screen2.dart) ──
              Positioned(top: -40, right: -50, child: _blob(200, Colors.white.withValues(alpha: 0.12))),
              Positioned(top: 80, left: -60, child: _blob(160, Colors.white.withValues(alpha: 0.10))),
              Positioned(top: 220, right: 20, child: _blob(80, Colors.white.withValues(alpha: 0.08))),
              Positioned(top: 300, left: 30, child: _dot(18, Colors.white.withValues(alpha: 0.20))),
              Positioned(top: 340, right: 60, child: _dot(10, Colors.white.withValues(alpha: 0.18))),
              Positioned(bottom: 200, right: -40, child: _blob(150, _drYellow.withValues(alpha: 0.18))),
              Positioned(bottom: 350, left: 10, child: _dot(14, Colors.white.withValues(alpha: 0.15))),

              // ── Konten Utama ──
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.03),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(position: slide, child: child),
                            );
                          },
                          child: _navIndex == 0
                              ? DriverDashboardBody(
                                  key: const ValueKey('driver_dash'),
                                  userName: userName,
                                  photoUrl: photoUrl,
                                )
                              : AccountPage(
                                  key: const ValueKey('driver_account'),
                                ),
                        ),
                      ),

                      // Bottom Nav Khusus Driver
                      NemuBottomNavbar(
                        currentIndex: _navIndex,
                        isDriver: true,
                        onTap: (i) => setState(() => _navIndex = i),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  Background shapes helper (copy persis dari home_screen2.dart)
  // ─────────────────────────────────────────────
  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }

  Widget _dot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DriverDashboardBody
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
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceAnim;

  Map<String, dynamic>? _driverData;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _driverSub;

  bool _isOnline = false;
  bool _togglingOnline = false;

  // ── Kecepatan live (dari GPS stream), buat estimasi waktu tempuh ──
  double _currentSpeedKmh = 0;

  // ── GPS 24/7 selama online ──
  StreamSubscription<Position>? _gpsSub;
  DateTime? _lastOrderLocationWrite;

  // ── Order yang sedang ditangani (menuju_penjual / diantar) ──
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activeOrderSub;
  QueryDocumentSnapshot<Map<String, dynamic>>? _activeOrderDoc;

  // ── Permintaan masuk (menunggu_driver, belum ada driver) ──
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _openRequestsSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _openRequests = [];
  final Set<String> _dismissedRequestIds = {}; // yang di-"Lewati" di popup ini
  bool _requestDialogOpen = false;

  bool _submittingAccept = false;
  bool _submittingPickup = false;
  bool _submittingComplete = false;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _entranceAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);
    _entranceCtrl.forward();

    _listenDriverData();
    _listenActiveOrder();
  }

  void _listenDriverData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _driverSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      final onlineNow = (data?['driverStatus'] as String?) == 'online';
      setState(() {
        _driverData = data;
        _isOnline = onlineNow;
      });
      if (onlineNow) {
        _startGpsStream();
        if (_activeOrderDoc == null && _openRequestsSub == null) {
          _listenOpenRequests();
        }
      } else {
        _stopGpsStream();
        _openRequestsSub?.cancel();
        _openRequestsSub = null;
        if (mounted) setState(() => _openRequests = []);
      }
    });
  }

  void _listenActiveOrder() {
    _activeOrderSub = OrderTrackingService.watchMyActiveDelivery().listen((snap) {
      if (!mounted) return;
      setState(() {
        _activeOrderDoc = snap.docs.isNotEmpty ? snap.docs.first : null;
      });
      // Kalau lagi pegang order aktif, nggak perlu dengerin permintaan baru
      // lain (satu driver satu antaran dalam satu waktu di prototipe ini).
      if (_activeOrderDoc != null) {
        _openRequestsSub?.cancel();
        _openRequestsSub = null;
        setState(() => _openRequests = []);
      } else if (_isOnline && _openRequestsSub == null) {
        _listenOpenRequests();
      }
    });
  }

  void _listenOpenRequests() {
    _openRequestsSub = OrderTrackingService.watchOpenRequests().listen((snap) {
      if (!mounted) return;
      setState(() => _openRequests = snap.docs);
      _maybeShowRequestPopup();
    });
  }

  void _maybeShowRequestPopup() {
    if (!mounted) return;
    if (_requestDialogOpen || _activeOrderDoc != null) return;
    final pending = _openRequests.where((d) => !_dismissedRequestIds.contains(d.id));
    if (pending.isEmpty) return;
    final next = pending.first;

    _requestDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _IncomingRequestDialog(
        doc: next,
        onSkip: () {
          _dismissedRequestIds.add(next.id);
          Navigator.pop(context);
        },
        onAccept: () async {
          Navigator.pop(context);
          await _acceptOrder(next);
        },
      ),
    ).then((_) {
      _requestDialogOpen = false;
      // Ada request lain yang belum di-skip/accept? Munculin lagi.
      Future.delayed(const Duration(milliseconds: 300), _maybeShowRequestPopup);
    });
  }

  Future<void> _acceptOrder(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    if (_submittingAccept) return;
    setState(() => _submittingAccept = true);
    final ok = await OrderTrackingService.acceptOrder(doc.id, driverName: widget.userName);
    if (mounted) {
      setState(() => _submittingAccept = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Pesanan diterima! Yuk jemput ke toko.' : 'Yah, pesanan ini sudah diambil driver lain.',
            style: _md(size: 12, color: Colors.white),
          ),
          backgroundColor: ok ? _drGreen : Colors.red.shade400,
        ),
      );
    }
  }

  // ── GPS 24/7 SELAMA ONLINE ──
  void _startGpsStream() {
    if (_gpsSub != null) return;
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // pos.speed dari Geolocator dalam meter/detik -> konversi ke km/jam.
      // Kadang GPS ngasih noise/negatif pas device diam, jadi di-clamp ke 0.
      if (mounted) {
        setState(() => _currentSpeedKmh = (pos.speed * 3.6).clamp(0, 200).toDouble());
      }

      // 1) Selalu update posisi umum si driver (dipakai buat matching driver
      // terdekat di fase berikutnya / status "aktif").
      FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'currentLocation': {
            'lat': pos.latitude,
            'lng': pos.longitude,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
        },
        SetOptions(merge: true),
      );

      // 2) Kalau lagi pegang order aktif, mirror ke dokumen order-nya juga
      // (di-throttle ~5 detik biar nggak spam write) supaya Penjual &
      // Pembeli bisa lacak real-time.
      final order = _activeOrderDoc;
      if (order != null) {
        final now = DateTime.now();
        if (_lastOrderLocationWrite == null ||
            now.difference(_lastOrderLocationWrite!) > const Duration(seconds: 5)) {
          _lastOrderLocationWrite = now;
          OrderTrackingService.updateDriverLocation(order.id, pos);
        }
      }
    });
  }

  void _stopGpsStream() {
    _gpsSub?.cancel();
    _gpsSub = null;
  }

  Future<void> _toggleOnline(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (value) {
      // Minta izin lokasi DULU sebelum nyalain online -- driver online tanpa
      // GPS nggak ada gunanya buat sistem pelacakan.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Izin lokasi dibutuhkan supaya bisa online sebagai Driver.', style: _md(size: 12, color: Colors.white)),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nyalakan GPS di HP kamu dulu ya.', style: _md(size: 12, color: Colors.white)),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
        return;
      }
    }

    setState(() => _togglingOnline = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'driverStatus': value ? 'online' : 'offline'},
        SetOptions(merge: true),
      );
      if (value) {
        _startGpsStream();
        if (_openRequestsSub == null) _listenOpenRequests();
      } else {
        _stopGpsStream();
        _openRequestsSub?.cancel();
        _openRequestsSub = null;
        setState(() => _openRequests = []);
      }
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

  Future<void> _confirmPickup() async {
    final order = _activeOrderDoc;
    if (order == null || _submittingPickup) return;
    setState(() => _submittingPickup = true);
    await OrderTrackingService.confirmPickup(order.id);
    if (mounted) {
      setState(() => _submittingPickup = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barang diambil! Yuk antar ke pembeli.', style: _md(size: 12, color: Colors.white)),
          backgroundColor: _drGreen,
        ),
      );
    }
  }

  // Jarak (km) & estimasi waktu tempuh dari posisi driver ke tujuan.
  // Geolocator.distanceBetween() ngasih jarak garis lurus (meter) -- bukan
  // jarak jalan asli, tapi cukup buat estimasi kasar tanpa perlu API
  // routing berbayar. Rute tercepat yang sebenarnya (ngikutin jalan)
  // ditangani lewat tombol "Petunjuk Arah" yang buka Google Maps eksternal.
  ({double distanceKm, int etaMinutes})? _estimateTrip(LiveLatLng from, LiveLatLng to) {
    final meters = Geolocator.distanceBetween(from.lat, from.lng, to.lat, to.lng);
    final km = meters / 1000;
    // Pakai kecepatan live kalau driver emang lagi jalan (>5 km/h), kalau
    // diam/baru mulai pakai asumsi rata-rata motor di kota (25 km/h) biar
    // ETA nggak jadi infinite/aneh pas kecepatan live-nya 0.
    final speedForEta = _currentSpeedKmh > 5 ? _currentSpeedKmh : 25.0;
    final etaMinutes = (km / speedForEta * 60).ceil().clamp(1, 999);
    return (distanceKm: km, etaMinutes: etaMinutes);
  }

  Future<void> _openExternalNavigation(LiveLatLng destination) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.lat},${destination.lng}&travelmode=motorcycle',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nggak bisa buka aplikasi peta.', style: _md(size: 12, color: Colors.white))),
      );
    }
  }

  Future<void> _completeDeliveryWithPhoto() async {
    final order = _activeOrderDoc;
    if (order == null || _submittingComplete) return;

    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo == null) return; // driver batal foto

    setState(() => _submittingComplete = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final ref = FirebaseStorage.instance
          .ref()
          .child('delivery_proofs')
          .child('${order.id}_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(photo.path));
      final url = await ref.getDownloadURL();

      await OrderTrackingService.completeDelivery(order.id, url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan selesai! Terima kasih sudah mengantar.', style: _md(size: 12, color: Colors.white)),
            backgroundColor: _drGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyelesaikan pesanan: $e', style: _md(size: 12, color: Colors.white))),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingComplete = false);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _driverSub?.cancel();
    _gpsSub?.cancel();
    _activeOrderSub?.cancel();
    _openRequestsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_entranceAnim),
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildOnlineToggleCard(),
            const SizedBox(height: 16),
            if (_activeOrderDoc != null)
              _buildActiveDeliveryCard(_activeOrderDoc!)
            else
              _buildNoActiveDeliveryCard(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 20),
            _buildIncomingRequestsSection(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          backgroundImage: widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
          child: widget.photoUrl == null
              ? Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                  style: _md(size: 18, weight: FontWeight.bold, color: _drGreen),
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
              Text('Driver Nemu', style: _md(size: 12, color: Colors.white.withOpacity(0.85))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineToggleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_isOnline ? _drGreen : Colors.grey).withOpacity(0.12),
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
                      _isOnline ? 'Kamu Online' : 'Kamu Offline',
                      style: _md(size: 14, weight: FontWeight.bold),
                    ),
                    Text(
                      _isOnline
                          ? 'Siap menerima permintaan pengantaran'
                          : 'Nyalakan buat mulai menerima pesanan',
                      style: _md(size: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              _togglingOnline
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _drGreen),
                    )
                  : Switch(
                      value: _isOnline,
                      activeColor: _drGreen,
                      onChanged: (_activeOrderDoc != null) ? null : _toggleOnline,
                    ),
            ],
          ),
          if (_activeOrderDoc != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.lock_clock_rounded, size: 14, color: _drAmber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Status online terkunci selama masih ada pesanan aktif yang kamu antar.',
                    style: _md(size: 11, color: Colors.black54, height: 1.4),
                  ),
                ),
              ],
            ),
          ] else if (_isOnline) ...[
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

  Widget _buildNoActiveDeliveryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Icon(Icons.local_shipping_outlined, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            'Belum ada pesanan yang sedang kamu antar',
            textAlign: TextAlign.center,
            style: _md(size: 13, weight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            _isOnline
                ? 'Begitu ada permintaan baru, kartunya bakal muncul di sini.'
                : 'Nyalakan status Online dulu buat mulai menerima pesanan.',
            textAlign: TextAlign.center,
            style: _md(size: 11, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = data['status'] as String? ?? OrderStatus.menujuPenjual;
    final storeName = data['storeName'] as String? ?? 'Toko';
    final marketName = data['marketName'] as String? ?? '';
    final buyerName = data['buyerName'] as String? ?? 'Pembeli';
    final items = data['items'] as String? ?? '';
    final deliveryAddress = (data['deliveryAddress'] as String?) ?? '';

    final sellerLoc = LiveLatLng.fromMap(data['sellerLocation'] as Map<String, dynamic>?);
    final buyerLiveLoc = LiveLatLng.fromMap(data['buyerLiveLocation'] as Map<String, dynamic>?);
    final myLoc = LiveLatLng.fromMap(
      (_driverData?['currentLocation'] as Map<String, dynamic>?),
    );

    final bool headingToStore = status == OrderStatus.menujuPenjual;
    final LiveLatLng? destination = headingToStore ? sellerLoc : buyerLiveLoc;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (headingToStore ? _drBlue : _drGreen).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  headingToStore ? 'Menuju Toko' : 'Menuju Pembeli',
                  style: _md(size: 10, weight: FontWeight.bold, color: headingToStore ? _drBlue : _drGreen),
                ),
              ),
              const Spacer(),
              Text(doc.id.substring(0, doc.id.length > 6 ? 6 : doc.id.length), style: _md(size: 10, color: Colors.black38)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(headingToStore ? Icons.storefront_rounded : Icons.person_rounded, size: 16, color: _drDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  headingToStore ? '$storeName${marketName.isNotEmpty ? ' • $marketName' : ''}' : buyerName,
                  style: _md(size: 13, weight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(items, style: _md(size: 11, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (!headingToStore && deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    deliveryAddress,
                    style: _md(size: 11.5, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (destination != null)
            LiveTrackingMap(
              from: myLoc,
              fromLabel: 'Kamu',
              to: destination,
              toLabel: headingToStore ? 'Toko' : 'Pembeli',
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text(
                headingToStore
                    ? 'Lokasi toko belum tersedia -- hubungi penjual manual buat alamatnya.'
                    : 'Menunggu lokasi live Pembeli...',
                style: _md(size: 11, color: Colors.black45),
              ),
            ),
          if (destination != null && myLoc != null) ...[
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final trip = _estimateTrip(myLoc, destination);
              if (trip == null) return const SizedBox.shrink();
              return Row(
                children: [
                  Expanded(
                    child: _tripStat(
                      icon: Icons.route_rounded,
                      value: '${trip.distanceKm.toStringAsFixed(1)} km',
                      label: 'Jarak',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tripStat(
                      icon: Icons.timer_outlined,
                      value: '${trip.etaMinutes} mnt',
                      label: 'Estimasi',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tripStat(
                      icon: Icons.speed_rounded,
                      value: '${_currentSpeedKmh.toStringAsFixed(0)} km/h',
                      label: 'Kecepatan',
                    ),
                  ),
                ],
              );
            }),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (destination != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openExternalNavigation(destination),
                    icon: const Icon(Icons.directions_rounded, size: 16),
                    label: Text('Petunjuk Arah', style: _md(size: 12, weight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _drGreen,
                      side: const BorderSide(color: _drGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (destination != null) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: headingToStore
                      ? (_submittingPickup ? null : _confirmPickup)
                      : (_submittingComplete ? null : _completeDeliveryWithPhoto),
                  icon: (_submittingPickup || _submittingComplete)
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(headingToStore ? Icons.inventory_2_rounded : Icons.camera_alt_rounded, size: 16),
                  label: Text(
                    headingToStore ? 'Sudah Ambil Barang' : 'Foto & Selesaikan',
                    style: _md(size: 12, weight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: headingToStore ? _drAmber : _drGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalDelivered = (_driverData?['driverDeliveries'] as num?) ?? 0;
    final rating = (_driverData?['driverRating'] as num?)?.toDouble();

    return Row(
      children: [
        Expanded(child: _statBox(icon: Icons.inventory_2_outlined, value: '$totalDelivered', label: 'Antaran Selesai')),
        const SizedBox(width: 10),
        Expanded(child: _statBox(icon: Icons.star_rounded, value: rating != null ? rating.toStringAsFixed(1) : '-', label: 'Rating')),
      ],
    );
  }

  Widget _tripStat({required IconData icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, size: 15, color: _drGreen),
          const SizedBox(height: 4),
          Text(value, style: _md(size: 12, weight: FontWeight.bold)),
          Text(label, style: _md(size: 9, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _statBox({required IconData icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
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

  Widget _buildIncomingRequestsSection() {
    if (_activeOrderDoc != null) return const SizedBox.shrink();

    final visible = _openRequests.where((d) => !_dismissedRequestIds.contains(d.id)).toList();

    if (visible.isEmpty) {
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
            const Icon(Icons.notifications_none_rounded, color: Colors.black38, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isOnline ? 'Menunggu permintaan pengantaran baru...' : 'Nyalakan status Online untuk mulai menerima permintaan',
                style: _md(size: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Permintaan Masuk', style: _md(size: 13, weight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        ...visible.map((doc) {
          final data = doc.data();
          final deliveryAddress = (data['deliveryAddress'] as String?) ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (data['storeName'] as String?) ?? 'Toko',
                        style: _md(size: 12, weight: FontWeight.bold),
                      ),
                      Text(
                        (data['items'] as String?) ?? '',
                        style: _md(size: 10.5, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (deliveryAddress.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 11, color: Colors.redAccent),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                deliveryAddress,
                                style: _md(size: 10, color: Colors.black45),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _submittingAccept ? null : () => _acceptOrder(doc),
                  child: Text('Terima', style: _md(size: 11, weight: FontWeight.bold, color: _drGreen)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Popup permintaan pengantaran baru
// ─────────────────────────────────────────────
class _IncomingRequestDialog extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onSkip;
  final VoidCallback onAccept;

  const _IncomingRequestDialog({
    required this.doc,
    required this.onSkip,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final storeName = (data['storeName'] as String?) ?? 'Toko';
    final marketName = (data['marketName'] as String?) ?? '';
    final items = (data['items'] as String?) ?? '';
    final totalPrice = (data['totalPrice'] as num?)?.toInt() ?? 0;
    // TODO: konfirmasi nama field alamat pembeli yang sebenarnya di
    // order_tracking_service.dart / skema dokumen 'orders' -- 'deliveryAddress'
    // masih tebakan mengikuti pola storeName/marketName/buyerName.
    final deliveryAddress = (data['deliveryAddress'] as String?) ?? '';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _drGreen.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.local_shipping_rounded, color: _drGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text('Permintaan Pengantaran Baru', style: _md(size: 14, weight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 14),
            Text('$storeName${marketName.isNotEmpty ? ' • $marketName' : ''}', style: _md(size: 13, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(items, style: _md(size: 11.5, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (deliveryAddress.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      deliveryAddress,
                      style: _md(size: 11, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text('Total: Rp$totalPrice', style: _md(size: 13, weight: FontWeight.bold, color: _drGreen)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black45,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Lewati', style: _md(size: 12, weight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _drGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text('Terima', style: _md(size: 12, weight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
              Text(message, textAlign: TextAlign.center, style: _md(size: 14, weight: FontWeight.w600)),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.maybePop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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