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

  /// Daftarkan toko baru ke Firestore.
  /// Return: store_id (document ID yang baru dibuat).
  static Future<String> createStore({
    required String ownerUid,
    required String storeName,
    required String marketSection,
    required String description,
  }) async {
    final ref = await _stores.add({
      'owner_id': ownerUid,
      'store_name': storeName,
      'market_section': marketSection,
      'description': description,
      'is_active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Update profil toko (nama toko & deskripsi).
  static Future<void> updateStore(
    String storeId, {
    required String storeName,
    required String description,
  }) async {
    await _stores.doc(storeId).update({
      'store_name': storeName,
      'description': description,
    });
  }

  /// Toggle is_active (buka / tutup toko dari sisi produk).
  static Future<void> setStoreActive(String storeId, bool isActive) async {
    await _stores.doc(storeId).update({'is_active': isActive});
  }

  // ════════════════════════════════════════════
  //  SELLER — Products
  // ════════════════════════════════════════════

  /// Stream produk milik satu toko — untuk dashboard Penjual.
  static Stream<QuerySnapshot> myProductsStream(String storeId) {
    return _products
        .where('store_id', isEqualTo: storeId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Tambah produk baru ke Firestore.
  static Future<void> addProduct({
    required String storeId,
    required String ownerUid,
    required String productName,
    required int price,
    required int stock,
    required String category, // emoji / kategori
    String imageUrl = '',
  }) async {
    await _products.add({
      'store_id': storeId,
      'owner_id': ownerUid,
      'product_name': productName,
      'price': price,
      'stock': stock,
      'category': category,
      'image_url': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update produk yang sudah ada.
  /// Penjual hanya boleh update produk miliknya sendiri (dijaga di Security Rules).
  static Future<void> updateProduct(
    String productId, {
    required String productName,
    required int price,
    required int stock,
    required String category,
  }) async {
    await _products.doc(productId).update({
      'product_name': productName,
      'price': price,
      'stock': stock,
      'category': category,
    });
  }

  /// Hapus produk dari Firestore.
  static Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  // ════════════════════════════════════════════
  //  BUYER — Streams untuk sisi Pembeli
  // ════════════════════════════════════════════

  /// Stream semua toko aktif dari Firestore, opsional difilter per pasar.
  /// Dipakai oleh GeraiScreen (sisi Pembeli) untuk menampilkan gerai real-time.
  static Stream<QuerySnapshot> allActiveStoresStream({String? marketSection}) {
    Query query = _stores.where('is_active', isEqualTo: true);
    if (marketSection != null) {
      query = query.where('market_section', isEqualTo: marketSection);
    }
    return query.orderBy('createdAt', descending: false).snapshots();
  }

  /// Stream produk satu toko untuk sisi Pembeli.
  static Stream<QuerySnapshot> storeProductsStream(String storeId) {
    return _products
        .where('store_id', isEqualTo: storeId)
        .orderBy('createdAt', descending: false)
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

  /// Format angka ke Rupiah singkat (misal 12000 → "12rb").
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
}
