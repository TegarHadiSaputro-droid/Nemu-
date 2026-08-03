import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
//  Warna Palette
// ─────────────────────────────────────────────
const Color _yellowTop   = Color(0xFFD9DF36);
const Color _greenBottom = Color(0xFF007C3F);
const Color _textDark    = Color(0xFF0F1B11);

// ─────────────────────────────────────────────
//  Helper: TextStyle Manrope
// ─────────────────────────────────────────────
TextStyle _m({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _textDark,
  double? height,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

// ─────────────────────────────────────────────
//  HomeScreen
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _navIndex = 0;
  int _bannerIndex = 0;
  int _selectedCommodityIndex = 0;
  int? _touchedDataPointIndex; // Untuk tooltip interaktif di grafik

  final PageController _pageCtrl = PageController();
  Timer? _autoScrollTimer;

  // Animasi grafik
  late AnimationController _chartAnimCtrl;
  late Animation<double> _chartAnimation;

  String _userName = 'Sobat Nemu'; // placeholder sebelum nickname dimuat/diisi
  int _cartItemCount = 1;
  bool _isDelivering = true; // State status pengantaran
  
  static const List<String> _welcomeGreetings = [
    'Sini mampir enggih!',                   // Jawa Tengah / Solo
    'Sampurasun, hayu mampir euy!',          // Sunda (Jawa Barat)
    'Mai singgah bli, santai aja!',          // Bali
    'Horas lae, mampir jo!',                 // Batak (Sumatera Utara)
    'Kuy lah mampir dimari!',                // Betawi (Jakarta)
    'Mari jo mampir sini, kawan!',           // Manado (Sulawesi Utara)
    'Yo ipar, mari mampir!',                 // Papua
    'Monggo pinarak mase!',                  // Jawa Timur / Surabaya
    'Wee mampir maki\' bro!',                // Makassar (Sulawesi Selatan)
    'Mampir lah sutan, rancak bana!',        // Minangkabau (Sumatera Barat)
    'Sok mangga lebet teh, kang!',           // Sunda (Priangan)
    'Lakasi mampir wal, rami nih!',          // Banjar (Kalimantan Selatan)
    'Tabik pun, mampir pay!',                // Lampung
    'Mejuah-juah, mampir mari!',             // Karo (Sumatera Utara)
    'Ngereng mampir taretan!',               // Madura (Jawa Timur)
    'Mampir nyok gaes, seru nih!',           // Betawi slang (Jakarta)
    'Salam takzim, singgah dulu yuk!',       // Melayu (Riau / Kepulauan)
    'Yo pace mace, mari rapat!',             // Papua (Jayapura)
    'Mai melali bli, seru abis!',            // Bali (casual)
    'Monggo pinarak mbakyu!',                // Jawa (Yogyakarta)
  ];
  String _welcomeGreeting = 'Halo, selamat datang!';

  // ── Data State dari API Backend ──
  List<_BannerData> _banners = const [
    _BannerData(tag: 'FRESH TODAY', title: 'Belanja Bahan Segar\nTanpa Ke Pasar', sub: 'Diantar langsung oleh mitra pedagang pasar.', bgColor: Colors.white, tagColor: _greenBottom, icon: Icons.eco_rounded),
    _BannerData(tag: 'PROMO', title: 'Ongkir Flat Rp2.000\nUntuk Jarak < 3 km', sub: 'Berlaku setiap hari untuk semua produk pasar.', bgColor: Colors.white, tagColor: Colors.orange, icon: Icons.local_shipping_rounded),
    _BannerData(tag: 'JASA', title: 'Panggil Tukang\nKapan Saja', sub: 'Tenaga ahli berpengalaman siap membantu kamu.', bgColor: Colors.white, tagColor: Colors.blue, icon: Icons.handyman_rounded),
  ];

  List<_CommodityData> _commodities = const [
    _CommodityData(name: 'Cabai Merah', icon: '🌶️', unit: '/kg', currentPrice: 42000, predictedPrice: 45000, changePercent: 7.1, isUp: true, predictionNote: 'Prediksi Besok: Naik ~Rp3.000 karena pasokan menurun.', historyPrices: [35000, 37000, 38000, 39500, 40000, 42000, 45000], days: ['5 hari lalu', '4 hari lalu', '3 hari lalu', 'Lusa', 'Kemarin', 'Hari Ini', 'Prediksi']),
    _CommodityData(name: 'Bawang Merah', icon: '🧅', unit: '/kg', currentPrice: 28000, predictedPrice: 26500, changePercent: 5.3, isUp: false, predictionNote: 'Prediksi Besok: Turun ~Rp1.500 karena panen lokal.', historyPrices: [33000, 32000, 31000, 30000, 29500, 28000, 26500], days: ['5 hari lalu', '4 hari lalu', '3 hari lalu', 'Lusa', 'Kemarin', 'Hari Ini', 'Prediksi']),
    _CommodityData(name: 'Tomat Segar', icon: '🍅', unit: '/kg', currentPrice: 12000, predictedPrice: 12000, changePercent: 0.0, isUp: false, predictionNote: 'Prediksi Besok: Stabil — pasokan cukup.', historyPrices: [11000, 11500, 12000, 11800, 12000, 12000, 12000], days: ['5 hari lalu', '4 hari lalu', '3 hari lalu', 'Lusa', 'Kemarin', 'Hari Ini', 'Prediksi']),
    _CommodityData(name: 'Daging Ayam', icon: '🍗', unit: '/kg', currentPrice: 36000, predictedPrice: 38000, changePercent: 5.5, isUp: true, predictionNote: 'Prediksi Besok: Naik mendekati akhir pekan.', historyPrices: [33000, 33500, 34000, 35000, 35500, 36000, 38000], days: ['5 hari lalu', '4 hari lalu', '3 hari lalu', 'Lusa', 'Kemarin', 'Hari Ini', 'Prediksi']),
    _CommodityData(name: 'Bawang Putih', icon: '🧄', unit: '/kg', currentPrice: 32000, predictedPrice: 31000, changePercent: 3.1, isUp: false, predictionNote: 'Prediksi Besok: Sedikit turun.', historyPrices: [34000, 33500, 33000, 32500, 32500, 32000, 31000], days: ['5 hari lalu', '4 hari lalu', '3 hari lalu', 'Lusa', 'Kemarin', 'Hari Ini', 'Prediksi']),
  ];

  List<_QuickProduct> _quickProducts = const [
    _QuickProduct(name: 'Kangkung Segar', store: 'Lapak Bu Sari', price: 3000, unit: '/ikat', icon: '🥬', restock: '1 jam lalu', imageUrl: 'assets/products/kangkung.jpg'),
    _QuickProduct(name: 'Tomat Merah', store: 'Lapak Bu Sari', price: 12000, unit: '/kg', icon: '🍅', restock: '30 mnt lalu', imageUrl: 'assets/products/tomat.jpg'),
    _QuickProduct(name: 'Tempe Papan', store: 'Kios Pak Budi', price: 4000, unit: '/papan', icon: '🍱', restock: '2 jam lalu', imageUrl: 'assets/products/tempe.jpg'),
    _QuickProduct(name: 'Cabai Keriting', store: 'Warung Tani', price: 42000, unit: '/kg', icon: '🌶️', restock: '45 mnt lalu', imageUrl: 'assets/products/cabai_keriting.jpg'),
    _QuickProduct(name: 'Bayam Hijau', store: 'Lapak Bu Sari', price: 4000, unit: '/ikat', icon: '🥗', restock: '20 mnt lalu', imageUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400&q=80'),
    _QuickProduct(name: 'Tahu Putih', store: 'Toko Harapan', price: 8000, unit: '/papan', icon: '🧈', restock: '1 jam lalu', imageUrl: 'assets/products/tahu.jpg'),
  ];

  List<_MarketStore> _stores = const [
    _MarketStore(name: 'Pasar Sepinggan', category: 'Sayur, Buah & Daging', rating: 4.8, distance: '1.5 km', isOpen: true),
    _MarketStore(name: 'Pasar Buton', category: 'Sembako & Rempah', rating: 4.6, distance: '4.8 km', isOpen: true),
    _MarketStore(name: 'Pasar Klandasan', category: 'Ikan & Seafood Segar', rating: 4.9, distance: '9.5 km', isOpen: true),
    _MarketStore(name: 'Pasar Pandansari', category: 'Beras & Palawija', rating: 4.7, distance: '13.0 km', isOpen: false),
  ];

  @override
  void initState() {
    super.initState();
    _welcomeGreeting = _welcomeGreetings[math.Random().nextInt(_welcomeGreetings.length)];
    _loadApiData();
    _loadNicknameOrAsk();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

    // Animasi chart saat pertama load & saat ganti komoditas
    _chartAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimCtrl,
      curve: Curves.easeOutCubic,
    );
    _chartAnimCtrl.forward();
  }

  /// Cek apakah user sudah punya nickname tersimpan di Firestore.
  /// Kalau belum (pertama kali masuk HomeScreen), tampilkan popup
  /// tanya "Nama panggilan Anda?" dan simpan jawabannya.
  Future<void> _loadNicknameOrAsk() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final existingNickname = doc.data()?['nickname'] as String?;

      if (existingNickname != null && existingNickname.trim().isNotEmpty) {
        if (mounted) setState(() => _userName = existingNickname);
      } else if (mounted) {
        // Tunggu frame pertama selesai render dulu supaya dialog muncul
        // rapi di atas HomeScreen, bukan nabrak proses build awal.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showNicknameDialog(user.uid);
        });
      }
    } catch (_) {
      // Kalau gagal ambil data (misal offline), biarkan pakai placeholder
      // default saja, tidak perlu ganggu user dengan error di sini.
    }
  }

  void _showNicknameDialog(String uid) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nama panggilan Anda?',
          style: _m(size: 18, weight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Contoh: Budi',
            hintStyle: _m(size: 14, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _greenBottom, width: 1.5),
            ),
          ),
          style: _m(size: 14),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _greenBottom,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final nickname = controller.text.trim();
                if (nickname.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'nickname': nickname});

                if (mounted) {
                  setState(() => _userName = nickname);
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(
                'Simpan',
                style: _m(size: 14, weight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadApiData() async {
    final apiData = await ApiService.fetchBerandaData();
    if (apiData != null && mounted) {
      setState(() {
        if (apiData['banners'] != null) {
          _banners = (apiData['banners'] as List).map((b) => _BannerData(
            tag: b['tag'] ?? '',
            title: b['title'] ?? '',
            sub: b['sub'] ?? '',
            bgColor: Colors.white,
            tagColor: _parseColor(b['tag_color']),
            icon: _parseIcon(b['icon']),
          )).toList();
        }

        if (apiData['commodities'] != null) {
          _commodities = (apiData['commodities'] as List).map((c) => _CommodityData(
            name: c['name'] ?? '',
            icon: c['icon'] ?? '🥦',
            unit: c['unit'] ?? '/kg',
            currentPrice: (c['current_price'] as num).toInt(),
            predictedPrice: (c['predicted_price'] as num).toInt(),
            changePercent: (c['change_percent'] as num).toDouble(),
            isUp: c['is_up'] ?? true,
            predictionNote: c['prediction_note'] ?? '',
            historyPrices: (c['history_prices'] as List).map((hp) => (hp as num).toInt()).toList(),
            days: (c['days'] as List).map((d) => d.toString()).toList(),
          )).toList();
        }

        if (apiData['quick_products'] != null) {
          _quickProducts = (apiData['quick_products'] as List).map((p) => _QuickProduct(
            name: p['name'] ?? '',
            store: p['store'] ?? '',
            price: (p['price'] as num).toInt(),
            unit: p['unit'] ?? '',
            icon: p['icon'] ?? '🥬',
            restock: p['restock'] ?? '',
            imageUrl: p['image_url'] ?? '',
          )).toList();
        }

        if (apiData['stores'] != null) {
          _stores = (apiData['stores'] as List).map((s) => _MarketStore(
            name: s['name'] ?? '',
            category: s['category'] ?? '',
            rating: (s['rating'] as num).toDouble(),
            distance: s['distance'] ?? '',
            isOpen: s['is_open'] ?? true,
          )).toList();
        }
      });
    }
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return _greenBottom;
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return _greenBottom;
    }
  }

  static IconData _parseIcon(String? name) {
    switch (name) {
      case 'local_shipping_rounded': return Icons.local_shipping_rounded;
      case 'handyman_rounded': return Icons.handyman_rounded;
      case 'eco_rounded':
      default: return Icons.eco_rounded;
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageCtrl.dispose();
    _chartAnimCtrl.dispose();
    super.dispose();
  }

  void _selectCommodity(int index) {
    setState(() {
      _selectedCommodityIndex = index;
      _touchedDataPointIndex = null;
    });
    _chartAnimCtrl.reset();
    _chartAnimCtrl.forward();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _welcomeGreeting = _welcomeGreetings[math.Random().nextInt(_welcomeGreetings.length)];
    });
    await ApiService.syncMarketPrices();
    await _loadApiData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Base Gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_yellowTop, _greenBottom],
              ),
            ),
          ),

          // ── Dekorasi Playful Background ──
          Positioned(top: -40, right: -50, child: _blob(200, Colors.white.withOpacity(0.12))),
          Positioned(top: 80, left: -60, child: _blob(160, Colors.white.withOpacity(0.10))),
          Positioned(top: 220, right: 20, child: _blob(80, Colors.white.withOpacity(0.08))),
          Positioned(top: 300, left: 30, child: _dot(18, Colors.white.withOpacity(0.20))),
          Positioned(top: 340, right: 60, child: _dot(10, Colors.white.withOpacity(0.18))),
          Positioned(bottom: 200, right: -40, child: _blob(150, const Color(0xFFD9DF36).withOpacity(0.18))),
          Positioned(bottom: 350, left: 10, child: _dot(14, Colors.white.withOpacity(0.15))),

          // ── Konten Utama ──
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: _greenBottom,
                      backgroundColor: Colors.white,
                      onRefresh: _handleRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Top Bar (Ikut scroll)
                            _buildTopBar(),
                            const SizedBox(height: 12),

                            // Search Bar
                            _buildSearchBar(),
                            const SizedBox(height: 14),

                            // Quick Info Row (Alamat & Kurir Pak Budi)
                            _buildQuickInfoRow(),
                            const SizedBox(height: 14),

                            // Banner Carousel (auto-scroll 10s)
                            _buildBannerCarousel(),
                            const SizedBox(height: 10),
                            _buildCarouselDots(),
                            const SizedBox(height: 20),

                            // 🛠️ 4. ELEMEN BARU 3: Quick Chips Jasa Tukang
                            _buildHandymanQuickChips(),
                            const SizedBox(height: 20),

                            // 3 Kategori Utama
                            _buildSectionTitle('Layanan Utama', 'Pilih kategori kebutuhanmu'),
                            const SizedBox(height: 12),
                            _buildCategoryRow(),
                            const SizedBox(height: 24),

                            // 📈 FEATURE GRAFIK PREDIKSI HARGA PASAR (Kotak Gede + Interaktif)
                            _buildSectionTitle('Pemantauan Harga Pasar', 'Pantau fluktuasi & prediksi harga komoditas terkini'),
                            const SizedBox(height: 12),
                            _buildInteractivePriceTrendSection(),
                            const SizedBox(height: 24),

                            // 🥦 5. ELEMEN BARU 4: Bahan Segar Kilat (Horizontal Scroll + Button Tambah)
                            _buildSectionTitle('Bahan Segar Langsung Lapak', 'Dipajang & diperbarui hari ini'),
                            const SizedBox(height: 12),
                            _buildQuickProductsScroll(),
                            const SizedBox(height: 24),

                            // Gerai Pasar Terdekat
                            _buildSectionTitle('Pasar Terdekat dari Rumah', 'Rekomendasi pasar tradisional di Kota Balikpapan'),
                            const SizedBox(height: 12),
                            _buildStoreList(),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Nav
                  _buildBottomNav(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  HELPER BACKGROUND
  // ──────────────────────────────────────────
  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _dot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ──────────────────────────────────────────
  //  1. TOP BAR
  // ──────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_welcomeGreeting,
                    style: _m(size: 13, color: _textDark.withOpacity(0.7))),
                const SizedBox(height: 2),
                Text(_userName,
                    style: _m(size: 20, weight: FontWeight.bold, color: _textDark)),
              ],
            ),
          ),

          // Cart dengan Ikon Troli
          Stack(
            clipBehavior: Clip.none,
            children: [
              _iconButton(Icons.shopping_cart_outlined),
              if (_cartItemCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: Text('$_cartItemCount', style: _m(size: 9, color: Colors.white, weight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
            ),
            child: const Icon(Icons.person, color: _greenBottom, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _textDark, size: 22),
    );
  }

  // ──────────────────────────────────────────
  //  SEARCH BAR
  // ──────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _greenBottom, size: 20),
          const SizedBox(width: 10),
          Text('Cari sayur, ikan, tukang...', style: _m(size: 13, color: Colors.black45)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _greenBottom.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('Filter', style: _m(size: 11, color: _greenBottom, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  QUICK INFO ROW (ALAMAT & KURIR)
  // ──────────────────────────────────────────
  Widget _buildQuickInfoRow() {
    return Row(
      children: [
        // Widget Alamat Kirim (Sebelah kiri)
        Expanded(
          child: _isDelivering
              ? _quickCard(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.redAccent,
                  title: 'Kirim ke Rumah',
                  sub: 'Rumah Egii (Jl. Mawar 12)',
                  bgColor: Colors.white,
                  onTap: () {
                    setState(() {
                      _isDelivering = false;
                      _welcomeGreeting = _welcomeGreetings[math.Random().nextInt(_welcomeGreetings.length)];
                    });
                  },
                )
              : _quickCard(
                  icon: Icons.location_on_rounded,
                  iconColor: _greenBottom,
                  title: 'Yuk Belanja!',
                  sub: 'Ubah Alamat',
                  bgColor: Colors.white,
                  subTextColor: _greenBottom,
                  onTap: () {
                    setState(() {
                      _isDelivering = true;
                      _welcomeGreeting = _welcomeGreetings[math.Random().nextInt(_welcomeGreetings.length)];
                    });
                  },
                ),
        ),
        const SizedBox(width: 12),
        // Widget Status Kurir (Sebelah kanan)
        Expanded(
          child: _isDelivering
              ? _quickCard(
                  icon: Icons.two_wheeler_rounded,
                  iconColor: Colors.white,
                  title: 'Pak Budi Antar',
                  sub: 'Est. 8 mnt • Lapak Sari',
                  bgColor: Colors.orange.shade700,
                  textColor: Colors.white,
                  subTextColor: Colors.white.withOpacity(0.9),
                  gradientColors: [Colors.orange.shade800, Colors.orange.shade600],
                  onTap: () {
                    setState(() {
                      _isDelivering = false;
                      _welcomeGreeting = _welcomeGreetings[math.Random().nextInt(_welcomeGreetings.length)];
                    });
                  },
                )
              : _quickCard(
                  icon: Icons.local_shipping_outlined,
                  iconColor: Colors.grey.shade600,
                  title: 'Tidak Ada Pengantaran',
                  sub: 'Mulai belanja yuk!',
                  bgColor: Colors.grey.shade200,
                  textColor: Colors.grey.shade800,
                  subTextColor: Colors.grey.shade500,
                  onTap: () {
                    setState(() {
                      _isDelivering = true;
                      _welcomeGreeting = _welcomeGreetings[math.Random().nextInt(_welcomeGreetings.length)];
                    });
                  },
                ),
        ),
      ],
    );
  }

  Widget _quickCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String sub,
    required Color bgColor,
    Color textColor = _textDark,
    Color subTextColor = Colors.black54,
    List<Color>? gradientColors,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: gradientColors == null ? bgColor : null,
          gradient: gradientColors != null ? LinearGradient(colors: gradientColors) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (gradientColors != null ? gradientColors.first : Colors.black).withOpacity(gradientColors != null ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gradientColors != null ? Colors.white.withOpacity(0.2) : iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: gradientColors != null ? Colors.white : iconColor, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _m(size: 11, weight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: _m(
                      size: 9.5,
                      color: subTextColor,
                      weight: subTextColor == _greenBottom ? FontWeight.w800 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  //  BANNER CAROUSEL
  // ──────────────────────────────────────────
  Widget _buildBannerCarousel() {
    return SizedBox(
      height: 185,
      child: PageView.builder(
        controller: _pageCtrl,
        itemCount: _banners.length,
        onPageChanged: (i) => setState(() => _bannerIndex = i),
        itemBuilder: (_, i) => _buildBannerCard(_banners[i]),
      ),
    );
  }

  Widget _buildBannerCard(_BannerData b) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: b.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: b.tagColor.withOpacity(0.4), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: b.tagColor, borderRadius: BorderRadius.circular(20)),
            child: Text(b.tag, style: _m(size: 10, weight: FontWeight.bold, color: Colors.white)),
          ),
          const Spacer(),
          Text(b.title, style: _m(size: 16, weight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 4),
          Text(b.sub, style: _m(size: 11.5, color: Colors.black54)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: b.tagColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            child: Text('Lihat Detail', style: _m(size: 11, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (i) {
        final active = i == _bannerIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ──────────────────────────────────────────
  //  🛠️ 4. QUICK CHIPS JASA TUKANG
  // ──────────────────────────────────────────
  Widget _buildHandymanQuickChips() {
    final chips = [
      {'label': 'Pipa & Bocor', 'icon': Icons.plumbing_rounded, 'color': Colors.blue},
      {'label': 'Servis AC', 'icon': Icons.ac_unit_rounded, 'color': Colors.cyan},
      {'label': 'Tukang Listrik', 'icon': Icons.flash_on_rounded, 'color': Colors.amber.shade800},
      {'label': 'Angkut Barang', 'icon': Icons.local_shipping_rounded, 'color': Colors.deepOrange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Panggil Tukang Cepat', 'Tenaga ahli siap datang ke rumah'),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: chips.length,
            itemBuilder: (_, i) {
              final item = chips[i];
              final color = item['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(item['label'] as String, style: _m(size: 11, weight: FontWeight.bold, color: _textDark)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  //  SECTION TITLE
  // ──────────────────────────────────────────
  Widget _buildSectionTitle(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _m(size: 15, weight: FontWeight.bold, color: Colors.white)),
        Text(sub, style: _m(size: 11, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  // ──────────────────────────────────────────
  //  KATEGORI
  // ──────────────────────────────────────────
  Widget _buildCategoryRow() {
    final cats = [
      {'label': 'Gerai Pasar', 'icon': Icons.storefront_rounded, 'color': const Color(0xFF1B7A3E)},
      {'label': 'Cek Harga', 'icon': Icons.show_chart_rounded, 'color': const Color(0xFF1565C0)},
      {'label': 'Jasa Tukang', 'icon': Icons.handyman_rounded, 'color': const Color(0xFFE65100)},
    ];

    return Row(
      children: cats.map((c) {
        final color = c['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 94,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(c['icon'] as IconData, color: color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(c['label'] as String, style: _m(size: 11, weight: FontWeight.bold), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  📈 HARGA PASAR HARI INI — KOTAK GEDE GRAFIK INTERAKTIF
  //     Dengan diagram garis, label harga Y-axis, tooltip sentuh,
  //     prediksi dashed line, dan switch komoditas tabs
  // ══════════════════════════════════════════════════════════════
  Widget _buildInteractivePriceTrendSection() {
    final selected = _commodities[_selectedCommodityIndex];
    final chartLineColor = selected.isUp ? Colors.redAccent : _greenBottom;

    // Hitung min/max untuk label Y-axis
    final prices = selected.historyPrices;
    final minP = prices.reduce(math.min);
    final maxP = prices.reduce(math.max);
    final midP = ((minP + maxP) / 2).round();

    // Perubahan hari ini vs kemarin
    final todayIdx = prices.length - 2; // "Hari Ini" index
    final yesterdayIdx = prices.length - 3; // "Kemarin" index
    final hariIni = prices[todayIdx];
    final kemarin = prices[yesterdayIdx];
    final selisih = hariIni - kemarin;
    final selisihLabel = selisih >= 0 ? '+Rp${_formatPrice(selisih.abs())}' : '-Rp${_formatPrice(selisih.abs())}';

    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _greenBottom.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: _greenBottom, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harga Pasar Hari Ini', style: _m(size: 15, weight: FontWeight.bold)),
                        Text('Pasar Mayestik — Data realtime', style: _m(size: 10, color: Colors.black45)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: Colors.green.shade500, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('LIVE', style: _m(size: 9, weight: FontWeight.bold, color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Tab Selector Komoditas (Horizontal Scroll) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _commodities.length,
                itemBuilder: (_, i) {
                  final isSelected = _selectedCommodityIndex == i;
                  final c = _commodities[i];
                  return GestureDetector(
                    onTap: () => _selectCommodity(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _greenBottom : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: isSelected
                            ? [BoxShadow(color: _greenBottom.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Text(c.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            c.name,
                            style: _m(
                              size: 12,
                              weight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Ringkasan Harga: Hari Ini vs Kemarin vs Prediksi ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Harga Hari Ini (Utama)
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(selected.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text(selected.name, style: _m(size: 12, color: Colors.black54, weight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rp${_formatPrice(selected.currentPrice)}',
                              style: _m(size: 24, weight: FontWeight.bold, color: _textDark),
                            ),
                            const SizedBox(width: 2),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(selected.unit, style: _m(size: 11, color: Colors.black45)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: selected.isUp ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    selected.isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                    size: 13,
                                    color: selected.isUp ? Colors.red.shade600 : Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${selected.changePercent}%',
                                    style: _m(
                                      size: 10,
                                      weight: FontWeight.bold,
                                      color: selected.isUp ? Colors.red.shade600 : Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'vs kemarin $selisihLabel',
                              style: _m(size: 9.5, color: Colors.black45),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Info Kemarin & Prediksi (2 kolom kecil)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _miniPriceBox(
                          label: 'Kemarin',
                          price: kemarin,
                          icon: Icons.history_rounded,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(height: 8),
                        _miniPriceBox(
                          label: 'Prediksi Besok',
                          price: selected.predictedPrice,
                          icon: Icons.auto_graph_rounded,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ══════════════════════════════════════
          //  📊 KOTAK GEDE: GRAFIK GARIS (LINE CHART)
          //     Dengan Y-axis labels, tooltip, dashed prediction
          // ══════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Grafik Utama dengan Y-axis labels
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 12, 0),
                    child: SizedBox(
                      height: 220,
                      child: Row(
                        children: [
                          // Y-Axis Price Labels
                          SizedBox(
                            width: 52,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_shortPrice(maxP), style: _m(size: 9, color: Colors.black38, weight: FontWeight.w600)),
                                Text(_shortPrice(midP), style: _m(size: 9, color: Colors.black38, weight: FontWeight.w600)),
                                Text(_shortPrice(minP), style: _m(size: 9, color: Colors.black38, weight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Chart Area
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _chartAnimation,
                              builder: (context, child) {
                                return GestureDetector(
                                  onTapDown: (details) {
                                    _handleChartTap(details, prices);
                                  },
                                  onTapUp: (_) {
                                    // Keep tooltip visible
                                  },
                                  child: CustomPaint(
                                    size: const Size(double.infinity, 220),
                                    painter: _EnhancedLineChartPainter(
                                      prices: prices,
                                      lineColor: chartLineColor,
                                      animationValue: _chartAnimation.value,
                                      touchedIndex: _touchedDataPointIndex,
                                      predictionStartIndex: prices.length - 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // X-Axis Day Labels
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 12, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: selected.days.map((d) {
                        final isPrediction = d.contains('Prediksi');
                        final isToday = d == 'Hari Ini';
                        return Expanded(
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: _m(
                              size: 8,
                              weight: (isPrediction || isToday) ? FontWeight.bold : FontWeight.normal,
                              color: isPrediction
                                  ? Colors.deepPurple
                                  : isToday
                                      ? _greenBottom
                                      : Colors.black38,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tooltip Info (jika titik disentuh) ──
          if (_touchedDataPointIndex != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTouchTooltip(selected),
            ),
          ],

          const SizedBox(height: 12),

          // ── Legend Grafik ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _legendDot(chartLineColor, 'Harga Aktual'),
                const SizedBox(width: 16),
                _legendDot(Colors.deepPurple.shade300, 'Prediksi Pasar'),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _touchedDataPointIndex = null),
                  child: Text('Ketuk titik grafik ☝️', style: _m(size: 9, color: Colors.black38)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Container(height: 1, color: Colors.grey.shade100),

          // ── Catatan Prediksi Harga ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_greenBottom.withOpacity(0.08), Colors.deepPurple.withOpacity(0.04)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _greenBottom.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _greenBottom.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: _greenBottom, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prediksi Harga Besok', style: _m(size: 10, weight: FontWeight.bold, color: _greenBottom)),
                        const SizedBox(height: 2),
                        Text(
                          selected.predictionNote,
                          style: _m(size: 10.5, weight: FontWeight.w500, color: Colors.black87, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mini price info box untuk Kemarin / Prediksi
  Widget _miniPriceBox({
    required String label,
    required int price,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _m(size: 8.5, color: Colors.black45)),
                Text(
                  'Rp${_formatPrice(price)}',
                  style: _m(size: 11, weight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Legend dot for chart
  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: _m(size: 9, color: Colors.black54)),
      ],
    );
  }

  /// Handle tap on chart to show tooltip
  void _handleChartTap(TapDownDetails details, List<int> prices) {
    // Dapatkan lebar chart area dari context (approximate)
    // Chart area ~= screenWidth - 16*2 padding - 52 y-axis - 4 gap - 12 right padding
    final screenWidth = MediaQuery.of(context).size.width;
    final chartWidth = screenWidth - 16 * 2 - 52 - 4 - 12;
    final stepX = chartWidth / (prices.length - 1);

    // Offset relatif terhadap chart area
    final tapX = details.localPosition.dx;
    final tappedIndex = (tapX / stepX).round().clamp(0, prices.length - 1);

    setState(() {
      _touchedDataPointIndex = tappedIndex;
    });
  }

  /// Build tooltip box saat titik di-tap
  Widget _buildTouchTooltip(_CommodityData selected) {
    final idx = _touchedDataPointIndex!;
    final price = selected.historyPrices[idx];
    final day = selected.days[idx];
    final isPrediction = day.contains('Prediksi');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isPrediction ? Colors.deepPurple.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrediction ? Colors.deepPurple.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPrediction ? Icons.auto_graph_rounded : Icons.touch_app_rounded,
            size: 18,
            color: isPrediction ? Colors.deepPurple : Colors.blue.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPrediction ? '🔮 Prediksi Harga Besok' : '📅 $day',
                  style: _m(
                    size: 10,
                    weight: FontWeight.bold,
                    color: isPrediction ? Colors.deepPurple : Colors.blue.shade700,
                  ),
                ),
                Text(
                  '${selected.icon} ${selected.name}: Rp${_formatPrice(price)}${selected.unit}',
                  style: _m(size: 12, weight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (idx > 0) ...[
            Builder(builder: (_) {
              final diff = price - selected.historyPrices[idx - 1];
              final isUp = diff > 0;
              final isStable = diff == 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isStable
                      ? Colors.grey.shade100
                      : isUp
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isStable
                      ? 'Stabil'
                      : '${isUp ? "+" : "-"}Rp${_formatPrice(diff.abs())}',
                  style: _m(
                    size: 9,
                    weight: FontWeight.bold,
                    color: isStable
                        ? Colors.grey
                        : isUp
                            ? Colors.red.shade600
                            : Colors.green.shade600,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  🥦 5. BAHAN SEGAR KILAT (HORIZONTAL SCROLL + BUTTON TAMBAH)
  // ──────────────────────────────────────────
  Widget _buildQuickProductsScroll() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickProducts.length,
        itemBuilder: (_, i) {
          final item = _quickProducts[i];
          return GestureDetector(
            onTap: () {
              setState(() => _cartItemCount++);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} ditambahkan ke keranjang!', style: _m(size: 11, color: Colors.white)),
                  duration: const Duration(seconds: 1),
                  backgroundColor: _greenBottom,
                ),
              );
            },
            child: Container(
              width: 155,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                     // ── Foto Produk Real (Unsplash / Local Asset) ──
                    item.imageUrl.isNotEmpty
                      ? (item.imageUrl.startsWith('http')
                          ? Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                );
                              },
                              errorBuilder: (ctx, _, __) => Container(
                                color: Colors.grey.shade200,
                                child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 40))),
                              ),
                            )
                          : Image.asset(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) => Container(
                                color: Colors.grey.shade200,
                                child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 40))),
                              ),
                            ))
                      : Container(
                          color: Colors.grey.shade200,
                          child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 40))),
                        ),

                    // ── Gradient Gelap Bawah (Info Produk) ──
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.25),
                              Colors.black.withOpacity(0.80),
                            ],
                            stops: const [0.35, 0.60, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // ── Badge Restock (Pojok Kanan Atas) ──
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item.restock, style: _m(size: 8, weight: FontWeight.bold, color: _greenBottom)),
                      ),
                    ),

                    // ── Info Bawah: Nama, Lapak, Harga + Tombol + ──
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name,
                            style: _m(size: 12.5, weight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.store,
                            style: _m(size: 9.5, color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rp${_formatPrice(item.price)}${item.unit}',
                                style: _m(size: 11, weight: FontWeight.bold, color: Colors.white),
                              ),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: _greenBottom,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
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



  // ──────────────────────────────────────────
  //  DAFTAR GERAI PASAR
  // ──────────────────────────────────────────
  Widget _buildStoreList() {
    return Column(
      children: _stores.map((s) => _buildStoreCard(s)).toList(),
    );
  }

  Widget _buildStoreCard(_MarketStore s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _greenBottom.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded, color: _greenBottom, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: _m(size: 13, weight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(s.category, style: _m(size: 11, color: Colors.black54)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text('${s.rating}', style: _m(size: 11, weight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 13),
                    const SizedBox(width: 2),
                    Text(s.distance, style: _m(size: 11, color: Colors.black45)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.isOpen ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.isOpen ? 'Buka' : 'Tutup',
                  style: _m(
                    size: 10,
                    weight: FontWeight.bold,
                    color: s.isOpen ? Colors.green.shade700 : Colors.red.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: s.isOpen ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _greenBottom,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                ),
                child: Text('Masuk', style: _m(size: 11, weight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  BOTTOM NAV
  // ──────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_filled, 'label': 'Beranda'},
      {'icon': Icons.eco_rounded, 'label': 'Pasar'},
      {'icon': Icons.search_rounded, 'label': 'Cari'},
      {'icon': Icons.people_alt_rounded, 'label': 'Mitra'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Pesanan'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = _navIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _navIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _greenBottom.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i]['icon'] as IconData,
                    color: selected ? _greenBottom : Colors.black38,
                    size: 24,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i]['label'] as String,
                    style: _m(
                      size: 10,
                      weight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? _greenBottom : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}.${(price % 1000).toString().padLeft(3, '0')}';
    }
    return price.toString();
  }

  String _shortPrice(int price) {
    if (price >= 1000) {
      final k = price / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}rb';
    }
    return 'Rp$price';
  }
}

// ─────────────────────────────────────────────
// 📈 ENHANCED LINE CHART CUSTOM PAINTER
//    Dengan: gradient fill, garis halus, titik data,
//    dashed line untuk prediksi, grid horizontal,
//    tooltip highlight, dan animasi masuk
// ─────────────────────────────────────────────
class _EnhancedLineChartPainter extends CustomPainter {
  final List<int> prices;
  final Color lineColor;
  final double animationValue;
  final int? touchedIndex;
  final int predictionStartIndex;

  _EnhancedLineChartPainter({
    required this.prices,
    required this.lineColor,
    required this.animationValue,
    required this.touchedIndex,
    required this.predictionStartIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    final paddingTop = 15.0;
    final paddingBottom = 15.0;
    final chartHeight = size.height - paddingTop - paddingBottom;

    final minPrice = prices.reduce(math.min).toDouble();
    final maxPrice = prices.reduce(math.max).toDouble();
    final priceRange = (maxPrice - minPrice) == 0 ? 1.0 : (maxPrice - minPrice);

    // Hitung titik-titik data
    final points = <Offset>[];
    final stepX = size.width / (prices.length - 1);
    for (int i = 0; i < prices.length; i++) {
      final x = i * stepX;
      final normalizedY = (prices[i] - minPrice) / priceRange;
      final y = paddingTop + chartHeight - (normalizedY * chartHeight);
      points.add(Offset(x, y));
    }

    // ── 1. Grid horizontal (garis tipis) ──
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ── 2. Garis data aktual (solid) ──
    final actualEndIndex = predictionStartIndex.clamp(0, points.length - 1);

    // Path untuk garis aktual (sampai "Hari Ini")
    if (actualEndIndex > 0) {
      final actualPath = Path();
      actualPath.moveTo(points[0].dx, _lerp(size.height, points[0].dy, animationValue));
      for (int i = 1; i <= actualEndIndex; i++) {
        final prev = points[i - 1];
        final cur = points[i];
        final prevY = _lerp(size.height, prev.dy, animationValue);
        final curY = _lerp(size.height, cur.dy, animationValue);
        final cp1 = Offset(prev.dx + stepX / 2, prevY);
        final cp2 = Offset(cur.dx - stepX / 2, curY);
        actualPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, cur.dx, curY);
      }

      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(actualPath, linePaint);

      // Gradient fill di bawah garis aktual
      final fillPath = Path.from(actualPath)
        ..lineTo(points[actualEndIndex].dx, size.height)
        ..lineTo(0, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withOpacity(0.20 * animationValue), lineColor.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    // ── 3. Garis prediksi (dashed) ──
    if (actualEndIndex < points.length - 1) {
      final predStart = points[actualEndIndex];
      final predEnd = points[points.length - 1];
      final predStartY = _lerp(size.height, predStart.dy, animationValue);
      final predEndY = _lerp(size.height, predEnd.dy, animationValue);

      _drawDashedLine(
        canvas,
        Offset(predStart.dx, predStartY),
        Offset(predEnd.dx, predEndY),
        Paint()
          ..color = Colors.deepPurple.shade300
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
        dashWidth: 6,
        dashGap: 4,
      );

      // Gradient fill prediksi
      final predFillPath = Path()
        ..moveTo(predStart.dx, predStartY)
        ..lineTo(predEnd.dx, predEndY)
        ..lineTo(predEnd.dx, size.height)
        ..lineTo(predStart.dx, size.height)
        ..close();

      final predFillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepPurple.withOpacity(0.10 * animationValue), Colors.deepPurple.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(predFillPath, predFillPaint);
    }

    // ── 4. Titik data (dots) ──
    for (int i = 0; i < points.length; i++) {
      final p = Offset(points[i].dx, _lerp(size.height, points[i].dy, animationValue));
      final isTouched = touchedIndex == i;
      final isPrediction = i >= predictionStartIndex;

      final dotColor = isPrediction ? Colors.deepPurple.shade300 : lineColor;

      if (isTouched) {
        // Lingkaran highlight besar saat disentuh
        canvas.drawCircle(p, 12, Paint()..color = dotColor.withOpacity(0.15));
        canvas.drawCircle(p, 8, Paint()..color = dotColor.withOpacity(0.25));
      }

      // Dot utama
      canvas.drawCircle(p, isTouched ? 6 : 4.5, Paint()..color = dotColor);
      canvas.drawCircle(p, isTouched ? 3 : 2, Paint()..color = Colors.white);

      // Label harga di atas titik "Hari Ini" dan "Prediksi"
      if (i == predictionStartIndex - 1 || i == predictionStartIndex) {
        final priceText = 'Rp${(prices[i] / 1000).toStringAsFixed(0)}rb';
        final textSpan = TextSpan(
          text: priceText,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isPrediction ? Colors.deepPurple.shade400 : lineColor,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(p.dx - textPainter.width / 2, p.dy - 18),
        );
      }
    }
  }

  double _lerp(double from, double to, double t) {
    return from + (to - from) * t;
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 5,
    double dashGap = 3,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / distance;
    final unitDy = dy / distance;

    double currentDistance = 0;
    bool draw = true;
    while (currentDistance < distance) {
      final segmentLength = draw ? dashWidth : dashGap;
      final endDistance = math.min(currentDistance + segmentLength, distance);
      if (draw) {
        canvas.drawLine(
          Offset(start.dx + unitDx * currentDistance, start.dy + unitDy * currentDistance),
          Offset(start.dx + unitDx * endDistance, start.dy + unitDy * endDistance),
          paint,
        );
      }
      currentDistance = endDistance;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedLineChartPainter oldDelegate) {
    return oldDelegate.prices != prices ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.touchedIndex != touchedIndex;
  }
}

// ─────────────────────────────────────────────
//  Model Classes
// ─────────────────────────────────────────────
class _BannerData {
  final String tag, title, sub;
  final Color bgColor, tagColor;
  final IconData icon;
  const _BannerData({
    required this.tag,
    required this.title,
    required this.sub,
    required this.bgColor,
    required this.tagColor,
    required this.icon,
  });
}

class _CommodityData {
  final String name, icon, unit, predictionNote;
  final int currentPrice, predictedPrice;
  final double changePercent;
  final bool isUp;
  final List<int> historyPrices;
  final List<String> days;
  const _CommodityData({
    required this.name,
    required this.icon,
    required this.unit,
    required this.currentPrice,
    required this.predictedPrice,
    required this.changePercent,
    required this.isUp,
    required this.predictionNote,
    required this.historyPrices,
    required this.days,
  });
}

class _QuickProduct {
  final String name, store, unit, icon, restock, imageUrl;
  final int price;
  const _QuickProduct({
    required this.name,
    required this.store,
    required this.price,
    required this.unit,
    required this.icon,
    required this.restock,
    this.imageUrl = '',
  });
}

class _MarketStore {
  final String name, category, distance;
  final double rating;
  final bool isOpen;
  const _MarketStore({
    required this.name,
    required this.category,
    required this.rating,
    required this.distance,
    required this.isOpen,
  });
}