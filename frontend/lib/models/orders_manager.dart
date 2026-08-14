import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/models/cart_model.dart';

// ─────────────────────────────────────────────
//  Status pesanan yang dipakai bersama antara
//  sisi pembeli (orders_screen.dart) dan
//  sisi penjual (seller_home_screen.dart).
// ─────────────────────────────────────────────
const String kStatusMenungguKonfirmasi = 'menunggu_konfirmasi';
const String kStatusDikemas = 'dikemas';
const String kStatusDalamPengantaran = 'dalam_pengantaran';
const String kStatusSelesai = 'selesai';
const String kStatusDibatalkan = 'dibatalkan';

const List<String> kActiveStatuses = [
  kStatusMenungguKonfirmasi,
  kStatusDikemas,
  kStatusDalamPengantaran,
];

const List<String> kHistoryStatuses = [
  kStatusSelesai,
  kStatusDibatalkan,
];

// ─────────────────────────────────────────────
//  OrdersManager — Singleton
//  Bertugas MENULIS pesanan asli ke Firestore
//  saat checkout, dan menyediakan stream untuk
//  ditampilkan di orders_screen.dart (sisi pembeli).
//
//  Skema Firestore: collection('orders')
//  Satu dokumen = satu pesanan ke SATU gerai/seller.
//  Kalau keranjang berisi produk dari beberapa gerai,
//  checkout akan memecahnya jadi beberapa dokumen
//  order sekaligus (dikelompokkan per sellerId),
//  supaya tiap seller cuma melihat order miliknya.
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
  /// Mengelompokkan item per gerai (sellerId) supaya tiap
  /// seller hanya menerima order untuk produknya sendiri.
  ///
  /// [ongkirPerGerai] adalah ongkos kirim flat per gerai (default Rp2.000
  /// sesuai info di home_screen.dart).
  ///
  /// Return: list orderCode yang berhasil dibuat.
  Future<List<String>> placeOrder({
    required List<CartItem> items,
    String? catatan,
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

    // Kelompokkan item berdasarkan gerai (sellerId + namaGerai)
    final Map<String, List<CartItem>> grouped = {};
    for (final item in items) {
      final key = item.sellerId ?? item.geraiId ?? item.namaGerai;
      grouped.putIfAbsent(key, () => []).add(item);
    }

    // groupOrderId menandai bahwa beberapa dokumen order ini
    // berasal dari satu checkout yang sama (berguna kalau nanti
    // ingin menampilkan "1 checkout, 3 gerai" di riwayat pembeli).
    final groupOrderId = _db.collection('orders').doc().id;
    final batch = _db.batch();
    final List<String> orderCodes = [];

    for (final entry in grouped.entries) {
      final groupItems = entry.value;
      final first = groupItems.first;

      final itemsSummary = groupItems
          .map((c) => '${c.produk.nama} ${c.qty}${c.produk.satuan}')
          .join(', ');

      final itemsDetail = groupItems
          .map((c) => {
                'produkId': c.produk.id,
                'nama': c.produk.nama,
                'satuan': c.produk.satuan,
                'qty': c.qty,
                'hargaSatuan': c.produk.hargaSekarang,
                'subtotal': c.subtotal,
              })
          .toList();

      final subtotalProduk =
          groupItems.fold<int>(0, (sum, c) => sum + c.subtotal);
      final totalPrice = subtotalProduk + ongkirPerGerai;

      final orderCode = _generateOrderCode();
      orderCodes.add(orderCode);

      final docRef = _ordersRef.doc();
      batch.set(docRef, {
        'orderCode': orderCode,
        'groupOrderId': groupOrderId,
        'sellerId': first.sellerId,
        'namaGerai': first.namaGerai,
        'namaMarket': first.namaMarket,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'itemsSummary': itemsSummary,
        'items': itemsDetail,
        'subtotalProduk': subtotalProduk,
        'ongkir': ongkirPerGerai,
        'totalPrice': totalPrice,
        'catatan': catatan ?? '',
        'status': kStatusMenungguKonfirmasi,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return orderCodes;
  }

  /// Stream pesanan aktif milik pembeli yang sedang login
  /// (menunggu_konfirmasi / dikemas / dalam_pengantaran).
  /// Dipakai di home_screen.dart & orders_screen.dart untuk
  /// menampilkan status pengantaran real-time.
  Stream<QuerySnapshot<Map<String, dynamic>>> activeOrdersStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _ordersRef
        .where('buyerId', isEqualTo: uid)
        .where('status', whereIn: kActiveStatuses)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream riwayat pesanan milik pembeli (selesai / dibatalkan).
  Stream<QuerySnapshot<Map<String, dynamic>>> orderHistoryStream({int limit = 30}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _ordersRef
        .where('buyerId', isEqualTo: uid)
        .where('status', whereIn: kHistoryStatuses)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Batalkan pesanan (dipakai pembeli jika masih menunggu konfirmasi).
  Future<void> cancelOrder(String orderDocId) async {
    await _ordersRef.doc(orderDocId).update({
      'status': kStatusDibatalkan,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}