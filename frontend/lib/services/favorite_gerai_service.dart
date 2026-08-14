// favorite_gerai_service.dart
//
// Service untuk fitur "Simpan Gerai" (bookmark) — realtime via Firestore.
// Path penyimpanan: users/{uid}/favoritGerai/{geraiId}
//
// Dipakai di:
//  - gerai_screen.dart      -> tombol bookmark di tiap kartu gerai
//  - home_screen.dart       -> section "Gerai Tersimpan" di beranda pembeli
//  - favorite_gerai_page.dart -> halaman "Favorit Saya" di Akun
//
// Karena ketiganya membaca/menulis koleksi Firestore yang sama, perubahan
// di satu tempat otomatis tersinkron real-time ke tempat lainnya.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/models/cart_model.dart' show PasarGerai;

// ─────────────────────────────────────────────
//  Model data gerai favorit (hasil baca dari Firestore)
// ─────────────────────────────────────────────
class FavoriteGerai {
  final String geraiId;
  final String namaGerai;
  final String deskripsi;
  final String emoji;
  final double rating;
  final int ulasan;
  final String? marketId;
  final String? namaMarket;
  final String? sellerId;

  const FavoriteGerai({
    required this.geraiId,
    required this.namaGerai,
    required this.deskripsi,
    required this.emoji,
    required this.rating,
    required this.ulasan,
    this.marketId,
    this.namaMarket,
    this.sellerId,
  });

  factory FavoriteGerai.fromMap(Map<String, dynamic> m) => FavoriteGerai(
        geraiId: (m['geraiId'] as String?) ?? '',
        namaGerai: (m['namaGerai'] as String?) ?? '',
        deskripsi: (m['deskripsi'] as String?) ?? '',
        emoji: (m['emoji'] as String?) ?? '🏪',
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        ulasan: (m['ulasan'] as num?)?.toInt() ?? 0,
        marketId: m['marketId'] as String?,
        namaMarket: m['namaMarket'] as String?,
        sellerId: m['sellerId'] as String?,
      );
}

// ─────────────────────────────────────────────
//  Service Singleton
// ─────────────────────────────────────────────
class FavoriteGeraiService {
  FavoriteGeraiService._();
  static final FavoriteGeraiService instance = FavoriteGeraiService._();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _ref {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favoritGerai');
  }

  /// Stream berisi HANYA id gerai yang tersimpan — dipakai di kartu gerai
  /// (gerai_screen.dart) supaya efisien saat cek status bookmark per item.
  Stream<Set<String>> streamFavoriteIds() {
    final ref = _ref;
    if (ref == null) return Stream.value(<String>{});
    return ref.snapshots().map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  /// Stream berisi data gerai favorit LENGKAP, diurutkan dari yang paling
  /// baru disimpan. Dipakai di beranda pembeli & halaman "Favorit Saya".
  Stream<List<FavoriteGerai>> streamFavorites() {
    final ref = _ref;
    if (ref == null) return Stream.value(const []);
    return ref.orderBy('savedAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => FavoriteGerai.fromMap(d.data()))
              .toList(),
        );
  }

  /// Cek sekali (non-stream) apakah sebuah gerai sudah tersimpan.
  Future<bool> isSaved(String geraiId) async {
    final ref = _ref;
    if (ref == null) return false;
    final doc = await ref.doc(geraiId).get();
    return doc.exists;
  }

  /// Simpan / batal simpan sebuah gerai (toggle).
  /// Kalau user belum login, tidak melakukan apa-apa (silent no-op).
  Future<void> toggle({
    required PasarGerai gerai,
    String? marketId,
    String? namaMarket,
  }) async {
    final ref = _ref;
    if (ref == null) return;

    final doc = ref.doc(gerai.id);
    final existing = await doc.get();

    if (existing.exists) {
      await doc.delete();
    } else {
      await doc.set({
        'geraiId': gerai.id,
        'namaGerai': gerai.nama,
        'deskripsi': gerai.deskripsi,
        'emoji': gerai.emoji,
        'rating': gerai.rating,
        'ulasan': gerai.ulasan,
        'marketId': marketId,
        'namaMarket': namaMarket,
        'sellerId': gerai.sellerId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Hapus gerai favorit langsung lewat id-nya (dipakai tombol hapus cepat
  /// di beranda / halaman favorit, tanpa perlu objek PasarGerai lengkap).
  Future<void> remove(String geraiId) async {
    final ref = _ref;
    if (ref == null) return;
    await ref.doc(geraiId).delete();
  }
}