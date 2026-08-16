import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/cart_model.dart';
import 'package:frontend/utils/ongkir.dart';
import 'package:frontend/services/address_manager.dart';
import 'package:frontend/services/order_tracking_service.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/widgets/address_editor_sheet.dart';

const Color _cGreen = Color(0xFF007C3F);
const Color _cYellow = Color(0xFFD9DF36);
const Color _cDark = Color(0xFF0F1B11);
const Color _cSurf = Color(0xFFF5F7F0);

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
  // Satu driver dipilih PER GERAI (bukan satu driver untuk seluruh
  // keranjang) -- karena tiap gerai/toko jadi sub-pesanan terpisah yang
  // dikirim ke pemilik pasarnya masing-masing, jadi wajar tiap gerai
  // juga diantar oleh drivernya sendiri-sendiri.
  final Map<String, String> _selectedDriverByGerai = {};

  // Driver ASLI (dari store_drivers, bukan mock) per gerai -- key-nya
  // group.key, isinya dokumen driver yang sellerUid-nya cocok sama
  // group.sellerId. Diisi async di _loadDriversForGroups().
  final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _driversByGerai = {};
  final Set<String> _loadingDriversForGerai = {};

  bool _ordered = false;

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
    _PaymentMethod(
      icon: Icons.money_rounded,
      label: 'Bayar di Tempat (COD)',
      desc: 'Bayar saat barang tiba',
    ),
    _PaymentMethod(
      icon: Icons.account_balance_rounded,
      label: 'Transfer Bank',
      desc: 'BRI / BNI / Mandiri',
    ),
    _PaymentMethod(
      icon: Icons.wallet_rounded,
      label: 'E-Wallet',
      desc: 'GoPay / OVO / Dana',
    ),
  ];

  int get _subtotal => _cart.totalHarga;

  int get _ongkir {
    final marketNames = _cart.items.value.map((i) => i.namaMarket).toSet();
    if (marketNames.isEmpty) return 0;
    return marketNames.fold<int>(0, (sum, m) => sum + _ongkirForMarket(m));
  }

  int get _total => _subtotal + _ongkir;

  int get _ongkirBerat {
    final marketNames = _cart.items.value.map((i) => i.namaMarket).toSet();
    return marketNames.fold<int>(
      0,
      (sum, m) => sum + _ongkirBeratForMarket(m),
    );
  }

  int get _ongkirJarak {
    final marketNames = _cart.items.value.map((i) => i.namaMarket).toSet();
    return marketNames.fold<int>(
      0,
      (sum, m) => sum + _ongkirJarakForMarket(m),
    );
  }

  // ─────────────────────────────────────────────
  //  Pengelompokan keranjang per gerai
  // ─────────────────────────────────────────────
  // Satu "order" di Firestore = satu gerai (biar tiap pemilik pasar/seller
  // cuma nerima pesanan miliknya sendiri, dan tiap gerai bisa diantar oleh
  // driver yang berbeda-beda). Kalau keranjang isinya dari beberapa gerai
  // sekaligus (termasuk beberapa gerai dalam satu pasar yang sama), tiap
  // gerai dipecah jadi grupnya sendiri di sini.
  List<_GeraiGroup> get _geraiGroups {
    final items = _cart.items.value;
    final Map<String, _GeraiGroup> groups = {};
    for (final item in items) {
      final key = item.geraiId ?? '${item.namaMarket}|${item.namaGerai}';
      final group = groups.putIfAbsent(
        key,
        () => _GeraiGroup(
          key: key,
          geraiId: item.geraiId,
          namaGerai: item.namaGerai,
          namaMarket: item.namaMarket,
          sellerId: item.sellerId,
        ),
      );
      group.items.add(item);
    }
    return groups.values.toList();
  }

  /// Ongkir per market dibagi rata ke tiap gerai yang berbagi market yang
  /// sama (sisa pembagian ditambahkan ke gerai terakhir supaya totalnya
  /// tetap pas dengan `_ongkirForMarket`).
  Map<String, int> _ongkirShareByGeraiKey(List<_GeraiGroup> groups) {
    final Map<String, int> share = {};
    final byMarket = <String, List<_GeraiGroup>>{};
    for (final g in groups) {
      byMarket.putIfAbsent(g.namaMarket, () => []).add(g);
    }
    byMarket.forEach((marketName, groupsInMarket) {
      final totalOngkir = _ongkirForMarket(marketName);
      final base = totalOngkir ~/ groupsInMarket.length;
      final remainder = totalOngkir - (base * groupsInMarket.length);
      for (var i = 0; i < groupsInMarket.length; i++) {
        share[groupsInMarket[i].key] = base + (i == groupsInMarket.length - 1 ? remainder : 0);
      }
    });
    return share;
  }

  @override
  void initState() {
    super.initState();
    _loadDriversForGroups();
  }

  // Ambil driver ASLI per gerai dari collection store_drivers (yang
  // diisi otomatis waktu seorang driver terima undangan -- lihat
  // DriverService.acceptDriverInvite). Gerai tanpa sellerId (mock/statis,
  // belum daftar lewat onboarding penjual) dilewati -- belum ada sistem
  // driver buat gerai kayak gitu.
  Future<void> _loadDriversForGroups() async {
    final groups = _geraiGroups;
    for (final group in groups) {
      final sellerId = group.sellerId;
      if (sellerId == null || _driversByGerai.containsKey(group.key)) continue;

      setState(() => _loadingDriversForGerai.add(group.key));
      try {
        final snap = await FirebaseFirestore.instance
            .collection('store_drivers')
            .where('sellerUid', isEqualTo: sellerId)
            .get();
        if (!mounted) return;
        setState(() {
          _driversByGerai[group.key] = snap.docs;
          _loadingDriversForGerai.remove(group.key);
          // Auto-pilih driver pertama kalau ada & belum ada yang dipilih,
          // supaya UX-nya tetap sama kayak sebelumnya (langsung ada
          // pilihan default begitu halaman dibuka).
          if (snap.docs.isNotEmpty && _selectedDriverByGerai[group.key] == null) {
            _selectedDriverByGerai[group.key] = snap.docs.first.id;
          }
        });
      } catch (e) {
        debugPrint('Gagal ambil daftar driver untuk ${group.namaGerai}: $e');
        if (!mounted) return;
        setState(() => _loadingDriversForGerai.remove(group.key));
      }
    }
  }

  void _pesan() async {
    final groups = _geraiGroups;
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Keranjang belanja kamu masih kosong.',
            style: _cs(size: 13, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final address = AddressManager.instance.address.value;
    if (address == null || address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan isi alamat pengiriman terlebih dahulu ya.',
            style: _cs(size: 13, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Isi Alamat',
            textColor: _cYellow,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddressEditorSheet(),
              );
            },
          ),
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kamu harus login dulu untuk memesan.',
            style: _cs(size: 13, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Driver hanya divalidasi jika gerai memiliki driver terdaftar
    final missingDriverFor = groups.where((g) {
      final hasDrivers = (_driversByGerai[g.key] ?? []).isNotEmpty;
      return hasDrivers && _selectedDriverByGerai[g.key] == null;
    }).toList();

    if (missingDriverFor.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih driver pengantar untuk ${missingDriverFor.map((g) => g.namaGerai).join(', ')} dulu ya',
            style: _cs(size: 13, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _ordered = true);

    final catatan = _catatanCtrl.text.trim();
    final ongkirShare = _ongkirShareByGeraiKey(groups);
    final orderTimestamp = DateTime.now().millisecondsSinceEpoch;
    final groupOrderId = FirebaseFirestore.instance.collection('orders').doc().id;

    String buyerName = 'Sobat Nemu';
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        buyerName = (userDoc.data()?['nickname'] as String?) ??
            (userDoc.data()?['name'] as String?) ??
            buyerName;
      }
    } catch (_) {}

    // Tulis SATU dokumen order per gerai ke Firestore collection 'orders'
    try {
      final batch = FirebaseFirestore.instance.batch();
      final ordersRef = FirebaseFirestore.instance.collection('orders');

      for (var i = 0; i < groups.length; i++) {
        final group = groups[i];
        final subtotal = group.items.fold<int>(0, (s, it) => s + it.subtotal);
        final ongkir = ongkirShare[group.key] ?? 0;
        final itemsSummary =
            group.items.map((it) => '${it.produk.nama} x${it.qty}').join(', ');
        final driverId = _selectedDriverByGerai[group.key];
        final orderCode = 'ORD$orderTimestamp${i.toString().padLeft(2, '0')}';

        final itemsDetail = group.items
            .map((c) => {
                  'product_id': c.produk.id,
                  'produkId': c.produk.id,
                  'product_name': c.produk.nama,
                  'nama': c.produk.nama,
                  'satuan': c.produk.satuan,
                  'quantity': c.qty,
                  'qty': c.qty,
                  'price': c.produk.hargaSekarang,
                  'hargaSatuan': c.produk.hargaSekarang,
                  'subtotal': c.subtotal,
                })
            .toList();

        final sellerId = group.sellerId ?? group.geraiId ?? '';
        final storeId = group.geraiId ?? group.sellerId ?? '';

        final docRef = ordersRef.doc();
        final data = <String, dynamic>{
          'orderId': docRef.id,
          'order_id': docRef.id,
          'orderCode': orderCode,
          'groupOrderId': groupOrderId,
          'buyerId': uid,
          'buyer_id': uid,
          'buyerName': buyerName,
          'buyer_name': buyerName,
          'sellerId': sellerId,
          'seller_id': sellerId,
          'owner_id': sellerId,
          'storeId': storeId,
          'store_id': storeId,
          'namaGerai': group.namaGerai,
          'store_name': group.namaGerai,
          'namaMarket': group.namaMarket,
          'market_type': group.namaMarket,
          'items': itemsDetail,
          'itemsSummary': itemsSummary.isNotEmpty ? itemsSummary : '-',
          'subtotal': subtotal,
          'subtotalProduk': subtotal,
          'ongkir': ongkir,
          'totalHarga': subtotal + ongkir,
          'totalPrice': subtotal + ongkir,
          'total_price': subtotal + ongkir,
          'alamatPengiriman': address.text,
          'address': address.text,
          'driverUid': driverId,
          'paymentMethod': _paymentMethods[_selectedPayment].label,
          'catatan': catatan.isEmpty ? null : catatan,
          'status': 'menunggu',
          'statusLabel': 'Menunggu Konfirmasi',
          'timestamp': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (group.geraiId != null) {
          data['gerai_id'] = group.geraiId;
        }
        batch.set(docRef, data);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Gagal membuat pesanan: $e');
      if (mounted) {
        setState(() => _ordered = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuat pesanan: $e',
              style: _cs(size: 13, color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await Future.delayed(const Duration(seconds: 1));
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
          HomeScreen.navIndexNotifier.value = 4; // Switch to Tab Pesanan
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _cDark,
            size: 20,
          ),
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
                          Text(
                            'Tiap gerai diantar oleh drivernya masing-masing',
                            style: _cs(size: 11.5, color: Colors.black45),
                          ),
                          const SizedBox(height: 10),
                          ..._geraiGroups.map(_buildDriverSelectionForGerai),

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
          );
        },
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
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
              child: Text(
                item.produk.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.produk.nama,
                  style: _cs(size: 13, weight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.namaMarket} • ${item.namaGerai}',
                  style: _cs(size: 11, color: Colors.black45),
                ),
                const SizedBox(height: 4),
                Text(
                  _cRupiah(item.produk.hargaSekarang),
                  style: _cs(size: 12, weight: FontWeight.w600, color: _cGreen),
                ),
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
                child: Text(
                  '${item.qty}',
                  style: _cs(size: 14, weight: FontWeight.bold),
                ),
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
      onTap: disabled
          ? null
          : () {
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
            color: disabled ? Colors.grey.shade200 : _cGreen.withOpacity(0.25),
          ),
        ),
        child: Icon(
          icon,
          size: 15,
          color: disabled ? Colors.grey.shade300 : _cGreen,
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return ValueListenableBuilder<DeliveryAddress?>(
      valueListenable: AddressManager.instance.address,
      builder: (context, address, _) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
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
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address != null ? 'Kirim ke Sini' : 'Belum ada alamat',
                      style: _cs(size: 13, weight: FontWeight.bold),
                    ),
                    Text(
                      address?.text ?? 'Tap "Ubah" untuk isi alamat pengiriman',
                      style: _cs(size: 11, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddressEditorSheet(),
                  );
                },
                child: Text(
                  'Ubah',
                  style: _cs(size: 12, weight: FontWeight.bold, color: _cGreen),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Satu baris pemilihan driver per gerai -- diberi label nama gerai
  // supaya jelas driver mana yang mengantar gerai yang mana.
  Widget _buildDriverSelectionForGerai(_GeraiGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.namaGerai,
            style: _cs(size: 12.5, weight: FontWeight.bold, color: _cGreen),
          ),
          const SizedBox(height: 6),
          _buildDriverSelectionList(group),
        ],
      ),
    );
  }

  // Horizontal list view of drivers, khusus untuk satu gerai. Sekarang
  // pakai data ASLI dari store_drivers (bukan mockDrivers) -- CATATAN:
  // belum ada konsep "sibuk" buat driver asli, jadi semua driver yang
  // terdaftar di toko itu ditampilkan sebagai bisa dipilih.
  Widget _buildDriverSelectionList(_GeraiGroup group) {
    if (group.sellerId == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Text(
          'Gerai ini belum terhubung ke sistem driver Nemu.',
          style: _cs(size: 11.5, color: Colors.black45),
        ),
      );
    }

    if (_loadingDriversForGerai.contains(group.key)) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _cGreen),
          ),
        ),
      );
    }

    final drivers = _driversByGerai[group.key] ?? const [];
    if (drivers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Text(
          'Toko ini belum punya driver terdaftar.',
          style: _cs(size: 11.5, color: Colors.black45),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: drivers.length,
        itemBuilder: (_, i) {
          final doc = drivers[i];
          final data = doc.data();
          final driverId = doc.id;
          final driverName = (data['driverName'] as String?) ?? 'Driver';
          final photoUrl = data['driverPhotoUrl'] as String?;
          final isSelected = _selectedDriverByGerai[group.key] == driverId;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDriverByGerai[group.key] = driverId);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              margin: const EdgeInsets.only(right: 10, bottom: 4),
              decoration: BoxDecoration(
                color: isSelected ? _cGreen : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _cGreen : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Text(
                              driverName.isNotEmpty ? driverName[0].toUpperCase() : '?',
                              style: _cs(size: 14, weight: FontWeight.bold, color: _cGreen),
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      driverName,
                      style: _cs(
                        size: 12,
                        weight: FontWeight.bold,
                        color: isSelected ? Colors.white : _cDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
          border: Border.all(
            color: selected ? _cGreen : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
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
              child: Icon(
                method.icon,
                color: selected ? _cGreen : Colors.grey.shade500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: _cs(
                      size: 13,
                      weight: FontWeight.bold,
                      color: selected ? _cGreen : _cDark,
                    ),
                  ),
                  Text(
                    method.desc,
                    style: _cs(size: 11, color: Colors.black45),
                  ),
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
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
              Text(
                'Total Pembayaran',
                style: _cs(size: 14, weight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                _cRupiah(_total),
                style: _cs(size: 18, weight: FontWeight.bold, color: _cGreen),
              ),
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

  Widget _itemSummaryRow(CartItem item) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${item.produk.nama} x${item.qty}',
            style: _cs(size: 12.5, color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          _cRupiah(item.produk.hargaSekarang * item.qty),
          style: _cs(size: 12.5, weight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _summaryRowWithNote({
    required IconData icon,
    required String label,
    required int amount,
    required String note,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.black38),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _cs(size: 13, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(note, style: _cs(size: 10.5, color: Colors.black38)),
            ],
          ),
        ),
        Text(_cRupiah(amount), style: _cs(size: 13, weight: FontWeight.w600)),
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
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: _cs(size: 12, color: Colors.black45)),
              Text(
                _cRupiah(_total),
                style: _cs(size: 16, weight: FontWeight.bold, color: _cGreen),
              ),
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
                          offset: const Offset(0, 5),
                        ),
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
                    : Text(
                        'Pesan Sekarang',
                        style: _cs(
                          size: 15,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
          Text(
            'Keranjang kosong',
            style: _cs(size: 18, weight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan produk dari pasar dulu yuk!',
            style: _cs(size: 13, color: Colors.black45),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _cGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Belanja Sekarang',
                style: _cs(
                  size: 14,
                  weight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
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
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pesanan Berhasil!',
              style: _cs(size: 20, weight: FontWeight.bold),
            ),
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
                    colors: [Color(0xFF00A851), _cGreen],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Lihat Pesanan',
                    style: _cs(
                      size: 14,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
class _GeraiGroup {
  final String key;
  final String? geraiId;
  final String namaGerai;
  final String namaMarket;
  final String? sellerId;
  final List<CartItem> items = [];

  _GeraiGroup({
    required this.key,
    required this.geraiId,
    required this.namaGerai,
    required this.namaMarket,
    required this.sellerId,
  });
}

class _PaymentMethod {
  final IconData icon;
  final String label;
  final String desc;
  const _PaymentMethod({
    required this.icon,
    required this.label,
    required this.desc,
  });
}