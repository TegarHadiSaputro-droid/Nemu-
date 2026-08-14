// order_tracking_service.dart
//
// SATU sumber kebenaran buat alur pesanan lintas 3 role (Penjual, Pembeli,
// Driver), semuanya lewat collection Firestore `simulated_orders` yang
// SUDAH dipakai seller_home_screen.dart & orders_screen.dart (doc id ==
// uid Pembeli, pola yang sudah ada -- jadi satu Pembeli = satu pesanan
// aktif dalam prototipe ini).
//
// STATE MACHINE status pesanan:
//
//   dikemas           Penjual sedang mengemas.                     (sudah ada)
//   menunggu_driver    Penjual selesai mengemas, sistem cari driver. (BARU)
//   menuju_penjual     Driver sudah "Terima", otw jemput ke Penjual. (BARU)
//   diantar            Driver sudah ambil barang, otw ke Pembeli.    (BARU, gantiin 'dalam_pengantaran')
//   selesai            Driver sudah antar + upload foto bukti.       (sudah ada)
//
// Field lain yang dipakai/ditulis di sepanjang alur:
//   buyerUid, buyerName
//   sellerUid, storeName, marketName, sellerLocation {lat,lng}
//   driverUid, driverName
//   driverLocation      {lat,lng,updatedAt}  -- ditulis Driver selama online & pegang order ini
//   buyerLiveLocation   {lat,lng,updatedAt}  -- ditulis Pembeli selama status == diantar
//   proofPhotoUrl
//
// CATATAN INDEX: watchMyActiveDelivery() melakukan query gabungan
// (driverUid == X DAN status whereIn [...]) -- pertama kali dijalankan
// Firestore kemungkinan minta bikin composite index otomatis (klik link
// di error log-nya sekali, jadi dalam beberapa menit).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class OrderStatus {
  static const dikemas = 'dikemas';
  static const menungguDriver = 'menunggu_driver';
  static const menujuPenjual = 'menuju_penjual';
  static const diantar = 'diantar';
  static const selesai = 'selesai';
}

/// Titik koordinat ringan buat baca field lokasi dari Firestore (driver,
/// toko, atau device pembeli). Dipakai bareng oleh live_tracking_map.dart.
class LiveLatLng {
  final double lat;
  final double lng;
  final int? updatedAtMs;

  const LiveLatLng({required this.lat, required this.lng, this.updatedAtMs});

  static LiveLatLng? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final lat = (map['lat'] as num?)?.toDouble();
    final lng = (map['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LiveLatLng(
      lat: lat,
      lng: lng,
      updatedAtMs: (map['updatedAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

  /// Umur data lokasi ini, buat nampilin "diperbarui X detik lalu" atau
  /// nge-warn kalau GPS driver/pembeli kelihatan berhenti update.
  Duration? age() {
    if (updatedAtMs == null) return null;
    return Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch - updatedAtMs!,
    );
  }
}

class OrderTrackingService {
  OrderTrackingService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('simulated_orders');

  static DocumentReference<Map<String, dynamic>> orderRef(String orderDocId) =>
      _orders.doc(orderDocId);

  // ── PENJUAL ──────────────────────────────────────────────────────

  /// Dipanggil Penjual pas tombol "Selesai Mengemas / Serahkan ke Kurir"
  /// ditekan. Order dilepas ke kolam "menunggu_driver" supaya driver yang
  /// online bisa lihat & ambil. Sekalian nyimpen lokasi toko (best-effort
  /// -- kalau gagal ambil GPS, tetap lanjut, jangan blokir Penjual).
  static Future<void> markReadyForDriver({
    required String orderDocId,
    required String storeName,
    required String marketName,
  }) async {
    Map<String, dynamic>? sellerLocation;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      sellerLocation = {'lat': pos.latitude, 'lng': pos.longitude};
    } catch (_) {
      // GPS toko gagal diambil (izin ditolak / mati) -- driver tetap bisa
      // jalan dengan nama toko & pasar sebagai penunjuk kasar.
    }

    await orderRef(orderDocId).update({
      'status': OrderStatus.menungguDriver,
      'sellerUid': _auth.currentUser?.uid,
      'storeName': storeName,
      'marketName': marketName,
      if (sellerLocation != null) 'sellerLocation': sellerLocation,
      'driverUid': null,
      'driverName': null,
      'driverLocation': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── DRIVER ───────────────────────────────────────────────────────

  /// Permintaan yang masih terbuka (belum ada driver yang ambil).
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchOpenRequests() {
    return _orders
        .where('status', isEqualTo: OrderStatus.menungguDriver)
        .snapshots();
  }

  /// Pesanan yang lagi ditangani driver yang sedang login (fase jemput ATAU
  /// antar). Dipakai buat kartu "Pesanan Aktif" di dashboard driver.
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMyActiveDelivery() {
    final uid = _auth.currentUser?.uid;
    return _orders
        .where('driverUid', isEqualTo: uid)
        .where('status', whereIn: [OrderStatus.menujuPenjual, OrderStatus.diantar])
        .snapshots();
  }

  /// Driver pencet "Terima". Pakai transaksi supaya kalau 2 driver online
  /// pencet hampir bersamaan, cuma satu yang berhasil klaim order-nya.
  static Future<bool> acceptOrder(
    String orderDocId, {
    required String driverName,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final ref = orderRef(orderDocId);
    try {
      return await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) return false;
        if (data['status'] != OrderStatus.menungguDriver ||
            data['driverUid'] != null) {
          return false; // sudah diambil driver lain / dibatalkan
        }
        tx.update(ref, {
          'status': OrderStatus.menujuPenjual,
          'driverUid': uid,
          'driverName': driverName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  /// Driver sampai di toko & sudah ambil barangnya -> mulai fase antar ke
  /// Pembeli. Ini titik yang bikin orders_screen.dart Pembeli berubah jadi
  /// "Barang segera diantarkan".
  static Future<void> confirmPickup(String orderDocId) {
    return orderRef(orderDocId).update({
      'status': OrderStatus.diantar,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Dipanggil berkala dari location stream Driver (di-throttle di sisi
  /// caller, mis. tiap ~5 detik) selama status online & pegang order aktif.
  static Future<void> updateDriverLocation(String orderDocId, Position pos) {
    return orderRef(orderDocId).update({
      'driverLocation': LiveLatLng(lat: pos.latitude, lng: pos.longitude).toMap(),
    }).catchError((_) {});
  }

  /// Driver akhiri pesanan setelah foto bukti sudah selesai diupload ke
  /// Storage (URL-nya dikirim di sini) + nambah statistik antaran driver.
  static Future<void> completeDelivery(
    String orderDocId,
    String proofPhotoUrl,
  ) async {
    final uid = _auth.currentUser?.uid;
    final batch = _db.batch();

    batch.update(orderRef(orderDocId), {
      'status': OrderStatus.selesai,
      'proofPhotoUrl': proofPhotoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (uid != null) {
      batch.set(
        _db.collection('users').doc(uid),
        {'driverDeliveries': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  // ── PEMBELI ──────────────────────────────────────────────────────

  /// Broadcast lokasi device Pembeli SELAMA status == diantar, supaya
  /// Driver bisa lacak posisi Pembeli buat antar yang akurat. Caller
  /// (orders_screen.dart) yang bertanggung jawab start/stop stream ini
  /// tepat saat status berubah.
  static Future<void> updateBuyerLiveLocation(String orderDocId, Position pos) {
    return orderRef(orderDocId).update({
      'buyerLiveLocation':
          LiveLatLng(lat: pos.latitude, lng: pos.longitude).toMap(),
    }).catchError((_) {});
  }

  // ── HELPERS ──────────────────────────────────────────────────────

  /// Label + warna buat status pesanan, dipakai bareng oleh ketiga role
  /// supaya teksnya konsisten di mana-mana.
  static String statusLabel(String? status) {
    switch (status) {
      case OrderStatus.dikemas:
        return 'Diproses';
      case OrderStatus.menungguDriver:
        return 'Menunggu Driver';
      case OrderStatus.menujuPenjual:
        return 'Driver Menuju Toko';
      case OrderStatus.diantar:
        return 'Barang Segera Diantarkan';
      case OrderStatus.selesai:
        return 'Selesai';
      default:
        return 'Diproses';
    }
  }

  /// Jarak garis lurus (bukan rute jalan asli -- nggak ada Directions API
  /// di prototipe ini) buat teks kasar "± X km lagi".
  static double distanceMeters(LiveLatLng a, LiveLatLng b) {
    return Geolocator.distanceBetween(a.lat, a.lng, b.lat, b.lng);
  }
}
