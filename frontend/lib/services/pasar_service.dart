import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────
//  Model: StoreData (dari Firestore)
// ─────────────────────────────────────────────
class StoreData {
  final String storeId;
  final String ownerId;
  final String storeName;
  final String marketSection;
  final String description;
  final String emoji;
  final bool isActive;

  const StoreData({
    required this.storeId,
    required this.ownerId,
    required this.storeName,
    required this.marketSection,
    required this.description,
    required this.emoji,
    required this.isActive,
  });

  factory StoreData.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StoreData(
      storeId: doc.id,
      ownerId: d['owner_id'] as String? ?? '',
      storeName: d['store_name'] as String? ?? 'Toko Saya',
      marketSection: d['market_section'] as String? ?? '',
      description: d['description'] as String? ?? '',
      emoji: d['emoji'] as String? ?? '🏪',
      isActive: d['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'owner_id': ownerId,
    'store_name': storeName,
    'market_section': marketSection,
    'description': description,
    'emoji': emoji,
    'is_active': isActive,
  };
}

// ─────────────────────────────────────────────
//  Model: ProductData (dari Firestore)
// ─────────────────────────────────────────────
class ProductData {
  final String productId;
  final String storeId;
  final String ownerId;
  final String productName;
  final String emoji;
  final int price;
  final int priceYesterday;
  final int stock;
  final String unit;
  final String category;
  final String imageUrl;

  const ProductData({
    required this.productId,
    required this.storeId,
    required this.ownerId,
    required this.productName,
    required this.emoji,
    required this.price,
    required this.priceYesterday,
    required this.stock,
    required this.unit,
    required this.category,
    required this.imageUrl,
  });

  factory ProductData.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductData(
      productId: doc.id,
      storeId: d['store_id'] as String? ?? '',
      ownerId: d['owner_id'] as String? ?? '',
      productName: d['product_name'] as String? ?? '',
      emoji: d['emoji'] as String? ?? '🛒',
      price: (d['price'] as num?)?.toInt() ?? 0,
      priceYesterday: (d['price_yesterday'] as num?)?.toInt() ?? 0,
      stock: (d['stock'] as num?)?.toInt() ?? 0,
      unit: d['unit'] as String? ?? 'per kg',
      category: d['category'] as String? ?? 'Umum',
      imageUrl: d['image_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'store_id': storeId,
    'owner_id': ownerId,
    'product_name': productName,
    'emoji': emoji,
    'price': price,
    'price_yesterday': priceYesterday,
    'stock': stock,
    'unit': unit,
    'category': category,
    'image_url': imageUrl,
  };
}

// ─────────────────────────────────────────────
//  PasarService — Semua operasi Firestore Pasar
// ─────────────────────────────────────────────
class PasarService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ── Pilihan Sektor Pasar (untuk Dropdown) ──
  static const List<String> marketSections = [
    'Pasar Sepinggan',
    'Pasar Klandasan',
    'Pasar Pandansari',
    'Pasar Buton',
    'Pasar Lainnya',
  ];

  // ──────────────────────────────────────────
  //  STORE OPERATIONS
  // ──────────────────────────────────────────

  /// Daftarkan toko baru untuk penjual yang sedang login.
  /// Mengembalikan ID toko yang baru dibuat.
  static Future<String> registerStore({
    required String storeName,
    required String marketSection,
    required String description,
    String emoji = '🏪',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Tidak ada user yang sedang login');

    final docRef = await _db.collection('stores').add({
      'owner_id': uid,
      'store_name': storeName.trim(),
      'market_section': marketSection,
      'description': description.trim(),
      'emoji': emoji.trim().isEmpty ? '🏪' : emoji.trim(),
      'is_active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Update nama toko & deskripsi.
  static Future<void> updateStore({
    required String storeId,
    required String storeName,
    required String description,
    String? emoji,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Tidak ada user yang sedang login');

    final update = <String, dynamic>{
      'store_name': storeName.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (emoji != null && emoji.trim().isNotEmpty) {
      update['emoji'] = emoji.trim();
    }

    await _db.collection('stores').doc(storeId).update(update);
  }

  /// Stream dokumen toko milik user yang sedang login.
  /// Mengembalikan null jika toko belum ada.
  static Stream<StoreData?> streamMyStore() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _db
        .collection('stores')
        .where('owner_id', isEqualTo: uid)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return StoreData.fromFirestore(snap.docs.first);
    });
  }

  /// Stream seluruh toko aktif (untuk sisi Pembeli).
  static Stream<List<StoreData>> streamAllActiveStores() {
    return _db
        .collection('stores')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(StoreData.fromFirestore).toList());
  }

  /// Stream toko aktif untuk sektor pasar tertentu (untuk GeraiScreen Pembeli).
  static Stream<List<StoreData>> streamStoresByMarket(String marketSection) {
    return _db
        .collection('stores')
        .where('is_active', isEqualTo: true)
        .where('market_section', isEqualTo: marketSection)
        .snapshots()
        .map((snap) => snap.docs.map(StoreData.fromFirestore).toList());
  }

  // ──────────────────────────────────────────
  //  PRODUCT OPERATIONS
  // ──────────────────────────────────────────

  /// Tambah produk baru ke toko.
  static Future<void> addProduct({
    required String storeId,
    required String productName,
    required String emoji,
    required int price,
    required int stock,
    required String unit,
    String category = 'Umum',
    String imageUrl = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Tidak ada user yang sedang login');

    await _db
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .add({
      'store_id': storeId,
      'owner_id': uid,
      'product_name': productName.trim(),
      'emoji': emoji.trim().isEmpty ? '🛒' : emoji.trim(),
      'price': price,
      'price_yesterday': price,
      'stock': stock,
      'unit': unit.trim(),
      'category': category,
      'image_url': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update produk yang sudah ada.
  static Future<void> updateProduct({
    required String storeId,
    required String productId,
    required String productName,
    required String emoji,
    required int price,
    required int stock,
    required String unit,
    String category = 'Umum',
  }) async {
    await _db
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .doc(productId)
        .update({
      'product_name': productName.trim(),
      'emoji': emoji.trim().isEmpty ? '🛒' : emoji.trim(),
      'price': price,
      'stock': stock,
      'unit': unit.trim(),
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hapus produk dari toko.
  static Future<void> deleteProduct({
    required String storeId,
    required String productId,
  }) async {
    await _db
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .doc(productId)
        .delete();
  }

  /// Stream semua produk untuk satu toko (real-time).
  static Stream<List<ProductData>> streamStoreProducts(String storeId) {
    return _db
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ProductData.fromFirestore).toList());
  }
}
