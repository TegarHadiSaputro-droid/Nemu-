import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// DRIVER SERVICE (Firebase)
/// Menangani pencarian calon driver dan pengiriman undangan
/// "jadi driver" dari penjual ke pengguna lain.
///
/// Undangan disimpan di koleksi top-level `driver_invitations`
/// dan juga di `users/{targetUid}/inbox/{inviteId}`.
/// Begitu penerima menekan "Terima Undangan" di Inbox, role
/// di users/{uid} berubah seketika: is_driver = true, is_buyer = false,
/// is_seller = false, linked_seller_id = seller_id.
/// ============================================================
class DriverService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Ambil user untuk dicari di dialog tambah driver
  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchUsersAZ({
    String? searchQuery,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    final q = (searchQuery ?? '').trim();

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
      final byName = await _firestore
          .collection('users')
          .orderBy('name')
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(fetchLimit)
          .get();
      results.addAll(byName.docs);

      if (q.contains('@') || results.isEmpty) {
        final byEmail = await _firestore
            .collection('users')
            .orderBy('email')
            .startAt([q.toLowerCase()])
            .endAt(['${q.toLowerCase()}\uf8ff'])
            .limit(fetchLimit)
            .get();
        for (final doc in byEmail.docs) {
          if (!results.any((r) => r.id == doc.id)) results.add(doc);
        }
      }
    }

    final filtered = results.where((doc) {
      if (doc.id == currentUid) return false;
      final data = doc.data();
      final roles = data['roles'] as Map<String, dynamic>?;
      final isSeller = (data['is_seller'] as bool?) ?? (roles?['seller'] as bool?) ?? false;
      final isDriver = (data['is_driver'] as bool?) ?? (roles?['driver'] as bool?) ?? false;
      return !isSeller && !isDriver;
    }).toList();

    return filtered.take(displayLimit).toList();
  }

  /// Kirim undangan driver berdasarkan email calon driver
  static Future<void> sendDriverInviteByEmail({
    required String email,
    required String storeName,
    String? sellerId,
  }) async {
    final seller = _auth.currentUser;
    if (seller == null) throw Exception('Kamu harus login dulu sebagai penjual.');

    final resolvedSellerId = sellerId ?? seller.uid;
    final normEmail = email.trim().toLowerCase();

    if (normEmail.isEmpty || !normEmail.contains('@')) {
      throw Exception('Format email tidak valid.');
    }

    // 1. Cek apakah ada undangan pending yang sama
    final existingInvites = await _firestore
        .collection('driver_invitations')
        .where('seller_id', isEqualTo: resolvedSellerId)
        .where('driver_email', isEqualTo: normEmail)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingInvites.docs.isNotEmpty) {
      throw Exception('Undangan ke email $normEmail masih menunggu konfirmasi.');
    }

    // 2. Buat dokumen di driver_invitations
    final inviteRef = _firestore.collection('driver_invitations').doc();
    final invitationData = {
      'invitation_id': inviteRef.id,
      'seller_id': resolvedSellerId,
      'seller_store_name': storeName,
      'driver_email': normEmail,
      'status': 'pending', // 'pending' | 'accepted' | 'declined'
      'created_at': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await inviteRef.set(invitationData);

    // 3. Mirror ke users/{targetUid}/inbox jika akun user tujuan sudah terdaftar
    try {
      final userSnap = await _firestore
          .collection('users')
          .where('email', isEqualTo: normEmail)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        final targetUid = userSnap.docs.first.id;
        await _firestore
            .collection('users')
            .doc(targetUid)
            .collection('inbox')
            .doc(inviteRef.id)
            .set({
          'type': 'driver_invite',
          'invitation_id': inviteRef.id,
          'seller_id': resolvedSellerId,
          'seller_store_name': storeName,
          'fromUid': resolvedSellerId,
          'storeName': storeName,
          'driver_email': normEmail,
          'title': 'Undangan Driver',
          'message': '$storeName mengundang Anda untuk menjadi Driver resmi.',
          'status': 'pending',
          'read': false,
          'created_at': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Abaikan error mirror jika akun belum login atau belum dibuat
    }
  }

  /// Kirim undangan driver berdasarkan targetUid & targetEmail
  static Future<void> sendDriverInvite({
    required String targetUid,
    required String storeName,
    String? targetEmail,
  }) async {
    String? email = targetEmail;
    if (email == null || email.isEmpty) {
      final userDoc = await _firestore.collection('users').doc(targetUid).get();
      email = userDoc.data()?['email'] as String?;
    }

    if (email != null && email.isNotEmpty) {
      await sendDriverInviteByEmail(
        email: email,
        storeName: storeName,
      );
    } else {
      final seller = _auth.currentUser;
      if (seller == null) throw Exception('Kamu harus login dulu');
      final inviteRef = _firestore.collection('driver_invitations').doc();
      await inviteRef.set({
        'invitation_id': inviteRef.id,
        'seller_id': seller.uid,
        'seller_store_name': storeName,
        'target_uid': targetUid,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore
          .collection('users')
          .doc(targetUid)
          .collection('inbox')
          .doc(inviteRef.id)
          .set({
        'type': 'driver_invite',
        'invitation_id': inviteRef.id,
        'fromUid': seller.uid,
        'seller_id': seller.uid,
        'storeName': storeName,
        'seller_store_name': storeName,
        'message': '$storeName mengundang Anda untuk menjadi Driver resmi.',
        'status': 'pending',
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Terima undangan jadi driver:
  /// - update status di driver_invitations jadi 'accepted'
  /// - update dokumen user di users/{uid}:
  ///   is_driver = true, is_buyer = false, is_seller = false, linked_seller_id = seller_id
  /// - tidak melakukan signOut() agar dynamic role switching langsung aktif
  static Future<void> acceptDriverInvite(
    String inviteId, {
    String? sellerId,
    String? driverInvitationDocId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    String resolvedSellerId = sellerId ?? '';
    String invId = driverInvitationDocId ?? inviteId;

    // Ambil detail sellerId jika belum disediakan
    if (resolvedSellerId.isEmpty) {
      try {
        final invDoc = await _firestore.collection('driver_invitations').doc(invId).get();
        if (invDoc.exists) {
          resolvedSellerId = (invDoc.data()?['seller_id'] as String?) ?? '';
        }
      } catch (_) {}
    }

    if (resolvedSellerId.isEmpty) {
      try {
        final inboxDoc = await _firestore
            .collection('users')
            .doc(uid)
            .collection('inbox')
            .doc(inviteId)
            .get();
        if (inboxDoc.exists) {
          resolvedSellerId = (inboxDoc.data()?['seller_id'] as String?) ??
              (inboxDoc.data()?['fromUid'] as String?) ??
              '';
        }
      } catch (_) {}
    }

    final batch = _firestore.batch();

    // 1. Update di driver_invitations
    final invRef = _firestore.collection('driver_invitations').doc(invId);
    batch.set(
      invRef,
      {
        'status': 'accepted',
        'accepted_by_uid': uid,
        'updated_at': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 2. Update di users/{uid}/inbox/{inviteId}
    final userInboxRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('inbox')
        .doc(inviteId);
    batch.set(
      userInboxRef,
      {
        'status': 'accepted',
        'read': true,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 3. Update dokumen user di users/{uid}
    final userRef = _firestore.collection('users').doc(uid);
    final userUpdates = <String, dynamic>{
      'is_driver': true,
      'is_buyer': false,
      'is_seller': false,
      'roles.driver': true,
      'roles.buyer': false,
      'roles.seller': false,
      'roles': {
        'driver': true,
        'buyer': false,
        'seller': false,
      },
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (resolvedSellerId.isNotEmpty) {
      userUpdates['linked_seller_id'] = resolvedSellerId;
    }

    batch.set(userRef, userUpdates, SetOptions(merge: true));

    // Eksekusi atomik batch
    await batch.commit();
  }

  /// Tolak undangan jadi driver.
  static Future<void> declineDriverInvite(
    String inviteId, {
    String? driverInvitationDocId,
  }) async {
    final uid = _auth.currentUser?.uid;
    final invId = driverInvitationDocId ?? inviteId;

    final batch = _firestore.batch();

    final invRef = _firestore.collection('driver_invitations').doc(invId);
    batch.set(
      invRef,
      {
        'status': 'declined',
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (uid != null) {
      final userInboxRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('inbox')
          .doc(inviteId);
      batch.set(
        userInboxRef,
        {
          'status': 'declined',
          'read': true,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}