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

/// Sub-kategori di dalam satu kategori utama, contoh: "Elektronik & Gadget"
/// dengan cakupan/spesialisasi "Smartphone, Tablet, Smartwatch".
class SubLayanan {
  final String nama;
  final String spesialisasi;
  final IconData icon;
  final List<PenyediaJasa> penyedia;

  const SubLayanan({
    required this.nama,
    required this.spesialisasi,
    required this.icon,
    required this.penyedia,
  });

  /// Daftar spesialisasi dipecah jadi tag-tag kecil, dipakai buat chip
  /// di halaman detail & list.
  List<String> get tagSpesialisasi =>
      spesialisasi.split(',').map((e) => e.trim()).toList();
}

/// Satu penyedia jasa: bisa berupa toko/usaha atau perorangan ("kang").
class PenyediaJasa {
  final String nama;
  final bool isToko; // true = toko/usaha, false = perorangan (kang)
  final double rating;
  final double jarakKm;
  final int pesananSelesai;
  final String lokasi;
  final bool buka; // status buka/tutup saat ini

  const PenyediaJasa({
    required this.nama,
    required this.isToko,
    required this.rating,
    required this.jarakKm,
    required this.pesananSelesai,
    required this.lokasi,
    this.buka = true,
  });

  String get labelTipe => isToko ? 'Toko / Usaha' : 'Perorangan';
  IconData get iconTipe => isToko ? Icons.storefront_rounded : Icons.badge_rounded;
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


/// Komentar dummy per rentang rating, supaya nada ulasan cocok dengan
/// bintang yang didapat (ulasan 1-2★ terasa kecewa, 4-5★ terasa puas).
String _komentarUntukRating(int bintang, PenyediaJasa provider) {
  switch (bintang) {
    case 5:
      return 'Sangat puas! ${provider.nama} kerja rapi, cepat, dan hasilnya melebihi ekspektasi. Recommended banget.';
    case 4:
      return 'Kerjanya bagus dan sesuai jadwal. ${provider.nama} komunikatif, cuma ada sedikit detail kecil yang bisa lebih rapi lagi.';
    case 3:
      return 'Cukup oke, hasil kerja standar dan sesuai harga. Tidak ada masalah berarti tapi juga belum istimewa.';
    case 2:
      return 'Kurang memuaskan, ${provider.nama} datang terlambat dari jadwal dan hasil kerjanya masih perlu diperbaiki.';
    default:
      return 'Sangat mengecewakan, sudah ditunggu lama tapi hasil kerja tidak sesuai yang dijanjikan. Tidak akan order lagi.';
  }
}

/// Data dummy 20 ulasan pelanggan. Rating tiap ulasan diacak (memakai seed
/// dari nama & lokasi penyedia supaya hasilnya konsisten tiap dibuka untuk
/// penyedia yang sama, bukan berubah-ubah tiap render), lalu komentarnya
/// disesuaikan dengan bintang yang didapat. Belum ada backend ulasan asli.
List<Ulasan> ulasanDummyUntuk(PenyediaJasa provider) {
  final seed = provider.nama.hashCode ^ provider.lokasi.hashCode;
  final rnd = Random(seed);

  const namaList = [
    'Dewi Anggraini', 'Rizky Ramadhan', 'Siti Nurhaliza', 'Budi Santoso',
    'Putri Wulandari', 'Ahmad Fauzi', 'Nadia Kusuma', 'Hendra Wijaya',
    'Lestari Handayani', 'Fajar Nugroho', 'Wahyu Saputra', 'Indah Permata',
    'Yusuf Hidayat', 'Ratna Sari', 'Doni Pratama', 'Melati Anjani',
    'Bayu Firmansyah', 'Citra Dewi', 'Eka Prasetyo', 'Sari Wulandari',
  ];

  const waktuList = [
    '1 hari lalu', '3 hari lalu', '5 hari lalu', '1 minggu lalu',
    '1 minggu lalu', '2 minggu lalu', '2 minggu lalu', '3 minggu lalu',
    '3 minggu lalu', '1 bulan lalu', '1 bulan lalu', '1 bulan lalu',
    '2 bulan lalu', '2 bulan lalu', '2 bulan lalu', '3 bulan lalu',
    '3 bulan lalu', '4 bulan lalu', '4 bulan lalu', '5 bulan lalu',
  ];

  // Pool rating 1-5 untuk 20 ulasan (lebih condong ke rating tinggi biar
  // realistis, tapi tetap mencakup semua bintang 1-5 supaya filter bintang
  // di halaman "Semua Ulasan" selalu ada isinya), lalu diacak urutannya.
  final ratingPool = <int>[
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    4, 4, 4, 4, 4,
    3, 3,
    2,
    1,
  ]..shuffle(rnd);

  return List.generate(namaList.length, (i) {
    final bintang = ratingPool[i];
    return Ulasan(
      nama: namaList[i],
      rating: bintang.toDouble(),
      waktu: waktuList[i],
      komentar: _komentarUntukRating(bintang, provider),
      jumlahSetujuAwal: 2 + rnd.nextInt(38),
    );
  });
}