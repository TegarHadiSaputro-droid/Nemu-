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

    // Simpan data tambahan (nama, telepon) ke Firestore
    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
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

  static void logout() => _auth.signOut();

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
      default:
        return e.message ?? 'Terjadi kesalahan, coba lagi';
    }
  }
}