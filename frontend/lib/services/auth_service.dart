import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// AUTH SERVICE (Firebase)
/// Menggantikan versi lama yang manggil backend PHP di Laragon.
/// - Login/registrasi pakai Firebase Authentication
/// - Nama & nomor telepon disimpan di Cloud Firestore, koleksi "users",
///   karena Firebase Auth secara default cuma nyimpen email & password.
/// - Verifikasi email pakai fitur bawaan Firebase (sendEmailVerification).
/// ============================================================
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registrasi akun baru + simpan profil ke Firestore + kirim email verifikasi.
  static Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // Cek dulu apakah nomor telepon sudah dipakai orang lain, karena
    // Firebase Auth (mode email/password) tidak otomatis mengecek ini
    // seperti dia mengecek keunikan email.
    final phoneCheck = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (phoneCheck.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'phone-already-in-use',
        message: 'Nomor telepon sudah terdaftar',
      );
    }

    // Buat akun di Firebase Auth (otomatis menolak kalau email sudah dipakai)
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    // Set nama di profil Firebase Auth
    await user.updateDisplayName(name);

    // Simpan data tambahan (nama, telepon) ke Firestore.
    // Setiap akun baru otomatis berlabel "Pembeli" (roles.buyer = true).
    // Label "Penjual" (roles.seller) baru diaktifkan lewat
    // AuthService.activateSellerRole(), dipanggil setelah form
    // pendaftaran gerai di Nemu+ berhasil dikirim.
    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'roles': {
        'buyer': true,
        'seller': false,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Kirim email verifikasi
    await user.sendEmailVerification();

    return user;
  }

  /// Login. Menolak (sign out otomatis) kalau email belum diverifikasi.
  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    // Refresh status verifikasi terbaru dari server Firebase
    await user.reload();
    final refreshedUser = _auth.currentUser!;

    if (!refreshedUser.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Email belum diverifikasi. Silakan cek inbox/spam email kamu.',
      );
    }

    return refreshedUser;
  }

  /// Kirim ulang email reset password.
  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Kirim ulang email verifikasi. Perlu login sementara dulu untuk tahu
  /// siapa user-nya, karena Firebase butuh objek User yang aktif untuk
  /// mengirim ulang — bukan cuma alamat emailnya saja.
  static Future<void> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.reload();

    if (_auth.currentUser!.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'already-verified',
        message: 'Email kamu sudah terverifikasi. Silakan login seperti biasa.',
      );
    }

    await user.sendEmailVerification();
    await _auth.signOut(); // sign out lagi karena belum boleh login sebelum verified
  }

  /// Aktifkan label "Penjual" (roles.seller) + buat dokumen di koleksi
  /// top-level "seller" (setara dengan koleksi "users", satu dokumen per
  /// user, id dokumen = uid). Dipanggil sekali setelah form pendaftaran
  /// gerai di Nemu+ (daftar_gerai_form_page.dart) berhasil dikirim.
  ///
  /// [geraiData] adalah data gerai dari form (nama pasar, nomor kios,
  /// status SPSTB, dst) yang mau ikut disimpan di dokumen seller-nya.
  ///
  /// Dua operasi (update roles.seller & buat dokumen seller) digabung
  /// dalam satu WriteBatch supaya atomik — kalau salah satu gagal,
  /// dua-duanya gagal, jadi tidak ada kondisi setengah-jadi (roles.seller
  /// true tapi dokumen seller-nya tidak ada, atau sebaliknya).
  static Future<void> registerAsSeller({
    required Map<String, dynamic> geraiData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Tidak ada user yang sedang login',
      );
    }

    // Ambil data profil dasar (nama, email, telepon) dari koleksi "users"
    // supaya dokumen seller konsisten dengan data akun buyer-nya, tidak
    // perlu diketik ulang di form gerai.
    final userSnapshot = await _firestore.collection('users').doc(user.uid).get();
    final userData = userSnapshot.data() ?? {};

    final batch = _firestore.batch();

    final userRef = _firestore.collection('users').doc(user.uid);
    batch.update(userRef, {'roles.seller': true});

    final sellerRef = _firestore.collection('seller').doc(user.uid);
    batch.set(sellerRef, {
      'uid': user.uid,
      'name': userData['name'] ?? user.displayName,
      'email': userData['email'] ?? user.email,
      'phone': userData['phone'],
      ...geraiData,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Nonaktifkan kembali label "Penjual", misalnya kalau gerai ditutup
  /// atau ditolak admin. Dokumen di koleksi "seller" sengaja TIDAK dihapus
  /// di sini (histori tetap ada) — hapus manual lewat deleteSellerProfile()
  /// kalau memang perlu.
  static Future<void> deactivateSellerRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Tidak ada user yang sedang login',
      );
    }

    await _firestore.collection('users').doc(user.uid).update({
      'roles.seller': false,
    });
  }

  static Future<bool> isSeller() async {
    final user = _auth.currentUser;
    if (user == null) return false;
 
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    if (data == null) return false;
 
    final roles = data['roles'] as Map<String, dynamic>?;
    return roles?['seller'] == true;
  }
 
  /// Versi stream dari isSeller(), untuk halaman yang perlu langsung
  /// bereaksi kalau status seller berubah selagi halaman terbuka
  /// (misalnya role di-nonaktifkan admin saat user masih di halaman itu).
  static Stream<bool> isSellerStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
 
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return false;
      final roles = data['roles'] as Map<String, dynamic>?;
      return roles?['seller'] == true;
    });
  }
 
  /// Update status buka/tutup toko secara cepat (di luar jam operasional
  /// tersimpan). Disimpan di field `isOpen` pada dokumen seller/{uid}.
  ///
  /// Dipanggil dari tombol toggle cepat di halaman Kelola Toko — TIDAK
  /// mengubah data jam operasional yang tersimpan di field lain, cuma
  /// menimpa status "buka sekarang" saja.
  static Future<void> updateStoreOpenStatus(bool isOpen) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Tidak ada user yang sedang login',
      );
    }
 
    await _firestore.collection('seller').doc(user.uid).set({
      'isOpen': isOpen,
      'isOpenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
 
  /// Stream status buka/tutup toko milik user yang sedang login, untuk
  /// dipakai langsung dengan StreamBuilder di halaman Kelola Toko.
  /// Default `true` (dianggap buka) kalau field `isOpen` belum pernah
  /// diset sebelumnya (misalnya seller baru saja terdaftar).
  static Stream<bool> storeOpenStatusStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Tidak ada user yang sedang login',
      );
    }
 
    return _firestore
        .collection('seller')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null || data['isOpen'] == null) return true;
      return data['isOpen'] as bool;
    });
  }

  /// Hapus dokumen profil penjual di koleksi "seller". Dipisah dari
  /// deactivateSellerRole() supaya menonaktifkan status dan menghapus
  /// data adalah dua aksi yang beda (yang kedua lebih destruktif).
  static Future<void> deleteSellerProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Tidak ada user yang sedang login',
      );
    }

    await _firestore.collection('seller').doc(user.uid).delete();
  }

  static Future<void> logout() => _auth.signOut();

  /// Terjemahkan kode error Firebase ke pesan Bahasa Indonesia yang mudah dibaca.
  static String mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'phone-already-in-use':
        return 'Nomor telepon sudah terdaftar';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Kata sandi terlalu lemah, minimal 6-8 karakter';
      case 'user-not-found':
        return 'Email tidak ditemukan';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah';
      case 'email-not-verified':
        return e.message ?? 'Email belum diverifikasi';
      case 'already-verified':
        return e.message ?? 'Email sudah terverifikasi';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      case 'no-current-user':
        return e.message ?? 'Kamu perlu login terlebih dahulu';
      default:
        return e.message ?? 'Terjadi kesalahan, coba lagi';
    }
  }
}