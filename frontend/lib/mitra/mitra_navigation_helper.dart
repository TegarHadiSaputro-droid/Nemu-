// mitra_navigation_helper.dart
//
// Helper dipakai dari HomeScreen (chip "Panggil Tukang Cepat" & banner)
// supaya tap langsung lompat ke daftar penyedia yang sesuai, tanpa user
// harus pilih kategori -> sub-kategori dulu secara manual.

import 'package:flutter/material.dart';
import 'data/mitra_data.dart';
import 'models/mitra_models.dart';
import 'pages/mitra_category_page.dart';
import 'pages/mitra_provider_list_page.dart';

/// Cari SubLayanan berdasarkan kata kunci (dicocokkan ke nama sub-kategori
/// atau ke daftar spesialisasinya). Dipakai supaya label chip di Beranda
/// ("Pipa & Bocor", "Servis AC", dst) tidak perlu di-hardcode ke satu nama
/// sub-kategori persis — cukup kata kunci yang cocok.
SubLayanan? cariSubLayanan(String keyword) {
  final kw = keyword.toLowerCase();
  for (final kategori in getKategoriMitra()) {
    for (final sub in kategori.subLayanan) {
      final gabungan = '${sub.nama} ${sub.spesialisasi}'.toLowerCase();
      if (gabungan.contains(kw)) return sub;
    }
  }
  return null;
}

/// Dipanggil dari chip quick search di Beranda. Kalau ketemu sub-layanan
/// yang cocok, langsung buka daftar penyedianya. Kalau tidak ketemu,
/// kasih tahu user lewat SnackBar dan tetap ajak ke halaman kategori Mitra.
void bukaPencarianCepatMitra(BuildContext context, String keyword) {
  final sub = cariSubLayanan(keyword);
  if (sub != null) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MitraProviderListPage(sub: sub)),
    );
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Kategori "$keyword" belum tersedia, coba lihat kategori lain ya'),
      behavior: SnackBarBehavior.floating,
    ),
  );
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MitraCategoryPage()),
  );
}
