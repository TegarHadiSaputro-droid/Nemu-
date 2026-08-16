// order_tracking_service.dart
//
// SATU sumber kebenaran buat alur pesanan lintas 3 role (Penjual, Pembeli,
// Driver), semuanya lewat collection Firestore `orders`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class OrderStatus {
  static const diproses = 'diproses';
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
      _db.collection('orders');

  static DocumentReference<Map<String, dynamic>> orderRef(String orderDocId) =>
      _orders.doc(orderDocId);

  // ── PENJUAL ──────────────────────────────────────────────────────

  /// Dipanggil Penjual pas tombol "Selesai Mengemas / Serahkan ke Kurir" ditekan.
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
      // GPS toko gagal diambil (izin ditolak / mati)
    }

    await orderRef(orderDocId).update({
      'status': OrderStatus.menungguDriver,
      'statusLabel': 'Mencari Driver',
      'sellerUid': _auth.currentUser?.uid,
      'storeName': storeName,
      'marketName': marketName,
      if (sellerLocation != null) 'sellerLocation': sellerLocation,
      'driverUid': null,
      'driverName': null,
      'driverLocation': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── DRIVER ───────────────────────────────────────────────────────

  /// Permintaan yang masih terbuka (belum ada driver yang ambil).
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchOpenRequests() {
    return _orders
        .where('status', isEqualTo: OrderStatus.menungguDriver)
        .snapshots();
  }

  /// Pesanan yang lagi ditangani driver yang sedang login (fase jemput ATAU antar).
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMyActiveDelivery() {
    final uid = _auth.currentUser?.uid;
    return _orders
        .where('driverUid', isEqualTo: uid)
        .where('status', whereIn: [OrderStatus.menujuPenjual, OrderStatus.diantar])
        .snapshots();
  }

  /// Driver pencet "Terima".
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
          return false;
        }
        tx.update(ref, {
          'status': OrderStatus.menujuPenjual,
          'statusLabel': 'Driver Menuju Toko',
          'driverUid': uid,
          'driverName': driverName,
          'updatedAt': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  /// Driver sampai di toko & sudah ambil barangnya
  static Future<void> confirmPickup(String orderDocId) {
    return orderRef(orderDocId).update({
      'status': OrderStatus.diantar,
      'statusLabel': 'Diantar',
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Update lokasi live driver
  static Future<void> updateDriverLocation(String orderDocId, Position pos) {
    return orderRef(orderDocId).update({
      'driverLocation': LiveLatLng(lat: pos.latitude, lng: pos.longitude).toMap(),
    }).catchError((_) {});
  }

  /// Driver selesaikan pesanan
  static Future<void> completeDelivery(
    String orderDocId,
    String proofPhotoUrl,
  ) async {
    final uid = _auth.currentUser?.uid;
    final batch = _db.batch();

    batch.update(orderRef(orderDocId), {
      'status': OrderStatus.selesai,
      'statusLabel': 'Selesai',
      'proofPhotoUrl': proofPhotoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
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

  /// Broadcast lokasi device Pembeli SELAMA status == diantar
  static Future<void> updateBuyerLiveLocation(String orderDocId, Position pos) {
    return orderRef(orderDocId).update({
      'buyerLiveLocation':
          LiveLatLng(lat: pos.latitude, lng: pos.longitude).toMap(),
    }).catchError((_) {});
  }

  // ── HELPERS ──────────────────────────────────────────────────────

  static String statusLabel(String? status) {
    switch (status) {
      case OrderStatus.diproses:
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

  static double distanceMeters(LiveLatLng a, LiveLatLng b) {
    return Geolocator.distanceBetween(a.lat, a.lng, b.lat, b.lng);
  }
}
