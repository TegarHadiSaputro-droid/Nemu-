// mitra_models.dart
//
// Model data untuk fitur "Mitra" / penyedia jasa (kang!).
// Struktur: KategoriUtama -> SubLayanan -> PenyediaJasa
// (persis mengikuti struktur "Kategori Utama / Sub-Kategori / Jenis Barang"
// yang sudah dibuat di data layanan sebelumnya.)

import 'package:flutter/material.dart';

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
