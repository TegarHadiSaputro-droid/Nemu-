import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/utils/ongkir.dart';
import 'package:frontend/models/orders_manager.dart';
import 'package:frontend/services/address_manager.dart';
import 'package:frontend/screens/orders_screen.dart';

// ─────────────────────────────────────────────
//  Warna (konsisten dengan pasar_screen.dart & home_screen.dart)
// ─────────────────────────────────────────────
const Color _cGreen = Color(0xFF007C3F);
const Color _cDark = Color(0xFF0F1B11);
const Color _cSurf = Color(0xFFF7F8F7);

TextStyle _cs({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _cDark,
}) => GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

String _cRupiah(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return 'Rp${buffer.toString()}';
}

class _PaymentMethod {
  final IconData icon;
  final String label;
  final String desc;
  const _PaymentMethod({required this.icon, required this.label, required this.desc});
}

// ─────────────────────────────────────────────
//  CheckoutScreen
// ─────────────────────────────────────────────
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartManager _cart = CartManager.instance;
  final TextEditingController _catatanCtrl = TextEditingController();
  int _selectedPayment = 0;
  String? _selectedDriverId;
  bool _isPlacingOrder = false;

  // Ongkir dihitung dari 2 komponen: berat pesanan (per market) dan jarak
  // pengantaran (per market). Aturan lengkap ada di lib/utils/ongkir.dart.
  // Kalau keranjang isinya dari beberapa pasar sekaligus, ongkir tiap
  // pasar dijumlah (asumsi: tiap pasar diantar terpisah).

  /// Ambil jarak (km) ke sebuah pasar. Prioritas:
  /// 1. Kalau alamat user & pasar sama-sama punya koordinat -> hitung
  ///    jarak asli pakai Haversine.
  /// 2. Kalau tidak, fallback ke field `jarak` di PasarMarket (mis. "1.5 km").
  double _jarakUntukMarket(String marketName) {
    final market = mockDaftarPasar.firstWhere(
      (m) => m.nama == marketName,
      orElse: () => mockDaftarPasar.first,
    );

    final address = AddressManager.instance.address.value;
    if (address != null && address.hasCoordinates && market.hasCoordinates) {
      return hitungJarakKm(
        address.lat!,
        address.lng!,
        market.lat!,
        market.lng!,
      );
    }

    final match = RegExp(r'[\d.]+').firstMatch(market.jarak);
    return match != null ? double.parse(match.group(0)!) : 0;
  }

  int _ongkirForMarket(String marketName) {
    final beratKg = _cart.totalBeratUntukMarket(marketName);
    final jarakKm = _jarakUntukMarket(marketName);
    return hitungTotalOngkir(beratKg: beratKg, jarakKm: jarakKm).totalOngkir;
  }

  // Dipecah per komponen (berat vs jarak) supaya bisa ditampilkan
  // detailnya di Ringkasan Biaya -- jadi kelihatan jelas komponen mana
  // yang kena biaya dan mana yang gratis.
  int _ongkirBeratForMarket(String marketName) {
    final beratKg = _cart.totalBeratUntukMarket(marketName);
    return hitungOngkirBerat(beratKg);
  }

  int _ongkirJarakForMarket(String marketName) {
    final jarakKm = _jarakUntukMarket(marketName);
    return hitungOngkirJarak(jarakKm);
  }

  static const _paymentMethods = [
    _PaymentMethod(icon: Icons.money_rounded, label: 'Bayar di Tempat (COD)', desc: 'Bayar saat barang tiba'),
    _PaymentMethod(icon: Icons.account_balance_rounded, label: 'Transfer Bank', desc: 'BRI / BNI / Mandiri'),
    _PaymentMethod(icon: Icons.wallet_rounded, label: 'E-Wallet', desc: 'GoPay / OVO / Dana'),
  ];

  int get _subtotal => _cart.totalHarga;

  int get _ongkir {
    final marketNames = _cart.items.value.map((i) => i.namaMarket).toSet();
    if (marketNames.isEmpty) return 0;
    return marketNames.fold<int>(0, (sum, m) => sum + _ongkirForMarket(m));
  }

  int get _ongkirBerat {
    final marketNames = _cart.items.value.map((i) => i.namaMarket).toSet();
    if (marketNames.isEmpty) return 0;
    return marketNames.fold<int>(0, (sum, m) => sum + _ongkirBeratForMarket(m));
  }

  int get _ongkirJarak {
    final marketNames = _cart.items.value.map((i) => i.namaMarket).toSet();
    if (marketNames.isEmpty) return 0;
    return marketNames.fold<int>(0, (sum, m) => sum + _ongkirJarakForMarket(m));
  }

  int get _total => _subtotal + _ongkir;

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cSurf,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _cDark, size: 20),
        ),
        title: Text('Checkout', style: _cs(size: 18, weight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: _cart.items,
        builder: (_, items, __) {
          if (items.isEmpty) {
            return _buildEmpty();
          }
          // Listener kedua khusus alamat -- supaya Ringkasan Biaya &
          // tombol total ikut rebuild begitu alamat (koordinat) berubah,
          // bukan cuma nunggu keranjang berubah.
          return ValueListenableBuilder<DeliveryAddress?>(
            valueListenable: AddressManager.instance.address,
            builder: (_, address, __) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Pesanan Kamu'),
                          const SizedBox(height: 10),
                          ...items.map((item) => _buildCartItem(item)),

                          const SizedBox(height: 16),
                          _buildSectionTitle('Alamat Pengiriman'),
                          const SizedBox(height: 10),
                          _buildAddressCard(),

                          const SizedBox(height: 18),
                          _buildSectionTitle('Pilih Driver Pengantar'),
                          Text('Geser untuk memilih driver yang tersedia',
                              style: _cs(size: 11.5, color: Colors.black45)),
                          const SizedBox(height: 10),
                          _buildDriverSelectionList(),

                          const SizedBox(height: 18),
                          _buildSectionTitle('Metode Pembayaran'),
                          const SizedBox(height: 10),
                          ..._paymentMethods.asMap().entries.map(
                                (e) => _buildPaymentTile(e.key, e.value),
                              ),

                          const SizedBox(height: 18),
                          _buildSectionTitle('Ringkasan Biaya'),
                          const SizedBox(height: 10),
                          _buildSummaryCard(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(_total, items),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Keranjang kosong', style: _cs(size: 16, weight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Yuk belanja dulu di pasar favoritmu', style: _cs(size: 13, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: _cs(size: 14, weight: FontWeight.bold));
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Text(item.produk.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.produk.nama, style: _cs(size: 13, weight: FontWeight.w600)),
                Text('${item.namaGerai} • ${item.namaMarket}', style: _cs(size: 10.5, color: Colors.black38)),
                Text('${item.qty} x ${_cRupiah(item.produk.hargaSekarang)}/${item.produk.satuan}',
                    style: _cs(size: 10.5, color: Colors.black45)),
              ],
            ),
          ),
          Text(_cRupiah(item.subtotal), style: _cs(size: 13, weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final address = AddressManager.instance.address.value;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, size: 18, color: _cGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              address?.text ?? 'Belum ada alamat dipilih',
              style: _cs(size: 12.5, color: Colors.black87),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.black38),
        ],
      ),
    );
  }

  Widget _buildDriverSelectionList() {
    // TODO: hubungkan ke sumber data driver yang sesungguhnya.
    return SizedBox(
      height: 80,
      child: Center(
        child: Text('Belum ada driver tersedia', style: _cs(size: 12, color: Colors.black38)),
      ),
    );
  }

  Widget _buildPaymentTile(int index, _PaymentMethod method) {
    final selected = _selectedPayment == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _cGreen : Colors.transparent, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Icon(method.icon, size: 20, color: selected ? _cGreen : Colors.black45),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: _cs(size: 12.5, weight: FontWeight.w600)),
                  Text(method.desc, style: _cs(size: 10.5, color: Colors.black45)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? _cGreen : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final items = _cart.items.value;
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
          if (items.isNotEmpty) ...[
            Text('Rincian Pesanan', style: _cs(size: 11.5, weight: FontWeight.bold, color: Colors.black38)),
            const SizedBox(height: 10),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _itemSummaryRow(item),
                )),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Divider(height: 1),
            ),
          ],
          _summaryRow('Subtotal', _subtotal),
          const SizedBox(height: 12),
          _summaryRowWithNote(
            icon: Icons.scale_rounded,
            label: 'Ongkir Berat',
            amount: _ongkirBerat,
            note: 'Kelebihan 1 kg dari pembelian di atas 3 kg dikenakan Rp4.000/kg',
          ),
          const SizedBox(height: 10),
          _summaryRowWithNote(
            icon: Icons.route_rounded,
            label: 'Ongkir Jarak',
            amount: _ongkirJarak,
            note: 'Kelebihan 1 km dari jarak toko di atas 3 km dikenakan Rp3.000/km',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Text('Total Pembayaran', style: _cs(size: 14, weight: FontWeight.bold)),
              const Spacer(),
              Text(_cRupiah(_total), style: _cs(size: 18, weight: FontWeight.bold, color: _cGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, int amount) {
    return Row(
      children: [
        Text(label, style: _cs(size: 13, color: Colors.black54)),
        const Spacer(),
        Text(_cRupiah(amount), style: _cs(size: 13, weight: FontWeight.w600)),
      ],
    );
  }

  // Baris per item pesanan (nama produk x qty -> harga), ditampilkan di
  // paling atas Ringkasan Biaya supaya user bisa cross-check pesanannya
  // sebelum bayar.
  Widget _itemSummaryRow(CartItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '${item.produk.nama} x${item.qty}',
            style: _cs(size: 12.5, color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _cRupiah(item.produk.hargaSekarang * item.qty),
          style: _cs(size: 12.5, weight: FontWeight.w600),
        ),
      ],
    );
  }

  // Baris ongkir (berat / jarak) + keterangan singkat nempel di bawahnya,
  // biar user langsung ngerti kenapa angkanya segitu tanpa harus lihat
  // box info terpisah.
  Widget _summaryRowWithNote({
    required IconData icon,
    required String label,
    required int amount,
    required String note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.black38),
            const SizedBox(width: 6),
            Text(label, style: _cs(size: 13, color: Colors.black54)),
            const Spacer(),
            Text(_cRupiah(amount), style: _cs(size: 13, weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            note,
            style: _cs(size: 10.5, color: Colors.black38, weight: FontWeight.w500),
          ),
        ),
      ],
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
                  Text('Total Bayar', style: _cs(size: 10, color: Colors.black45)),
                  Text(_cRupiah(totalBayar), style: _cs(size: 16, weight: FontWeight.bold, color: _cGreen)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isPlacingOrder ? null : () => _handlePlaceOrder(items),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cGreen,
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
                  : Text('Buat Pesanan', style: _cs(size: 13, weight: FontWeight.bold, color: Colors.white)),
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
        ongkirPerGerai: _ongkir,
      );

      CartManager.instance.kosongkan();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderCodes.length > 1
                ? '${orderCodes.length} pesanan berhasil dibuat!'
                : 'Pesanan ${orderCodes.first} berhasil dibuat!',
            style: _cs(size: 12, color: Colors.white),
          ),
          backgroundColor: _cGreen,
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
          content: Text('Gagal membuat pesanan: $e', style: _cs(size: 12, color: Colors.white)),
          backgroundColor: Colors.red.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}