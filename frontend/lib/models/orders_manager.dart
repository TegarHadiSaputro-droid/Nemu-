import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/models/cart_model.dart';

// ─────────────────────────────────────────────
//  Status pesanan yang dipakai bersama antara
//  sisi pembeli (orders_screen.dart) dan
//  sisi penjual (seller_home_screen.dart).
// ─────────────────────────────────────────────
const String kStatusMenunggu = 'menunggu';
const String kStatusPending = 'pending';
const String kStatusMenungguKonfirmasi = 'menunggu_konfirmasi';

const String kStatusDiproses = 'diproses';
const String kStatusAccepted = 'accepted';
const String kStatusProcessing = 'processing';
const String kStatusDikemas = 'dikemas';

const String kStatusMenungguDriver = 'menunggu_driver';
const String kStatusMenujuPenjual = 'menuju_penjual';
const String kStatusDalamPengantaran = 'dalam_pengantaran';
const String kStatusDiantar = 'diantar';
const String kStatusSelesai = 'selesai';

const String kStatusDitolak = 'ditolak';
const String kStatusRejected = 'rejected';
const String kStatusDibatalkan = 'dibatalkan';

const List<String> kPendingStatuses = [
  kStatusMenunggu,
  kStatusPending,
  kStatusMenungguKonfirmasi,
];

const List<String> kProcessingStatuses = [
  kStatusDiproses,
  kStatusAccepted,
  kStatusProcessing,
  kStatusDikemas,
];

const List<String> kActiveStatuses = [
  kStatusMenunggu,
  kStatusPending,
  kStatusMenungguKonfirmasi,
  kStatusDiproses,
  kStatusAccepted,
  kStatusProcessing,
  kStatusDikemas,
  kStatusMenungguDriver,
  kStatusMenujuPenjual,
  kStatusDalamPengantaran,
  kStatusDiantar,
];

const List<String> kHistoryStatuses = [
  kStatusSelesai,
  kStatusDitolak,
  kStatusRejected,
  kStatusDibatalkan,
];

// ─────────────────────────────────────────────
//  OrdersManager — Singleton
//  Bertugas MENULIS pesanan asli ke Firestore
//  saat checkout, dan menyediakan stream untuk
//  ditampilkan di orders_screen.dart (sisi pembeli)
//  dan seller_home_screen.dart (sisi penjual).
//
//  Skema Firestore: collection('orders')
// ─────────────────────────────────────────────
class OrdersManager {
  OrdersManager._();
  static final OrdersManager instance = OrdersManager._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _db.collection('orders');

  String _generateOrderCode() {
    final rand = Random();
    final number = 1000 + rand.nextInt(9000);
    return 'ORD-$number';
  }

  /// Membuat pesanan dari isi keranjang saat ini.
  /// Mengelompokkan item per gerai (store_id / sellerId) supaya tiap
  /// seller hanya menerima order untuk produknya sendiri.
  Future<List<String>> placeOrder({
    required List<CartItem> items,
    String? catatan,
    String? alamatPengiriman,
    String? paymentMethod,
    int ongkirPerGerai = 2000,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kamu harus login terlebih dahulu untuk checkout.');
    }
    if (items.isEmpty) {
      throw Exception('Keranjang masih kosong.');
    }

    final buyerId = user.uid;
    final buyerName = user.displayName?.isNotEmpty == true
        ? user.displayName!
        : (user.email ?? 'Pembeli');

    // Kelompokkan item berdasarkan gerai (store_id / sellerId / namaGerai)
    final Map<String, List<CartItem>> grouped = {};
    for (final item in items) {
      final key = item.geraiId ?? item.sellerId ?? item.namaGerai;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final groupOrderId = _db.collection('orders').doc().id;
    final batch = _db.batch();
    final List<String> orderCodes = [];

    for (final entry in grouped.entries) {
      final groupItems = entry.value;
      final first = groupItems.first;

      final storeId = first.geraiId ?? first.sellerId ?? '';
      final sellerId = first.sellerId ?? first.geraiId ?? '';
      final marketType = first.namaMarket;
      final storeName = first.namaGerai;

      final itemsSummary = groupItems
          .map((c) => '${c.produk.nama} ${c.qty}${c.produk.satuan}')
          .join(', ');

      final itemsDetail = groupItems
          .map((c) => {
                'product_id': c.produk.id,
                'produkId': c.produk.id,
                'product_name': c.produk.nama,
                'nama': c.produk.nama,
                'satuan': c.produk.satuan,
                'quantity': c.qty,
                'qty': c.qty,
                'price': c.produk.hargaSekarang,
                'hargaSatuan': c.produk.hargaSekarang,
                'subtotal': c.subtotal,
              })
          .toList();

      final subtotalProduk =
          groupItems.fold<int>(0, (acc, c) => acc + c.subtotal);
      final totalPrice = subtotalProduk + ongkirPerGerai;

      final orderCode = _generateOrderCode();
      orderCodes.add(orderCode);

      final docRef = _ordersRef.doc();
      batch.set(docRef, {
        'orderId': docRef.id,
        'order_id': docRef.id,
        'orderCode': orderCode,
        'groupOrderId': groupOrderId,
        'buyerId': buyerId,
        'buyer_id': buyerId,
        'buyerName': buyerName,
        'buyer_name': buyerName,
        'storeId': storeId,
        'store_id': storeId,
        'sellerId': sellerId,
        'seller_id': sellerId,
        'owner_id': sellerId,
        'namaGerai': storeName,
        'store_name': storeName,
        'namaMarket': marketType,
        'market_type': marketType,
        'itemsSummary': itemsSummary,
        'items': itemsDetail,
        'subtotal': subtotalProduk,
        'subtotalProduk': subtotalProduk,
        'ongkir': ongkirPerGerai,
        'totalHarga': totalPrice,
        'totalPrice': totalPrice,
        'total_price': totalPrice,
        'alamatPengiriman': alamatPengiriman ?? '',
        'address': alamatPengiriman ?? '',
        'paymentMethod': paymentMethod ?? 'Bayar di Tempat (COD)',
        'catatan': catatan ?? '',
        'status': kStatusMenunggu, // Status awal: menunggu (menunggu konfirmasi)
        'statusLabel': 'Menunggu Konfirmasi',
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return orderCodes;
  }

  /// Stream pesanan aktif milik pembeli yang sedang login
  Stream<QuerySnapshot<Map<String, dynamic>>> activeOrdersStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _ordersRef.where('buyer_id', isEqualTo: uid).snapshots();
  }

  /// Stream riwayat pesanan milik pembeli (selesai / rejected / dibatalkan)
  Stream<QuerySnapshot<Map<String, dynamic>>> orderHistoryStream({int limit = 30}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _ordersRef.where('buyer_id', isEqualTo: uid).snapshots();
  }

  /// Stream pesanan pending untuk toko seller
  /// Mencocokkan store_id, seller_id, atau owner_id dengan storeId maupun sellerUid
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingOrdersForStoreStream(
    String storeId, {
    String? sellerUid,
  }) {
    final uid = sellerUid ?? FirebaseAuth.instance.currentUser?.uid;
    final validIds = <String>{
      if (storeId.isNotEmpty) storeId,
      if (uid != null && uid.isNotEmpty) uid,
    }.toList();

    if (validIds.isEmpty) {
      return const Stream.empty();
    }

    final filters = <Filter>[];
    for (final id in validIds) {
      filters.add(Filter('store_id', isEqualTo: id));
      filters.add(Filter('seller_id', isEqualTo: id));
      filters.add(Filter('owner_id', isEqualTo: id));
      filters.add(Filter('storeId', isEqualTo: id));
      filters.add(Filter('sellerId', isEqualTo: id));
    }

    Filter orGroup = filters.first;
    for (int i = 1; i < filters.length; i++) {
      orGroup = Filter.or(orGroup, filters[i]);
    }

    return _ordersRef
        .where(
          Filter.and(
            orGroup,
            Filter('status', whereIn: kPendingStatuses),
          ),
        )
        .snapshots();
  }

  /// Stream pesanan yang sedang diproses untuk toko seller
  Stream<QuerySnapshot<Map<String, dynamic>>> processingOrdersForStoreStream(
    String storeId, {
    String? sellerUid,
  }) {
    final uid = sellerUid ?? FirebaseAuth.instance.currentUser?.uid;
    final validIds = <String>{
      if (storeId.isNotEmpty) storeId,
      if (uid != null && uid.isNotEmpty) uid,
    }.toList();

    if (validIds.isEmpty) {
      return const Stream.empty();
    }

    final filters = <Filter>[];
    for (final id in validIds) {
      filters.add(Filter('store_id', isEqualTo: id));
      filters.add(Filter('seller_id', isEqualTo: id));
      filters.add(Filter('owner_id', isEqualTo: id));
      filters.add(Filter('storeId', isEqualTo: id));
      filters.add(Filter('sellerId', isEqualTo: id));
    }

    Filter orGroup = filters.first;
    for (int i = 1; i < filters.length; i++) {
      orGroup = Filter.or(orGroup, filters[i]);
    }

    return _ordersRef
        .where(
          Filter.and(
            orGroup,
            Filter('status', whereIn: kProcessingStatuses),
          ),
        )
        .snapshots();
  }

  /// Penjual Menerima Pesanan: update status ke 'diproses' & kirim notifikasi ke buyer inbox
  Future<void> acceptOrder(
    String orderDocId, {
    String? buyerId,
    String? storeName,
    String? orderCode,
  }) async {
    String? targetBuyerId = buyerId;
    String targetStoreName = storeName ?? 'Toko';
    String targetOrderCode = orderCode ?? '';

    if (targetBuyerId == null || targetBuyerId.isEmpty) {
      final docSnap = await _ordersRef.doc(orderDocId).get();
      if (docSnap.exists) {
        final data = docSnap.data();
        targetBuyerId = (data?['buyerId'] as String?) ??
            (data?['buyer_id'] as String?);
        targetStoreName = (data?['store_name'] as String?) ??
            (data?['namaGerai'] as String?) ??
            targetStoreName;
        targetOrderCode = (data?['orderCode'] as String?) ?? targetOrderCode;
      }
    }

    await _ordersRef.doc(orderDocId).update({
      'status': kStatusDiproses,
      'statusLabel': 'Diproses',
      'updated_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Kirim notifikasi ke inbox pembeli
    if (targetBuyerId != null && targetBuyerId.isNotEmpty) {
      try {
        await _db
            .collection('users')
            .doc(targetBuyerId)
            .collection('inbox')
            .add({
          'type': 'order_accepted',
          'title': 'Pesanan Diproses',
          'message':
              'Pesanan Anda ${targetOrderCode.isNotEmpty ? '($targetOrderCode) ' : ''}di $targetStoreName telah diterima dan sedang diproses!',
          'orderDocId': orderDocId,
          'orderId': orderDocId,
          'status': kStatusDiproses,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Jangan gagalkan update pesanan jika inbox gagal
      }
    }
  }

  /// Penjual Menolak Pesanan: update status ke 'ditolak' & kirim notifikasi ke buyer inbox
  Future<void> rejectOrder(
    String orderDocId, {
    String? buyerId,
    String? storeName,
    String? orderCode,
    String? reason,
  }) async {
    String? targetBuyerId = buyerId;
    String targetStoreName = storeName ?? 'Toko';
    String targetOrderCode = orderCode ?? '';

    if (targetBuyerId == null || targetBuyerId.isEmpty) {
      final docSnap = await _ordersRef.doc(orderDocId).get();
      if (docSnap.exists) {
        final data = docSnap.data();
        targetBuyerId = (data?['buyerId'] as String?) ??
            (data?['buyer_id'] as String?);
        targetStoreName = (data?['store_name'] as String?) ??
            (data?['namaGerai'] as String?) ??
            targetStoreName;
        targetOrderCode = (data?['orderCode'] as String?) ?? targetOrderCode;
      }
    }

    await _ordersRef.doc(orderDocId).update({
      'status': kStatusDitolak,
      'statusLabel': 'Ditolak Penjual',
      'rejectReason': reason ?? 'Pesanan tidak dapat diproses',
      'updated_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Kirim notifikasi ke inbox pembeli
    if (targetBuyerId != null && targetBuyerId.isNotEmpty) {
      try {
        await _db
            .collection('users')
            .doc(targetBuyerId)
            .collection('inbox')
            .add({
          'type': 'order_rejected',
          'title': 'Pesanan Ditolak',
          'message': reason != null && reason.isNotEmpty
              ? 'Pesanan Anda ${targetOrderCode.isNotEmpty ? '($targetOrderCode) ' : ''}di $targetStoreName ditolak: $reason'
              : 'Mohon maaf, pesanan Anda ${targetOrderCode.isNotEmpty ? '($targetOrderCode) ' : ''}di $targetStoreName tidak dapat diproses saat ini.',
          'orderDocId': orderDocId,
          'orderId': orderDocId,
          'status': kStatusDitolak,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Jangan gagalkan update pesanan jika inbox gagal
      }
    }
  }

  /// Batalkan pesanan dari sisi pembeli
  Future<void> cancelOrder(String orderDocId) async {
    await _ordersRef.doc(orderDocId).update({
      'status': kStatusDibatalkan,
      'statusLabel': 'Dibatalkan',
      'updated_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}