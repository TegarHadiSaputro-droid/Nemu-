// orders_manager.dart
//
// Singleton (pola sama seperti CartManager.instance) yang jadi jembatan
// antara checkout_screen.dart (yang BIKIN pesanan) dan orders_screen.dart
// (yang NAMPILIN pesanan). Tanpa ini, "Pesan Sekarang" di checkout cuma
// nampilin dialog sukses lokal tanpa pesanannya beneran nyampe ke
// halaman Pesanan.

import 'package:flutter/foundation.dart';
import '../screens/orders_screen.dart' show OrderHistoryItem;

class OrdersManager {
  OrdersManager._();
  static final OrdersManager instance = OrdersManager._();

  final ValueNotifier<OrderHistoryItem?> activeOrder = ValueNotifier(null);
  final ValueNotifier<List<OrderHistoryItem>> history = ValueNotifier(const []);

  /// Dipanggil dari checkout_screen.dart setelah "Pesan Sekarang" berhasil.
  void placeOrder(OrderHistoryItem order) {
    // Kalau ada order aktif sebelumnya yang belum masuk riwayat, geser dulu
    // ke history supaya nggak ketiban begitu aja.
    final previous = activeOrder.value;
    if (previous != null) {
      history.value = [...history.value, previous];
    }
    activeOrder.value = order;
  }

  /// Dipanggil dari orders_screen.dart begitu status pesanan jadi "Selesai".
  void completeActiveOrder() {
    final order = activeOrder.value;
    if (order == null) return;
    history.value = [...history.value, order];
    activeOrder.value = null;
  }
}
