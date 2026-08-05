import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/cart_model.dart';

const Color _cGreen  = Color(0xFF007C3F);
const Color _cYellow = Color(0xFFD9DF36);
const Color _cDark   = Color(0xFF0F1B11);
const Color _cSurf   = Color(0xFFF5F7F0);

TextStyle _cs({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _cDark,
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

String _cRupiah(int val) {
  final s = val.toString().split('').reversed.join();
  final groups = <String>[];
  for (var i = 0; i < s.length; i += 3) {
    groups.add(s.substring(i, i + 3 > s.length ? s.length : i + 3));
  }
  return 'Rp ${groups.join('.').split('').reversed.join()}';
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
  int _selectedPayment = 0;
  String? _selectedDriverId;
  bool _ordered = false;

  static const int _ongkir = 5000;

  static const _paymentMethods = [
    _PaymentMethod(icon: Icons.money_rounded, label: 'Bayar di Tempat (COD)', desc: 'Bayar saat barang tiba'),
    _PaymentMethod(icon: Icons.account_balance_rounded, label: 'Transfer Bank', desc: 'BRI / BNI / Mandiri'),
    _PaymentMethod(icon: Icons.wallet_rounded, label: 'E-Wallet', desc: 'GoPay / OVO / Dana'),
  ];

  int get _subtotal => _cart.totalHarga;
  int get _total => _subtotal + _ongkir;

  @override
  void initState() {
    super.initState();
    // Default select first available driver
    final firstAvailable = mockDrivers.firstWhere((d) => !d.sibuk, orElse: () => mockDrivers.first);
    if (!firstAvailable.sibuk) {
      _selectedDriverId = firstAvailable.id;
    }
  }

  void _pesan() async {
    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan pilih driver pengantar terlebih dahulu',
              style: _cs(size: 13, color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _ordered = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _cart.kosongkan();
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        onDone: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
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
          if (items.isEmpty && !_ordered) {
            return _buildEmpty();
          }
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
                      ..._cart.items.value.map((item) => _buildCartItem(item)),

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
              _buildOrderButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: _cs(size: 15, weight: FontWeight.bold));
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          // Emoji
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _cGreen.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(item.produk.emoji,
                  style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.produk.nama,
                    style: _cs(size: 13, weight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${item.namaMarket} • ${item.namaGerai}',
                    style: _cs(size: 11, color: Colors.black45)),
                const SizedBox(height: 4),
                Text(_cRupiah(item.produk.hargaSekarang),
                    style: _cs(size: 12, weight: FontWeight.w600, color: _cGreen)),
              ],
            ),
          ),
          // Stepper
          Row(
            children: [
              _miniBtn(Icons.remove_rounded, () {
                _cart.ubahQty(item.produk.id, item.qty - 1);
                setState(() {});
              }, item.qty <= 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${item.qty}',
                    style: _cs(size: 14, weight: FontWeight.bold)),
              ),
              _miniBtn(Icons.add_rounded, () {
                _cart.ubahQty(item.produk.id, item.qty + 1);
                setState(() {});
              }, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap, bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade100 : _cGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: disabled ? Colors.grey.shade200 : _cGreen.withOpacity(0.25)),
        ),
        child: Icon(icon,
            size: 15,
            color: disabled ? Colors.grey.shade300 : _cGreen),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rumah Egii',
                    style: _cs(size: 13, weight: FontWeight.bold)),
                Text('Jl. Mawar No. 12, Balikpapan Selatan',
                    style: _cs(size: 11, color: Colors.black54)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text('Ubah',
                style: _cs(size: 12, weight: FontWeight.bold, color: _cGreen)),
          ),
        ],
      ),
    );
  }

  // Horizontal list view of drivers
  Widget _buildDriverSelectionList() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mockDrivers.length,
        itemBuilder: (_, i) {
          final driver = mockDrivers[i];
          final isSelected = _selectedDriverId == driver.id;
          final isBusy = driver.sibuk;

          return GestureDetector(
            onTap: isBusy
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDriverId = driver.id);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              margin: const EdgeInsets.only(right: 10, bottom: 4),
              decoration: BoxDecoration(
                color: isBusy
                    ? Colors.grey.shade100
                    : (isSelected ? _cGreen : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isBusy
                      ? Colors.grey.shade300
                      : (isSelected ? _cGreen : Colors.transparent),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          driver.emoji,
                          style: TextStyle(
                            fontSize: 26,
                            color: isBusy ? Colors.grey : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          driver.nama,
                          style: _cs(
                            size: 12,
                            weight: FontWeight.bold,
                            color: isBusy
                                ? Colors.grey
                                : (isSelected ? Colors.white : _cDark),
                          ),
                        ),
                        Text(
                          isBusy ? 'Sibuk' : '⭐ ${driver.rating}',
                          style: _cs(
                            size: 10,
                            color: isBusy
                                ? Colors.grey.shade400
                                : (isSelected ? Colors.white70 : Colors.black45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected && !isBusy)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentTile(int idx, _PaymentMethod method) {
    final selected = _selectedPayment == idx;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPayment = idx);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _cGreen : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? _cGreen.withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(method.icon,
                  color: selected ? _cGreen : Colors.grey.shade500, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label,
                      style: _cs(
                          size: 13,
                          weight: FontWeight.bold,
                          color: selected ? _cGreen : _cDark)),
                  Text(method.desc,
                      style: _cs(size: 11, color: Colors.black45)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? _cGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _cGreen : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', _subtotal),
          const SizedBox(height: 8),
          _summaryRow('Ongkir', _ongkir),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Text('Total Pembayaran',
                  style: _cs(size: 14, weight: FontWeight.bold)),
              const Spacer(),
              Text(_cRupiah(_total),
                  style: _cs(
                      size: 18,
                      weight: FontWeight.bold,
                      color: _cGreen)),
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
        Text(_cRupiah(amount),
            style: _cs(size: 13, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildOrderButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: _cs(size: 12, color: Colors.black45)),
              Text(_cRupiah(_total),
                  style:
                      _cs(size: 16, weight: FontWeight.bold, color: _cGreen)),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _ordered ? null : _pesan,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _ordered
                      ? [Colors.grey.shade400, Colors.grey.shade300]
                      : [const Color(0xFF00A851), _cGreen],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _ordered
                    ? []
                    : [
                        BoxShadow(
                            color: _cGreen.withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 5))
                      ],
              ),
              child: Center(
                child: _ordered
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text('Pesan Sekarang',
                        style: _cs(
                            size: 15,
                            weight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('Keranjang kosong', style: _cs(size: 18, weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tambahkan produk dari pasar dulu yuk!',
              style: _cs(size: 13, color: Colors.black45)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _cGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Belanja Sekarang',
                  style: _cs(
                      size: 14,
                      weight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Success Dialog
// ─────────────────────────────────────────────
class _SuccessDialog extends StatefulWidget {
  final VoidCallback onDone;
  const _SuccessDialog({required this.onDone});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: _cGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 20),
            Text('Pesanan Berhasil!',
                style: _cs(size: 20, weight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Pesananmu sedang diproses oleh pedagang.\nKamu bisa cek status di tab Pesanan.',
              textAlign: TextAlign.center,
              style: _cs(size: 13, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: widget.onDone,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00A851), _cGreen]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text('Kembali ke Beranda',
                      style: _cs(
                          size: 14,
                          weight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Data class
// ─────────────────────────────────────────────
class _PaymentMethod {
  final IconData icon;
  final String label;
  final String desc;
  const _PaymentMethod(
      {required this.icon, required this.label, required this.desc});
}


