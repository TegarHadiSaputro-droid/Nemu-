import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────
//  StoreService
//  Semua operasi Firestore untuk koleksi `stores` dan `products`.
//  Koleksi `stores`   → profil toko / gerai Penjual.
//  Koleksi `products` → daftar produk yang dijual per toko.
// ─────────────────────────────────────────────
class StoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Ref helpers ──────────────────────────────
  static CollectionReference get _stores => _db.collection('stores');
  static CollectionReference get _products => _db.collection('products');

  // ════════════════════════════════════════════
  //  SELLER — Store / Toko
  // ════════════════════════════════════════════

  /// Cek apakah seller (berdasarkan UID) sudah punya toko.
  /// Return: DocumentSnapshot jika ada, null jika belum terdaftar.
  static Future<DocumentSnapshot?> getMyStore(String ownerUid) async {
    final query = await _stores
        .where('owner_id', isEqualTo: ownerUid)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first;
  }

  /// Stream versi getMyStore — bereaksi real-time kalau data toko berubah.
  static Stream<QuerySnapshot> myStoreStream(String ownerUid) {
    return _stores
        .where('owner_id', isEqualTo: ownerUid)
        .limit(1)
        .snapshots();
  }

  /// Stream single store document berdasarkan storeId
  static Stream<DocumentSnapshot> storeStream(String storeId) {
    return _stores.doc(storeId).snapshots();
  }

  /// Daftarkan toko baru ke Firestore koleksi `stores/{store_id}`.
  /// Return: store_id (document ID yang baru dibuat).
  static Future<String> createStore({
    required String ownerUid,
    required String storeName,
    required String marketType,
    bool isOpen = true,
    String description = '',
  }) async {
    final ref = await _stores.add({
      'owner_id': ownerUid,
      'store_name': storeName,
      'market_type': marketType,
      'market_section': marketType, // fallback kompatibilitas
      'is_open': isOpen,
      'is_active': isOpen, // fallback kompatibilitas
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Simpan auto id ke dalam field 'store_id'
    await ref.update({'store_id': ref.id});

    // Sinkronkan juga ke dokumen seller/{uid}
    try {
      await _db.collection('seller').doc(ownerUid).set({
        'uid': ownerUid,
        'store_id': ref.id,
        'store_name': storeName,
        'market_type': marketType,
        'market_section': marketType,
        'isOpen': isOpen,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    return ref.id;
  }

  /// Update profil toko (nama toko, pasar, deskripsi, status buka).
  static Future<void> updateStore(
    String storeId, {
    required String storeName,
    String? marketType,
    required String description,
    bool? isOpen,
    String? ownerUid,
  }) async {
    final map = <String, dynamic>{
      'store_name': storeName,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (marketType != null && marketType.isNotEmpty) {
      map['market_type'] = marketType;
      map['market_section'] = marketType;
    }
    if (isOpen != null) {
      map['is_open'] = isOpen;
      map['is_active'] = isOpen;
    }
    await _stores.doc(storeId).update(map);

    final uid = ownerUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final sellerMap = <String, dynamic>{
          'store_name': storeName,
          'description': description,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (marketType != null && marketType.isNotEmpty) {
          sellerMap['market_type'] = marketType;
          sellerMap['market_section'] = marketType;
        }
        if (isOpen != null) {
          sellerMap['isOpen'] = isOpen;
        }
        await _db.collection('seller').doc(uid).set(sellerMap, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Toggle is_open (buka / tutup toko).
  static Future<void> setStoreOpenStatus(String storeId, bool isOpen, {String? ownerUid}) async {
    await _stores.doc(storeId).update({
      'is_open': isOpen,
      'is_active': isOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final uid = ownerUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.collection('seller').doc(uid).set({
          'isOpen': isOpen,
          'isOpenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ════════════════════════════════════════════
  //  SELLER — Products
  // ════════════════════════════════════════════

  /// Stream produk milik satu toko — untuk dashboard Penjual.
  static Stream<QuerySnapshot> myProductsStream(String storeId) {
    return _products
        .where('store_id', isEqualTo: storeId)
        .snapshots();
  }

  /// Tambah produk baru ke Firestore koleksi `products`.
  static Future<String> addProduct({
    required String storeId,
    required String ownerUid,
    required String marketType,
    required String productName,
    required int price,
    required int stock,
    required String category, // emoji / kategori
    String imageUrl = '',
  }) async {
    final ref = await _products.add({
      'store_id': storeId,
      'owner_id': ownerUid,
      'market_type': marketType,
      'product_name': productName,
      'price': price,
      'stock': stock,
      'category': category,
      'image_url': imageUrl,
      'created_at': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await ref.update({'product_id': ref.id});
    return ref.id;
  }

  /// Update produk yang sudah ada.
  static Future<void> updateProduct(
    String productId, {
    required String productName,
    required int price,
    required int stock,
    required String category,
    String? marketType,
    String? imageUrl,
  }) async {
    final map = <String, dynamic>{
      'product_name': productName,
      'price': price,
      'stock': stock,
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (marketType != null && marketType.isNotEmpty) {
      map['market_type'] = marketType;
    }
    if (imageUrl != null) {
      map['image_url'] = imageUrl;
    }
    await _products.doc(productId).update(map);
  }

  /// Hapus produk dari Firestore.
  static Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  // ════════════════════════════════════════════
  //  BUYER — Streams untuk sisi Pembeli
  // ════════════════════════════════════════════

  /// Stream semua toko aktif dari Firestore.
  /// Dipakai oleh GeraiScreen (sisi Pembeli) untuk menampilkan gerai real-time.
  ///
  /// CATATAN: sengaja TIDAK difilter `market_type` di sisi server (Firestore
  /// `isEqualTo` itu case-sensitive & whitespace-sensitive, jadi gampang
  /// meleset kalau field `market_type` yang ditulis penjual beda dikit dari
  /// nama pasar yang dipakai di sisi pembeli -- toko real jadi "hilang"
  /// tanpa error apa pun). Pencocokan per-pasar dilakukan di caller
  /// (GeraiScreen) secara ternormalisasi -- lihat `matchesMarket` di bawah.
  static Stream<QuerySnapshot> allActiveStoresStream({String? marketType}) {
    return _stores.snapshots();
  }

  /// Cek apakah sebuah dokumen toko cocok dengan pasar tertentu.
  /// Dibandingkan ternormalisasi (trim + lowercase) terhadap nama ATAU id
  /// pasar, dan terhadap field `market_type` maupun `market_section`
  /// (keduanya ditulis saat createStore/updateStore).
  static bool matchesMarket(
    Map<String, dynamic> data, {
    required String marketId,
    required String marketNama,
  }) {
    String norm(String? s) => (s ?? '').trim().toLowerCase();

    final storeMarketType = norm(data['market_type'] as String?);
    final storeMarketSection = norm(data['market_section'] as String?);
    final targetId = norm(marketId);
    final targetNama = norm(marketNama);

    if (storeMarketType.isEmpty && storeMarketSection.isEmpty) return false;

    return storeMarketType == targetId ||
        storeMarketType == targetNama ||
        storeMarketSection == targetId ||
        storeMarketSection == targetNama;
  }

  /// Stream produk satu toko untuk sisi Pembeli.
  static Stream<QuerySnapshot> storeProductsStream(String storeId) {
    return _products
        .where('store_id', isEqualTo: storeId)
        .snapshots();
  }

  /// Stream semua produk berdasarkan pasar pilihan pembeli.
  static Stream<QuerySnapshot> productsByMarketStream(String marketType) {
    return _products
        .where('market_type', isEqualTo: marketType)
        .snapshots();
  }

  // ════════════════════════════════════════════
  //  UTILITY
  // ════════════════════════════════════════════

  /// UID user yang sedang login. Throw jika belum login.
  static String get currentUid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Tidak ada user yang sedang login');
    return uid;
  }

  /// Format angka ke Rupiah singkat (misal 12000 → "12rb" atau "Rp 12.000").
  static String formatRupiah(int value) {
    if (value >= 1000000) {
      final juta = value / 1000000;
      return 'Rp${juta == juta.truncateToDouble() ? '${juta.toInt()}jt' : '${juta.toStringAsFixed(1)}jt'}';
    } else if (value >= 1000) {
      final ribu = value / 1000;
      return 'Rp${ribu == ribu.truncateToDouble() ? '${ribu.toInt()}rb' : '${ribu.toStringAsFixed(0)}rb'}';
    }
    return 'Rp$value';
  }

  /// Format angka Rupiah lengkap (contoh: Rp 15.000)
  static String formatRupiahFull(int value) {
    final s = value.toString().split('').reversed.join();
    final groups = <String>[];
    for (var i = 0; i < s.length; i += 3) {
      groups.add(s.substring(i, i + 3 > s.length ? s.length : i + 3));
    }
    return 'Rp ${groups.join('.').split('').reversed.join()}';
  }
}