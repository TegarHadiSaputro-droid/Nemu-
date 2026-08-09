// address_manager.dart
//
// Singleton (pola sama seperti CartManager.instance di checkout_screen.dart)
// yang jadi SATU-SATUNYA sumber alamat pengiriman aktif. Dipakai bareng oleh:
//   - home_screen.dart      (kartu "Ganti Alamat")
//   - address_editor_sheet.dart (yang nulis alamat baru)
//   - checkout_screen.dart  (kartu alamat pengiriman + hitung ongkir)
//   - orders_screen.dart    (nampilin alamat di tracking pesanan)
//
// Karena semua baca dari sumber yang sama, ganti alamat di satu tempat
// otomatis kelihatan di semua tempat lain -- tidak perlu passing data
// manual antar halaman.
//
// Persistensi ke Firestore: field `address` di users/{uid} cuma nyimpen
// SATU alamat aktif (bukan array/riwayat). Jadi begitu setAddress()
// dipanggil dengan alamat baru, .set(..., merge: true) otomatis NIMPA
// nilai lama -- alamat lama "terhapus" dengan sendirinya, tidak perlu
// langkah hapus terpisah.

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeliveryAddress {
  final String text;
  final double? lat;
  final double? lng;

  const DeliveryAddress({required this.text, this.lat, this.lng});

  bool get hasCoordinates => lat != null && lng != null;

  Map<String, dynamic> toMap() => {'text': text, 'lat': lat, 'lng': lng};

  static DeliveryAddress? fromMap(Map<String, dynamic>? map) {
    if (map == null || map['text'] == null) return null;
    return DeliveryAddress(
      text: map['text'] as String,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }
}

class AddressManager {
  AddressManager._();
  static final AddressManager instance = AddressManager._();

  final ValueNotifier<DeliveryAddress?> address = ValueNotifier(null);

  /// Panggil sekali pas app start / user login (mis. di initState HomeScreen)
  /// buat muat alamat yang udah tersimpan sebelumnya dari Firestore.
  Future<void> loadFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final map = doc.data()?['address'] as Map<String, dynamic>?;
      address.value = DeliveryAddress.fromMap(map);
    } catch (_) {
      // Gagal muat (mis. offline) -> biarkan null, user bisa isi manual lagi.
    }
  }

  /// Simpan alamat baru. Nimpa field `address` di Firestore (bukan
  /// menambah entri baru), jadi alamat lama otomatis hilang dari Firestore.
  Future<void> setAddress(DeliveryAddress newAddress) async {
    address.value = newAddress;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'address': newAddress.toMap()},
      SetOptions(merge: true),
    );
  }

  /// Hapus alamat tersimpan sepenuhnya (state lokal + Firestore).
  Future<void> clearAddress() async {
    address.value = null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'address': FieldValue.delete(),
    });
  }
}
