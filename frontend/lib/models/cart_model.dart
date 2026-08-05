import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────
//  Model: Produk Pasar (dengan harga kemarin & sekarang)
// ─────────────────────────────────────────────
class PasarProduk {
  final String id;
  final String nama;
  final String emoji;
  final String satuan;
  final int hargaKemarin;
  final int hargaSekarang;
  final String deskripsi;

  const PasarProduk({
    required this.id,
    required this.nama,
    required this.emoji,
    required this.satuan,
    required this.hargaKemarin,
    required this.hargaSekarang,
    required this.deskripsi,
  });

  // Get status harga (naik = true, turun = false, stabil = null)
  bool? get statusHarga {
    if (hargaSekarang > hargaKemarin) return true; // Naik (Merah)
    if (hargaSekarang < hargaKemarin) return false; // Turun (Hijau)
    return null; // Stabil
  }
}

// ─────────────────────────────────────────────
//  Model: Gerai / Warung Pasar
// ─────────────────────────────────────────────
class PasarGerai {
  final String id;
  final String nama;
  final String deskripsi;
  final double rating;
  final int ulasan;
  final String emoji;
  final List<PasarProduk> produk;

  const PasarGerai({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.rating,
    required this.ulasan,
    required this.emoji,
    required this.produk,
  });
}

// ─────────────────────────────────────────────
//  Model: Pasar / Market
// ─────────────────────────────────────────────
class PasarMarket {
  final String id;
  final String nama;
  final String kategori;
  final double rating;
  final String jarak;
  final bool buka;
  final String jamBuka;
  final String alamat;
  final List<PasarGerai> gerai;

  const PasarMarket({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.rating,
    required this.jarak,
    required this.buka,
    required this.jamBuka,
    required this.alamat,
    required this.gerai,
  });
}

// ─────────────────────────────────────────────
//  Model: Driver
// ─────────────────────────────────────────────
class Driver {
  final String id;
  final String nama;
  final double rating;
  final bool sibuk;
  final String emoji;

  const Driver({
    required this.id,
    required this.nama,
    required this.rating,
    required this.sibuk,
    required this.emoji,
  });
}

// ─────────────────────────────────────────────
//  Model: Cart Item
// ─────────────────────────────────────────────
class CartItem {
  final PasarProduk produk;
  int qty;
  final String namaGerai;
  final String namaMarket;

  CartItem({
    required this.produk,
    required this.qty,
    required this.namaGerai,
    required this.namaMarket,
  });

  int get subtotal => produk.hargaSekarang * qty;
}

// ─────────────────────────────────────────────
//  Cart Manager — Singleton reactive state
// ─────────────────────────────────────────────
class CartManager {
  CartManager._();
  static final CartManager instance = CartManager._();

  final ValueNotifier<List<CartItem>> items = ValueNotifier([]);

  int get totalQty => items.value.fold(0, (sum, i) => sum + i.qty);
  int get totalHarga => items.value.fold(0, (sum, i) => sum + i.subtotal);

  void tambah(PasarProduk produk, int qty, String namaGerai, String namaMarket) {
    final list = List<CartItem>.from(items.value);
    final idx = list.indexWhere((c) => c.produk.id == produk.id);
    if (idx >= 0) {
      list[idx].qty += qty;
    } else {
      list.add(CartItem(produk: produk, qty: qty, namaGerai: namaGerai, namaMarket: namaMarket));
    }
    items.value = list;
  }

  void hapus(String produkId) {
    items.value = items.value.where((c) => c.produk.id != produkId).toList();
  }

  void ubahQty(String produkId, int qty) {
    final list = List<CartItem>.from(items.value);
    final idx = list.indexWhere((c) => c.produk.id == produkId);
    if (idx >= 0) {
      if (qty <= 0) {
        list.removeAt(idx);
      } else {
        list[idx].qty = qty;
      }
    }
    items.value = list;
  }

  void kosongkan() => items.value = [];
}

// ─────────────────────────────────────────────
//  Mock Data Driver
// ─────────────────────────────────────────────
final List<Driver> mockDrivers = [
  const Driver(id: 'd1', nama: 'Pak Budi', rating: 4.9, sibuk: false, emoji: '🚴'),
  const Driver(id: 'd2', nama: 'Mas Anton', rating: 4.8, sibuk: false, emoji: '🏍️'),
  const Driver(id: 'd3', nama: 'Pak Eko', rating: 4.7, sibuk: true, emoji: '🛵'),
  const Driver(id: 'd4', nama: 'Bang Jamil', rating: 4.9, sibuk: false, emoji: '🚴'),
  const Driver(id: 'd5', nama: 'Kang Asep', rating: 4.6, sibuk: true, emoji: '🏍️'),
];

// ─────────────────────────────────────────────
//  Mock Data Pasar & Gerai & Produk
// ─────────────────────────────────────────────
final List<PasarMarket> mockDaftarPasar = [
  PasarMarket(
    id: 'p1',
    nama: 'Pasar Sepinggan',
    kategori: 'Sayur, Buah & Daging',
    rating: 4.8,
    jarak: '1.5 km',
    buka: true,
    jamBuka: '05.00 – 14.00',
    alamat: 'Jl. Marsma Iswahyudi, Sepinggan, Balikpapan',
    gerai: [
      PasarGerai(
        id: 'p1-g1',
        nama: 'Gerai Bu Eko',
        deskripsi: 'Menyediakan sayur mayur segar langsung dari kebun lokal.',
        rating: 4.9,
        ulasan: 124,
        emoji: '🥬',
        produk: [
          PasarProduk(id: 'p1-g1-1', nama: 'Tomat Segar', emoji: '🍅', satuan: 'kg', hargaKemarin: 14000, hargaSekarang: 12000, deskripsi: 'Tomat segar pilihan, merah merona dan kaya vitamin C.'),
          PasarProduk(id: 'p1-g1-2', nama: 'Kangkung Segar', emoji: '🌿', satuan: 'ikat', hargaKemarin: 3000, hargaSekarang: 4000, deskripsi: 'Kangkung hidroponik bersih tanpa ulat, siap dimasak tumis.'),
          PasarProduk(id: 'p1-g1-3', nama: 'Bawang Putih', emoji: '🧄', satuan: 'kg', hargaKemarin: 32000, hargaSekarang: 32000, deskripsi: 'Bawang putih pilihan dengan ukuran besar dan wangi khas.'),
          PasarProduk(id: 'p1-g1-4', nama: 'Cabai Merah', emoji: '🌶️', satuan: 'kg', hargaKemarin: 45000, hargaSekarang: 42000, deskripsi: 'Cabai merah keriting tingkat kepedasan sedang.'),
        ],
      ),
      PasarGerai(
        id: 'p1-g2',
        nama: 'Lapak Pak Joko',
        deskripsi: 'Spesialis daging ayam dan sapi segar bersertifikasi halal.',
        rating: 4.8,
        ulasan: 98,
        emoji: '🍗',
        produk: [
          PasarProduk(id: 'p1-g2-1', nama: 'Daging Ayam Potong', emoji: '🍗', satuan: 'kg', hargaKemarin: 35000, hargaSekarang: 36000, deskripsi: 'Daging ayam segar dipotong pagi ini.'),
          PasarProduk(id: 'p1-g2-2', nama: 'Daging Sapi Has Dalam', emoji: '🥩', satuan: 'kg', hargaKemarin: 130000, hargaSekarang: 125000, deskripsi: 'Daging sapi segar tanpa lemak, sangat empuk.'),
        ],
      ),
      PasarGerai(
        id: 'p1-g3',
        nama: 'Toko Sembako Bu Minah',
        deskripsi: 'Kebutuhan harian, beras, minyak goreng, dan sembako terlengkap.',
        rating: 4.7,
        ulasan: 82,
        emoji: '🌾',
        produk: [
          PasarProduk(id: 'p1-g3-1', nama: 'Beras Premium', emoji: '🌾', satuan: 'kg', hargaKemarin: 14000, hargaSekarang: 14000, deskripsi: 'Beras premium pulen wangi asli Kalimantan.'),
          PasarProduk(id: 'p1-g3-2', nama: 'Minyak Goreng Sunco', emoji: '🛢️', satuan: 'liter', hargaKemarin: 18000, hargaSekarang: 17500, deskripsi: 'Minyak goreng kelapa sawit jernih kualitas tinggi.'),
        ],
      ),
      PasarGerai(
        id: 'p1-g4',
        nama: 'Warung Rempah Mba Sri',
        deskripsi: 'Menyediakan rempah-rempah tradisional masakan Nusantara.',
        rating: 4.6,
        ulasan: 54,
        emoji: '🫚',
        produk: [
          PasarProduk(id: 'p1-g4-1', nama: 'Jahe Merah', emoji: '🫚', satuan: '100g', hargaKemarin: 7000, hargaSekarang: 8000, deskripsi: 'Jahe merah berkhasiat menghangatkan tubuh.'),
          PasarProduk(id: 'p1-g4-2', nama: 'Kunyit Bubuk', emoji: '🌿', satuan: 'pcs', hargaKemarin: 5000, hargaSekarang: 5000, deskripsi: 'Kunyit murni tanpa campuran pewarna kimia.'),
        ],
      ),
      PasarGerai(
        id: 'p1-g5',
        nama: 'Kios Buah Segar Berkah',
        deskripsi: 'Buah-buahan segar lokal dan impor terpilih.',
        rating: 4.9,
        ulasan: 156,
        emoji: '🍎',
        produk: [
          PasarProduk(id: 'p1-g5-1', nama: 'Apel Fuji', emoji: '🍎', satuan: 'kg', hargaKemarin: 38000, hargaSekarang: 40000, deskripsi: 'Apel fuji manis garing kemerahan.'),
          PasarProduk(id: 'p1-g5-2', nama: 'Pisang Ambon', emoji: '🍌', satuan: 'sisir', hargaKemarin: 18000, hargaSekarang: 18000, deskripsi: 'Pisang ambon matang pohon manis alami.'),
        ],
      ),
      PasarGerai(
        id: 'p1-g6',
        nama: 'Lapak Ikan Basah Cak Ali',
        deskripsi: 'Ikan laut dan air tawar segar tangkapan nelayan subuh hari.',
        rating: 4.7,
        ulasan: 76,
        emoji: '🐟',
        produk: [
          PasarProduk(id: 'p1-g6-1', nama: 'Ikan Bandeng', emoji: '🐟', satuan: 'kg', hargaKemarin: 32000, hargaSekarang: 30000, deskripsi: 'Ikan bandeng segar ukuran sedang isi 3-4 ekor per kg.'),
        ],
      ),
      PasarGerai(
        id: 'p1-g7',
        nama: 'Warung Tahu Tempe Pak Kirman',
        deskripsi: 'Pembuat tahu sutra dan tempe murni higienis tanpa pengawet.',
        rating: 4.8,
        ulasan: 110,
        emoji: '🧀',
        produk: [
          PasarProduk(id: 'p1-g7-1', nama: 'Tempe Papan Murni', emoji: '🫘', satuan: 'pcs', hargaKemarin: 6000, hargaSekarang: 6500, deskripsi: 'Tempe padat kedelai murni dibungkus daun pisang.'),
        ],
      ),
      PasarGerai(
        id: 'p1-g8',
        nama: 'Toko Bumbu Instan Bu Wati',
        deskripsi: 'Menyediakan bumbu halus siap masak tinggal tumis.',
        rating: 4.5,
        ulasan: 38,
        emoji: '🥣',
        produk: [
          PasarProduk(id: 'p1-g8-1', nama: 'Bumbu Rendang Siap Pakai', emoji: '🥣', satuan: 'ons', hargaKemarin: 8000, hargaSekarang: 9000, deskripsi: 'Bumbu rendang lezat siap pakai racikan resep turun-temurun.'),
        ],
      ),
    ],
  ),
  PasarMarket(
    id: 'p2',
    nama: 'Pasar Klandasan',
    kategori: 'Ikan & Seafood Segar',
    rating: 4.9,
    jarak: '9.5 km',
    buka: true,
    jamBuka: '04.00 – 12.00',
    alamat: 'Jl. Jend. Sudirman, Klandasan Ulu, Balikpapan',
    gerai: [
      PasarGerai(
        id: 'p2-g1',
        nama: 'Seafood Segar Laut Makassar',
        deskripsi: 'Pemasok seafood segar terlengkap untuk restoran dan rumah tangga.',
        rating: 4.9,
        ulasan: 142,
        emoji: '🦑',
        produk: [
          PasarProduk(id: 'p2-g1-1', nama: 'Udang Vaname', emoji: '🦐', satuan: 'kg', hargaKemarin: 70000, hargaSekarang: 68000, deskripsi: 'Udang vaname segar kupas kulit.'),
          PasarProduk(id: 'p2-g1-2', nama: 'Cumi-Cumi Telur', emoji: '🦑', satuan: 'kg', hargaKemarin: 50000, hargaSekarang: 52000, deskripsi: 'Cumi cumi segar isi telur gurih.'),
        ],
      ),
    ],
  ),
  PasarMarket(
    id: 'p3',
    nama: 'Pasar Pandansari',
    kategori: 'Beras & Palawija',
    rating: 4.7,
    jarak: '13.0 km',
    buka: false,
    jamBuka: '06.00 – 13.00',
    alamat: 'Jl. Pandansari, Balikpapan Utara',
    gerai: [
      PasarGerai(
        id: 'p3-g1',
        nama: 'Kios Palawija Pak Warno',
        deskripsi: 'Hasil bumi, jagung manis, ubi kayu, singkong mentega.',
        rating: 4.7,
        ulasan: 63,
        emoji: '🌽',
        produk: [
          PasarProduk(id: 'p3-g1-1', nama: 'Jagung Manis Pipil', emoji: '🌽', satuan: 'kg', hargaKemarin: 15000, hargaSekarang: 16000, deskripsi: 'Jagung manis pipil segar cocok untuk bakwan jagung.'),
        ],
      ),
    ],
  ),
];


