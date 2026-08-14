/// ─────────────────────────────────────────────
///  UTIL: Perhitungan Ongkir
/// ─────────────────────────────────────────────
/// Aturan:
/// 1. Berat: gratis jika <= 3 kg. Di atas 3 kg, kena Rp4.000 per kg
///    KELEBIHAN. Contoh: 5 kg -> (5-3) x 4.000 = Rp8.000
///    2 kg -> gratis, karena masih di bawah 3 kg.
///
/// 2. Jarak: gratis jika <= 3 km. Di atas 3 km, kena Rp3.000 per km
///    KELEBIHAN. Contoh: 5 km -> (5-3) x 3.000 = Rp6.000
///
/// Total ongkir = biaya berat + biaya jarak
library;

import 'dart:math' as math;

const double batasBeratGratisKg = 3.0;
const int tarifPerKg = 4000; // Rp per kg kelebihan

const double batasJarakGratisKm = 3.0;
const int tarifPerKm = 3000; // Rp per km kelebihan

/// Hitung jarak garis lurus (km) antara 2 titik koordinat pakai rumus
/// Haversine. Ini jarak "burung terbang", bukan jarak jalan asli —
/// cukup akurat untuk estimasi ongkir jarak dekat dalam kota.
double hitungJarakKm(double lat1, double lng1, double lat2, double lng2) {
  const radiusBumiKm = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return radiusBumiKm * c;
}

double _toRad(double deg) => deg * (math.pi / 180);

/// Hitung biaya ongkir dari berat pesanan (kg).
int hitungOngkirBerat(double beratKg) {
  final kelebihan = (beratKg - batasBeratGratisKg).clamp(0, double.infinity);
  return (kelebihan * tarifPerKg).round();
}

/// Hitung biaya ongkir dari jarak pengantaran (km). Kelebihan jarak
/// dibulatkan ke km terdekat dulu (pembulatan biasa) sebelum dikali
/// tarif, biar hasilnya kelipatan bulat dari tarifPerKm.
int hitungOngkirJarak(double jarakKm) {
  final kelebihan = (jarakKm - batasJarakGratisKm).clamp(0, double.infinity);
  final kelebihanDibulatkan = kelebihan.round();
  return kelebihanDibulatkan * tarifPerKm;
}

/// Ringkasan hasil hitung ongkir (berat + jarak + total).
class OngkirResult {
  final int ongkirBerat;
  final int ongkirJarak;
  final int totalOngkir;

  const OngkirResult({
    required this.ongkirBerat,
    required this.ongkirJarak,
    required this.totalOngkir,
  });
}

/// Hitung total ongkir gabungan berat + jarak.
OngkirResult hitungTotalOngkir({
  required double beratKg,
  required double jarakKm,
}) {
  final ongkirBerat = hitungOngkirBerat(beratKg);
  final ongkirJarak = hitungOngkirJarak(jarakKm);
  return OngkirResult(
    ongkirBerat: ongkirBerat,
    ongkirJarak: ongkirJarak,
    totalOngkir: ongkirBerat + ongkirJarak,
  );
}