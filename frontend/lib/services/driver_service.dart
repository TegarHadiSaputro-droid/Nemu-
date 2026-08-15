import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// DRIVER SERVICE (Firebase)
/// Menangani pencarian calon driver dan pengiriman undangan
/// "jadi driver" dari penjual ke pengguna lain.
///
/// Undangan ditulis ke users/{targetUid}/inbox/{inviteId} — dibaca oleh
/// InboxScreen di sisi penerima. roles.driver BARU dinyalakan kalau
/// penerima menekan "Terima" di InboxScreen (bukan otomatis saat
/// diundang), jadi si penerima tetap yang memutuskan sendiri —
/// sama seperti kenapa roles.seller nggak boleh diubah sepihak.
/// ============================================================
class DriverService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Ambil 20 user pertama, diurutkan A-Z berdasarkan nama, TIDAK termasuk
  /// akun yang sudah berstatus Penjual atau Driver (nggak masuk akal
  /// ditawari jadi driver lagi). Kalau [searchQuery] diisi, cari
  /// berdasarkan awalan nama (dan awalan email kalau query-nya kelihatan
  /// seperti email / nama tidak ketemu apa-apa).
  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchUsersAZ({
    String? searchQuery,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    final q = (searchQuery ?? '').trim();

    // Overfetch (40, bukan 20) karena sebagian bakal kesaring keluar
    // (sudah Penjual/Driver, atau diri sendiri) sebelum dipotong jadi 20.
    const fetchLimit = 40;
    const displayLimit = 20;

    List<QueryDocumentSnapshot<Map<String, dynamic>>> results = [];

    if (q.isEmpty) {
      final snap = await _firestore
          .collection('users')
          .orderBy('name')
          .limit(fetchLimit)
          .get();
      results = snap.docs;
    } else {
      // Cari berdasarkan awalan nama (case-sensitive — Firestore nggak
      // bisa case-insensitive query tanpa field tambahan yang di-lowercase).
      final byName = await _firestore
          .collection('users')
          .orderBy('name')
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(fetchLimit)
          .get();
      results.addAll(byName.docs);

      // Kalau ketikannya kelihatan kayak email, atau pencarian nama
      // nggak nemu apa-apa, coba juga cari lewat awalan email.
      if (q.contains('@') || results.isEmpty) {
        final byEmail = await _firestore
            .collection('users')
            .orderBy('email')
            .startAt([q])
            .endAt(['$q\uf8ff'])
            .limit(fetchLimit)
            .get();
        for (final doc in byEmail.docs) {
          if (!results.any((r) => r.id == doc.id)) results.add(doc);
        }
      }
    }

    // Saring: bukan diri sendiri, dan belum berstatus Penjual/Driver.
    // (Firestore nggak bisa query nested-map roles.seller/roles.driver
    // sekaligus orderBy nama tanpa index gabungan, jadi disaring di
    // client saja — cukup buat skala prototipe.)
    final filtered = results.where((doc) {
      if (doc.id == currentUid) return false;
      final roles = doc.data()['roles'] as Map<String, dynamic>?;
      final isSeller = (roles?['seller'] as bool?) ?? false;
      final isDriver = (roles?['driver'] as bool?) ?? false;
      return !isSeller && !isDriver;
    }).toList();

    return filtered.take(displayLimit).toList();
  }

  /// Kirim undangan jadi driver ke user lain. Undangan masuk ke inbox
  /// penerima; roles.driver belum berubah sampai penerima menekan Terima.
  static Future<void> sendDriverInvite({
    required String targetUid,
    required String storeName,
  }) async {
    final seller = _auth.currentUser;
    if (seller == null) throw Exception('Kamu harus login dulu');

    // Cegah kirim undangan dobel yang masih pending dari seller yang sama
    // ke orang yang sama.
    final existing = await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('inbox')
        .where('fromUid', isEqualTo: seller.uid)
        .where('type', isEqualTo: 'driver_invite')
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Undangan ke akun ini masih menunggu jawaban');
    }

    await _firestore.collection('users').doc(targetUid).collection('inbox').add({
      'type': 'driver_invite',
      'fromUid': seller.uid,
      'storeName': storeName,
      'message': 'Kamu diundang menjadi driver untuk $storeName',
      'status': 'pending', // pending -> accepted | declined
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Terima undangan jadi driver: update status pesan + nyalakan
  /// roles.driver di dokumen user yang menerima (dirinya sendiri, jadi
  /// aman ditulis dari client — bukan orang lain yang menentukan).
  ///
  /// roles.buyer SEKALIAN dimatikan di sini -- akun yang sudah jadi Driver
  /// nggak lagi dianggap Pembeli biasa, supaya router (main.dart / auth
  /// gate) yang milih home screen berdasarkan roles nggak ketiban salah
  /// arah ke HomeScreen Pembeli lagi. Pakai dot-path ('roles.driver',
  /// 'roles.buyer') supaya cuma dua field itu yang berubah -- roles.seller
  /// (kalau ada) tetap apa adanya, nggak ikut ketimpa.
  static Future<void> acceptDriverInvite(String inviteId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final batch = _firestore.batch();
    final inviteRef =
        _firestore.collection('users').doc(uid).collection('inbox').doc(inviteId);
    batch.update(inviteRef, {'status': 'accepted', 'read': true});

    // PENTING: pakai batch.update() di sini, BUKAN batch.set(..., merge:true).
    // Dot-notation ('roles.driver') sebagai key top-level cuma dijamin
    // di-treat sebagai nested field path oleh update(). Kalau dipakai di
    // set()+merge, Firestore malah bikin field baru literal bernama
    // "roles.driver" (sejajar dengan map "roles", bukan nested di
    // dalamnya) -- makanya sebelumnya roles.driver di dalam map "roles"
    // nggak pernah benar-benar ke-update walau operasinya "berhasil".
    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {
      'roles.driver': true,
      'roles.buyer': false,
    });

    await batch.commit();

    // Sign out setelah accept berhasil -- user diarahkan login ulang
    // (dilakukan oleh InboxScreen setelah ini return) supaya sesi & data
    // ter-refresh sebagai Driver.
    await _auth.signOut();
  }

  /// Tolak undangan jadi driver.
  static Future<void> declineDriverInvite(String inviteId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('inbox')
        .doc(inviteId)
        .update({'status': 'declined', 'read': true});
  }
}