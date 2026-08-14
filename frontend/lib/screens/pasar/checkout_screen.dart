import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/models/orders_manager.dart';
import 'package:frontend/screens/orders_screen.dart';

// ─────────────────────────────────────────────
//  Warna (konsisten dengan pasar_screen.dart & home_screen.dart)
// ─────────────────────────────────────────────
const Color _green = Color(0xFF007C3F);
const Color _dark = Color(0xFF0F1B11);

TextStyle _ms({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _dark,
}) => GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

const int _ongkirPerGerai = 2000;

// ─────────────────────────────────────────────
//  CheckoutScreen
// ─────────────────────────────────────────────
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _catatanCtrl = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  // Kelompokkan item keranjang per gerai, supaya biaya ongkir
  // dan ringkasan ditampilkan per-gerai (karena tiap gerai jadi
  // 1 dokumen order terpisah di Firestore saat checkout).
  Map<String, List<CartItem>> _groupByGerai(List<CartItem> items) {
    final Map<String, List<CartItem>> grouped = {};
    for (final item in items) {
      final key = item.sellerId ?? item.geraiId ?? item.namaGerai;
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: CartManager.instance.items,
      builder: (context, items, _) {
        final grouped = _groupByGerai(items);
        final subtotalProduk = items.fold<int>(0, (s, c) => s + c.subtotal);
        final totalOngkir = grouped.length * _ongkirPerGerai;
        final totalBayar = subtotalProduk + totalOngkir;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: _dark,
            title: Text('Checkout', style: _ms(size: 16, weight: FontWeight.bold)),
          ),
          body: items.isEmpty
              ? _buildEmptyCart()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                  children: [
                    ...grouped.entries.map((e) => _buildGeraiGroup(e.key, e.value)),
                    const SizedBox(height: 8),
                    _buildCatatanField(),
                    const SizedBox(height: 8),
                    _buildRingkasanBayar(subtotalProduk, totalOngkir, totalBayar),
                  ],
                ),
          bottomNavigationBar: items.isEmpty
              ? null
              : _buildBottomBar(totalBayar, items),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Keranjang kosong', style: _ms(size: 16, weight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Yuk belanja dulu di pasar favoritmu', style: _ms(size: 13, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildGeraiGroup(String key, List<CartItem> groupItems) {
    final first = groupItems.first;
    final subtotal = groupItems.fold<int>(0, (s, c) => s + c.subtotal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 16, color: _green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(first.namaGerai, style: _ms(size: 13, weight: FontWeight.bold)),
              ),
              Text(first.namaMarket, style: _ms(size: 10, color: Colors.black38)),
            ],
          ),
          if (first.sellerId == null || first.sellerId!.isEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'sellerId gerai ini belum diatur — pesanan tidak akan muncul di dashboard seller.',
                style: _ms(size: 9, color: Colors.red.shade700),
              ),
            ),
          ],
          const Divider(height: 18, color: Color(0xFFF0F0F0)),
          ...groupItems.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(c.produk.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.produk.nama, style: _ms(size: 12, weight: FontWeight.w600)),
                          Text('${c.qty} x Rp${_formatRupiah(c.produk.hargaSekarang)}/${c.produk.satuan}',
                              style: _ms(size: 10, color: Colors.black45)),
                        ],
                      ),
                    ),
                    Text('Rp${_formatRupiah(c.subtotal)}', style: _ms(size: 12, weight: FontWeight.bold)),
                  ],
                ),
              )),
          const Divider(height: 10, color: Color(0xFFF0F0F0)),
          Row(
            children: [
              Text('Ongkir', style: _ms(size: 11, color: Colors.black54)),
              const Spacer(),
              Text('Rp${_formatRupiah(_ongkirPerGerai)}', style: _ms(size: 11, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Subtotal Gerai', style: _ms(size: 12, weight: FontWeight.bold)),
              const Spacer(),
              Text('Rp${_formatRupiah(subtotal + _ongkirPerGerai)}', style: _ms(size: 12, weight: FontWeight.bold, color: _green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanField() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Catatan untuk penjual (opsional)', style: _ms(size: 12, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _catatanCtrl,
            maxLines: 2,
            style: _ms(size: 12),
            decoration: InputDecoration(
              hintText: 'Contoh: tolong pilihkan yang matang',
              hintStyle: _ms(size: 12, color: Colors.black38),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasanBayar(int subtotalProduk, int totalOngkir, int totalBayar) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Pembayaran', style: _ms(size: 12, weight: FontWeight.bold)),
          const SizedBox(height: 10),
          _summaryRow('Subtotal Produk', subtotalProduk),
          _summaryRow('Total Ongkir', totalOngkir),
          const Divider(height: 18, color: Color(0xFFF0F0F0)),
          Row(
            children: [
              Text('Total Bayar', style: _ms(size: 13, weight: FontWeight.bold)),
              const Spacer(),
              Text('Rp${_formatRupiah(totalBayar)}', style: _ms(size: 15, weight: FontWeight.bold, color: _green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: _ms(size: 12, color: Colors.black54)),
          const Spacer(),
          Text('Rp${_formatRupiah(value)}', style: _ms(size: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int totalBayar, List<CartItem> items) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Bayar', style: _ms(size: 10, color: Colors.black45)),
                  Text('Rp${_formatRupiah(totalBayar)}', style: _ms(size: 16, weight: FontWeight.bold, color: _green)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isPlacingOrder ? null : () => _handlePlaceOrder(items),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Buat Pesanan', style: _ms(size: 13, weight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder(List<CartItem> items) async {
    setState(() => _isPlacingOrder = true);
    HapticFeedback.mediumImpact();

    try {
      final orderCodes = await OrdersManager.instance.placeOrder(
        items: items,
        catatan: _catatanCtrl.text.trim(),
        ongkirPerGerai: _ongkirPerGerai,
      );

      CartManager.instance.kosongkan();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderCodes.length > 1
                ? '${orderCodes.length} pesanan berhasil dibuat!'
                : 'Pesanan ${orderCodes.first} berhasil dibuat!',
            style: _ms(size: 12, color: Colors.white),
          ),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat pesanan: $e', style: _ms(size: 12, color: Colors.white)),
          backgroundColor: Colors.red.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _formatRupiah(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}