// live_tracking_map.dart
//
// Widget peta kecil yang dipakai ULANG di 3 tempat:
//   - seller_home_screen.dart  -> Penjual lacak Driver
//   - orders_screen.dart       -> Pembeli lacak Driver
//   - home_screen3.dart        -> Driver lihat rute ke Penjual / Pembeli
//
// Pakai flutter_map + tile OpenStreetMap (gratis, tanpa API key) yang
// sudah jadi dependency di pubspec.yaml. TIDAK ada rute jalan asli (butuh
// Directions API berbayar) -- garis yang ditampilkan cuma garis lurus
// penunjuk arah + jarak kasarnya, bukan rute sebenarnya.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:frontend/services/order_tracking_service.dart';

const Color _mapGreen = Color(0xFF007C3F);
const Color _mapOrange = Color(0xFFD35400);

class LiveTrackingMap extends StatelessWidget {
  /// Posisi bergerak (biasanya Driver). Null kalau belum ada data GPS.
  final LiveLatLng? from;
  final String fromLabel;

  /// Tujuan (toko Penjual atau alamat Pembeli).
  final LiveLatLng to;
  final String toLabel;

  final double height;

  const LiveTrackingMap({
    super.key,
    required this.from,
    required this.fromLabel,
    required this.to,
    required this.toLabel,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final center = from != null
        ? ll.LatLng((from!.lat + to.lat) / 2, (from!.lng + to.lng) / 2)
        : ll.LatLng(to.lat, to.lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            child: IgnorePointer(
              ignoring: false,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: from != null ? 13.5 : 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nemu.frontend',
                  ),
                  if (from != null)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: [
                          ll.LatLng(from!.lat, from!.lng),
                          ll.LatLng(to.lat, to.lng),
                        ],
                        strokeWidth: 4,
                        color: _mapGreen,
                      ),
                    ]),
                  MarkerLayer(markers: [
                    if (from != null)
                      Marker(
                        point: ll.LatLng(from!.lat, from!.lng),
                        width: 42,
                        height: 42,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _mapOrange, width: 2),
                          ),
                          child: const Icon(Icons.two_wheeler_rounded,
                              color: _mapOrange, size: 22),
                        ),
                      ),
                    Marker(
                      point: ll.LatLng(to.lat, to.lng),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on_rounded,
                          color: _mapGreen, size: 36),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendDot(_mapOrange, fromLabel, show: from != null),
            if (from != null) const SizedBox(width: 14),
            _legendDot(_mapGreen, toLabel, show: true),
            const Spacer(),
            if (from != null)
              Text(
                _distanceLabel(OrderTrackingService.distanceMeters(from!, to)),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _mapGreen,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label, {required bool show}) {
    if (!show) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 10.5, color: Colors.black54),
        ),
      ],
    );
  }

  String _distanceLabel(double meters) {
    if (meters < 1000) return '± ${meters.round()} m lagi';
    return '± ${(meters / 1000).toStringAsFixed(1)} km lagi';
  }
}