// order_tracking_service.dart
//
// SATU sumber kebenaran buat alur pesanan lintas 3 role (Penjual, Pembeli,
// Driver), semuanya lewat collection Firestore `orders`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 2),
        ),
      ).timeout(const Duration(seconds: 2));
      sellerLocation = {'lat': pos.latitude, 'lng': pos.longitude};
    } catch (_) {
      // GPS toko fallback jika tidak tersedia / dimatikan
    }

    // Baca dokumen order terlebih dahulu agar bisa menyalin deliveryAddress,
    // buyerName, dan items ke dalam field yang dibaca sisi Driver.
    final existingSnap = await _orders.doc(orderDocId).get();
    final existing = existingSnap.data() ?? {};

    final deliveryAddress = (existing['alamatPengiriman'] as String?) ??
        (existing['address'] as String?) ??
        (existing['deliveryAddress'] as String?) ??
        '';
    final buyerName = (existing['buyerName'] as String?) ??
        (existing['buyer_name'] as String?) ??
        'Pembeli';
    final itemsDetail = existing['items'];
    final itemsSummary = (existing['itemsSummary'] as String?) ?? '';
    // Buat string ringkas untuk ditampilkan di card driver
    final itemsString = itemsSummary.isNotEmpty
        ? itemsSummary
        : (itemsDetail is List && itemsDetail.isNotEmpty
            ? itemsDetail
                .take(3)
                .map((e) {
                  final m = e as Map<String, dynamic>?;
                  if (m == null) return '';
                  final name = (m['product_name'] as String?) ?? (m['nama'] as String?) ?? '';
                  final qty = (m['quantity'] as num?)?.toInt() ?? (m['qty'] as num?)?.toInt() ?? 0;
                  return '$name x$qty';
                })
                .where((s) => s.isNotEmpty)
                .join(', ')
            : '');
    final totalPrice = (existing['totalHarga'] as num?)?.toInt() ??
        (existing['totalPrice'] as num?)?.toInt() ??
        (existing['total_price'] as num?)?.toInt() ?? 0;
    final sellerId = (existing['sellerId'] as String?) ??
        (existing['seller_id'] as String?) ??
        _auth.currentUser?.uid ?? '';

    await orderRef(orderDocId).update({
      'status': OrderStatus.menungguDriver,
      'statusLabel': 'Mencari Driver',
      'sellerUid': _auth.currentUser?.uid,
      'storeName': storeName,
      'marketName': marketName,
      // Salin data order ke field yang dibaca sisi Driver
      'deliveryAddress': deliveryAddress,
      'buyerName': buyerName,
      'items': itemsString,
      'totalPrice': totalPrice,
      'sellerId': sellerId,
      if (sellerLocation != null) 'sellerLocation': sellerLocation,
      'driverUid': null,
      'driverName': null,
      'driverLocation': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Kirim notifikasi ke inbox pembeli
    final buyerId = (existing['buyerId'] as String?) ?? (existing['buyer_id'] as String?);
    final orderCode = (existing['orderCode'] as String?) ?? orderDocId;
    if (buyerId != null && buyerId.isNotEmpty) {
      try {
        await _db
            .collection('users')
            .doc(buyerId)
            .collection('inbox')
            .add({
          'type': 'order_update',
          'title': 'Pesanan Siap Diantar 🛵',
          'message': 'Pesanan $orderCode dari $storeName sudah selesai dikemas dan siap dijemput oleh driver.',
          'orderId': orderDocId,
          'orderCode': orderCode,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  // ── DRIVER ───────────────────────────────────────────────────────

  /// Permintaan yang masih terbuka (status: menunggu_driver).
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchOpenRequests() {
    return _orders.snapshots();
  }

  /// Pesanan yang lagi ditangani driver yang sedang login (fase jemput ATAU antar).
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMyActiveDelivery() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _orders
        .where('driverUid', isEqualTo: uid)
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
      final snap = await ref.get();
      final data = snap.data();
      if (data == null) return false;

      // Jika sudah ada driver lain yang mengambil pesanan ini
      final existingDriver = data['driverUid'] as String?;
      if (existingDriver != null && existingDriver.isNotEmpty && existingDriver != uid) {
        return false;
      }

      await ref.update({
        'status': OrderStatus.menujuPenjual,
        'statusLabel': 'Driver Menuju Toko',
        'driverUid': uid,
        'driverName': driverName.isNotEmpty ? driverName : 'Driver',
        'updatedAt': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update lokasi driver
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 2),
          ),
        ).timeout(const Duration(seconds: 2));
        await ref.update({
          'driverLocation': LiveLatLng(lat: pos.latitude, lng: pos.longitude).toMap(),
        });
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Error acceptOrder: $e');
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
    String? proofPhotoUrl,
  ) async {
    final uid = _auth.currentUser?.uid;
    final batch = _db.batch();

    // Baca order untuk ambil info pembeli & kode
    final orderSnap = await _orders.doc(orderDocId).get();
    final orderData = orderSnap.data() ?? {};
    final buyerId = (orderData['buyerId'] as String?) ?? (orderData['buyer_id'] as String?);
    final orderCode = (orderData['orderCode'] as String?) ?? orderDocId;
    final storeName = (orderData['storeName'] as String?) ?? 'Toko';

    final updateData = <String, dynamic>{
      'status': OrderStatus.selesai,
      'statusLabel': 'Selesai',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (proofPhotoUrl != null) {
      updateData['proofPhotoUrl'] = proofPhotoUrl;
    }

    batch.update(orderRef(orderDocId), updateData);

    if (uid != null) {
      batch.set(
        _db.collection('users').doc(uid),
        {'driverDeliveries': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    }

    // Kirim notifikasi ke inbox pembeli bahwa pesanan sudah terkirim
    if (buyerId != null && buyerId.isNotEmpty) {
      final inboxRef = _db
          .collection('users')
          .doc(buyerId)
          .collection('inbox')
          .doc();
      batch.set(inboxRef, {
        'type': 'order_delivered',
        'title': 'Pesanan Terkirim! 🎉',
        'message': 'Pesanan $orderCode dari $storeName telah diantar dan diselesaikan oleh driver. '
            'Terima kasih sudah belanja di Nemu!',
        'orderId': orderDocId,
        'orderCode': orderCode,
        if (proofPhotoUrl != null) 'proofPhotoUrl': proofPhotoUrl,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
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
