import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// GERAI SERVICE (Firebase)
/// Dipanggil dari daftar_gerai_form_page.dart saat user submit form
/// pendaftaran gerai — sama pola-nya dengan AuthService.register yang
/// otomatis menulis dokumen baru ke Firestore.
///
/// Dokumen baru dibuat di collection "gerai" dengan status awal
/// "menunggu_verifikasi". Field roles.seller di users/{uid} TIDAK
/// diubah di sini — itu baru dinyalakan lewat Cloud Function saat
/// admin mengubah status gerai ini menjadi "aktif".
/// ============================================================
class GeraiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Daftarkan gerai baru untuk user yang sedang login.
  /// Return: id dokumen gerai yang baru dibuat.
  static Future<String> registerGerai({
    required String namaToko,
    required String namaPasar,
    required String nomorKios,
    required bool punyaSpstb,
    String? nomorSpstb,
    List<String> fotoUrls = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kamu harus login dulu sebelum mendaftar gerai');
    }

    // Cek dulu apakah user ini sudah punya gerai yang masih berjalan
    // (belum ditolak), supaya tidak dobel daftar.
    final existing = await _firestore
        .collection('gerai')
        .where('ownerId', isEqualTo: user.uid)
        .where('status', whereIn: ['menunggu_verifikasi', 'verifikasi_admin', 'aktif'])
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Kamu sudah punya gerai yang terdaftar/sedang diverifikasi');
    }

    final docRef = _firestore.collection('gerai').doc(); // auto-generate id

    await docRef.set({
      'ownerId': user.uid,
      'namaToko': namaToko,
      'namaPasar': namaPasar,
      'nomorKios': nomorKios,
      'punyaSpstb': punyaSpstb,
      'nomorSpstb': nomorSpstb,
      'fotoUrls': fotoUrls,
      'status': 'menunggu_verifikasi', // draft -> menunggu_verifikasi -> verifikasi_admin -> aktif
      'createdAt': FieldValue.serverTimestamp(),
    });

    // [SEMENTARA / PROTOTIPE] Langsung nyalakan roles.seller begitu form
    // dikirim, tanpa nunggu verifikasi admin sungguhan.
    //
    // PENTING: kalau nanti alur verifikasi admin sudah beneran jalan
    // (lewat Cloud Function yang mendengarkan status gerai -> "aktif",
    // seperti yang sudah dibahas sebelumnya), baris update di bawah ini
    // WAJIB dihapus dari sini. Kalau tetap ada di client, siapa pun bisa
    // kasih dirinya sendiri label Penjual cuma dengan submit form, tanpa
    // pernah diperiksa siapa pun.
    await _firestore.collection('users').doc(user.uid).update({
      'roles.seller': true,
    });

    return docRef.id;
  }

  /// Ambil gerai milik user yang sedang login (kalau ada), buat dipakai
  /// di kelola_toko_page.dart untuk cek status verifikasi terkini.
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMyGerai() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kamu harus login dulu');
    }
    return _firestore
        .collection('gerai')
        .where('ownerId', isEqualTo: user.uid)
        .limit(1)
        .snapshots();
  }
}