// mitra_models.dart
//
// Model data untuk fitur "Mitra" / penyedia jasa (kang!).
// Struktur: KategoriUtama -> SubLayanan -> PenyediaJasa
// (persis mengikuti struktur "Kategori Utama / Sub-Kategori / Jenis Barang"
// yang sudah dibuat di data layanan sebelumnya.)

import 'package:flutter/material.dart';
import 'dart:math';

/// Kategori utama, contoh: Perbaikan, Kebersihan, Kesehatan, Pendidikan.
class KategoriUtama {
  final String nama;
  final IconData icon;
  final String deskripsiSingkat;
  final List<SubLayanan> subLayanan;

  const KategoriUtama({
    required this.nama,
    required this.icon,
    required this.deskripsiSingkat,
    required this.subLayanan,
  });
}

/// Satu tingkatan kebutuhan/tarif untuk sebuah jenis layanan, contoh
/// "Servis Ringan" dengan estimasi Rp50.000 - Rp100.000. Dipakai di
/// kalkulator estimasi tarif interaktif (user pilih tingkat kebutuhannya,
/// lalu lihat kisaran harganya).
class TingkatKebutuhan {
  final String label;
  final String deskripsi;
  final int tarifMin;
  final int tarifMax;

  const TingkatKebutuhan({
    required this.label,
    required this.deskripsi,
    required this.tarifMin,
    required this.tarifMax,
  });

  /// Format siap tampil, contoh "Rp50.000 - Rp100.000".
  String get labelTarif => '${formatRupiah(tarifMin)} - ${formatRupiah(tarifMax)}';
}

/// Format angka jadi Rupiah dengan titik ribuan, contoh 150000 -> "Rp150.000".
String formatRupiah(int angka) {
  final str = angka.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final posisiDariKanan = str.length - i;
    buffer.write(str[i]);
    if (posisiDariKanan > 1 && posisiDariKanan % 3 == 1) buffer.write('.');
  }
  return 'Rp$buffer';
}

/// Sub-kategori di dalam satu kategori utama, contoh: "Elektronik & Gadget"
/// dengan cakupan/spesialisasi "Smartphone, Tablet, Smartwatch".
class SubLayanan {
  final String nama;
  final String spesialisasi;
  final IconData icon;
  final List<PenyediaJasa> penyedia;
  final List<TingkatKebutuhan> tingkatKebutuhan;

  const SubLayanan({
    required this.nama,
    required this.spesialisasi,
    required this.icon,
    required this.penyedia,
    this.tingkatKebutuhan = const [],
  });

  /// Daftar spesialisasi dipecah jadi tag-tag kecil, dipakai buat chip
  /// di halaman detail & list.
  List<String> get tagSpesialisasi =>
      spesialisasi.split(',').map((e) => e.trim()).toList();

  /// Estimasi tarif keseluruhan (dari tingkat termurah sampai termahal),
  /// dipakai buat label ringkas "Mulai Rp50.000" di daftar sub-layanan.
  String? get labelEstimasiTarif {
    if (tingkatKebutuhan.isEmpty) return null;
    final termurah = tingkatKebutuhan.map((t) => t.tarifMin).reduce((a, b) => a < b ? a : b);
    return 'Mulai ${formatRupiah(termurah)}';
  }
}

/// Satu penyedia jasa: bisa berupa toko/usaha atau perorangan ("kang").
class PenyediaJasa {
  final String nama;
  final bool isToko; // true = toko/usaha, false = perorangan (kang)
  final double rating;
  final double jarakKm;
  final int pesananSelesai;
  final String lokasi;
  final bool buka; // legacy override manual, jarang dipakai lagi
  final String jamBuka; // format "HH:mm", contoh "08:00"
  final String jamTutup; // format "HH:mm", contoh "20:00"

  const PenyediaJasa({
    required this.nama,
    required this.isToko,
    required this.rating,
    required this.jarakKm,
    required this.pesananSelesai,
    required this.lokasi,
    this.buka = true,
    this.jamBuka = '08:00',
    this.jamTutup = '20:00',
  });

  String get labelTipe => isToko ? 'Toko / Usaha' : 'Perorangan';
  IconData get iconTipe => isToko ? Icons.storefront_rounded : Icons.badge_rounded;

  /// Label jam operasional siap tampil, contoh "08:00 - 20:00".
  String get labelJamOperasional => '$jamBuka - $jamTutup';

  int _menitDari(String hhmm) {
    final bagian = hhmm.split(':');
    final jam = int.tryParse(bagian[0]) ?? 0;
    final menit = bagian.length > 1 ? (int.tryParse(bagian[1]) ?? 0) : 0;
    return jam * 60 + menit;
  }

  /// Status buka/tutup dihitung LANGSUNG dari waktu sekarang dibanding
  /// jam operasional toko (mendukung jam yang melewati tengah malam,
  /// misal 20:00 - 02:00).
  bool get sedangBuka {
    final now = DateTime.now();
    final menitSekarang = now.hour * 60 + now.minute;
    final mulai = _menitDari(jamBuka);
    final selesai = _menitDari(jamTutup);
    if (mulai == selesai) return true; // buka 24 jam
    if (mulai < selesai) {
      return menitSekarang >= mulai && menitSekarang < selesai;
    }
    // Rentang melewati tengah malam.
    return menitSekarang >= mulai || menitSekarang < selesai;
  }

  /// Sisa waktu sampai buka/tutup, buat label kecil semacam
  /// "Tutup 2 jam lagi" / "Buka 45 menit lagi".
  String get labelHitungMundur {
    final now = DateTime.now();
    final menitSekarang = now.hour * 60 + now.minute;
    final target = sedangBuka ? _menitDari(jamTutup) : _menitDari(jamBuka);
    var selisih = target - menitSekarang;
    if (selisih <= 0) selisih += 24 * 60;
    final jam = selisih ~/ 60;
    final menit = selisih % 60;
    final sisa = jam > 0 ? '$jam jam${menit > 0 ? ' $menit mnt' : ''}' : '$menit menit';
    return sedangBuka ? 'Tutup $sisa lagi' : 'Buka $sisa lagi';
  }
}

/// Satu ulasan pelanggan untuk seorang penyedia jasa.
/// Dipakai bersama oleh halaman detail penyedia (preview 3 ulasan) dan
/// halaman "Lihat Semua Ulasan" (daftar lengkap + fitur like/setuju).
class Ulasan {
  final String nama;
  final double rating;
  final String waktu;
  final String komentar;
  final int jumlahSetujuAwal;

  const Ulasan({
    required this.nama,
    required this.rating,
    required this.waktu,
    required this.komentar,
    this.jumlahSetujuAwal = 0,
  });
}


/// Belum ada backend ulasan asli, jadi daftar ulasan pelanggan kosong
/// (0 ulasan) untuk semua penyedia.
List<Ulasan> ulasanDummyUntuk(PenyediaJasa provider) => const [];

/// Rating acak (1-5) untuk satu penyedia, dipakai buat ringkasan rating di
/// halaman "Semua Ulasan" selama belum ada ulasan asli. Di-seed dari nama &
/// lokasi penyedia supaya hasilnya konsisten tiap dibuka untuk penyedia
/// yang sama (bukan berubah-ubah tiap render), tapi beda-beda antar
/// penyedia. Hanya SATU bintang yang punya nilai (1), bintang lainnya 0.
int ratingAcakUntuk(PenyediaJasa provider) {
  final seed = provider.nama.hashCode ^ provider.lokasi.hashCode;
  final rnd = Random(seed);
  return 1 + rnd.nextInt(5);
}

/// Status online/offline mitra saat ini. Belum ada backend status
/// real-time, jadi status ini di-seed dari nama penyedia (mirip pola
/// ratingAcakUntuk) supaya konsisten tiap dibuka untuk penyedia yang sama,
/// tapi beda-beda antar penyedia — sebagian tampak online, sebagian
/// offline, persis seperti aplikasi yang sudah jalan dengan data asli.
/// Sekitar 65% penyedia akan tampak online.
bool statusOnlineUntuk(PenyediaJasa provider) {
  final seed = provider.nama.hashCode ^ provider.lokasi.hashCode ^ 0x4F4E4C4E;
  final rnd = Random(seed);
  return rnd.nextDouble() < 0.65;
}

/// Penyimpanan status "disimpan/favorit" mitra di memori aplikasi (bukan
/// state satu halaman saja), dikunci berdasarkan nama penyedia. Dengan ini
/// status simpan tetap konsisten walau user keluar-masuk halaman detail
/// dalam sesi aplikasi yang sama — baru reset kalau aplikasinya ditutup
/// total (belum pakai penyimpanan permanen semacam SharedPreferences/DB).
///
/// Sengaja pakai List (bukan Set) supaya URUTAN penyimpanan ikut kesimpan:
/// nama yang paling BARU disimpan selalu ditaruh di index 0 (paling depan),
/// jadi kalau ada penyedia yang baru saja ditandai "simpan", dia langsung
/// jadi yang PALING ATAS di daftar — bukan cuma ikut-ikutan diurutkan
/// berdasarkan rating di antara sesama yang tersimpan.
///
/// Dibungkus ValueNotifier supaya SEMUA tempat yang menampilkan status
/// simpan (halaman daftar penyedia & halaman detail) bisa saling dengar
/// perubahan lewat ValueListenableBuilder — begitu satu tombol simpan
/// dipencet, tombol simpan di halaman lain ikut berubah warnanya secara
/// otomatis, tanpa harus keluar-masuk halaman dulu.
final ValueNotifier<List<String>> mitraTersimpanNotifier =
    ValueNotifier<List<String>>(<String>[]);

/// Cek apakah seorang penyedia sedang berstatus "disimpan".
bool isMitraTersimpan(PenyediaJasa provider) =>
    mitraTersimpanNotifier.value.contains(provider.nama);

/// Balik status simpan seorang penyedia (simpan <-> batal simpan).
/// Return status terbaru setelah di-toggle. List baru sengaja dibuat
/// (bukan diubah langsung) supaya ValueNotifier mendeteksi perubahan dan
/// memberi tahu semua listener-nya. Saat disimpan, namanya disisipkan di
/// index 0 supaya langsung jadi yang paling depan/paling atas.
bool toggleMitraTersimpan(PenyediaJasa provider) {
  final updated = List<String>.from(mitraTersimpanNotifier.value);
  late final bool statusBaru;
  if (updated.contains(provider.nama)) {
    updated.remove(provider.nama);
    statusBaru = false;
  } else {
    updated.insert(0, provider.nama);
    statusBaru = true;
  }
  mitraTersimpanNotifier.value = updated;
  return statusBaru;
}