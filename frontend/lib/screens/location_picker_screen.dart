import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';

const Color _lGreen = Color(0xFF007C3F);
const Color _lDark = Color(0xFF0F1B11);

TextStyle _ls({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _lDark,
}) => GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

// Titik tengah Balikpapan, dipakai kalau belum ada lokasi awal sama sekali.
final ll.LatLng _defaultCenter = ll.LatLng(-1.2379, 116.8529);

// ─────────────────────────────────────────────
//  LocationPickerScreen
//  Peta full-screen (tile OpenStreetMap via flutter_map) dengan pin
//  TETAP di tengah layar -- user geser petanya (pola yang sama kayak
//  Gojek/Grab), bukan geser pin-nya.
//  Balik ke halaman sebelumnya dengan Navigator.pop(context, ll.LatLng).
// ─────────────────────────────────────────────
class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  late ll.LatLng _center;
  bool _loadingGpsAwal = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _center = ll.LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      _center = _defaultCenter;
      // Kalau belum ada titik awal, coba mulai dari lokasi GPS user
      // biar nggak mulai dari titik acak.
      _mulaiDariLokasiGps();
    }
  }

  Future<void> _mulaiDariLokasiGps() async {
    setState(() => _loadingGpsAwal = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final target = ll.LatLng(pos.latitude, pos.longitude);
      setState(() => _center = target);
      _mapController.move(target, 15);
    } catch (_) {
      // Gagal -> biarkan tetap di titik tengah Balikpapan.
    } finally {
      if (mounted) setState(() => _loadingGpsAwal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: (camera, hasGesture) {
                _center = camera.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // WAJIB diisi sesuai applicationId project kamu (dipakai
                // OpenStreetMap buat identifikasi trafik, bukan cuma hiasan).
                userAgentPackageName: 'com.nemu.frontend',
              ),
              // Atribusi wajib dari kebijakan penggunaan OpenStreetMap.
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // Pin tetap di tengah layar -- yang gerak petanya, bukan pin-nya.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on_rounded,
                    color: Colors.redAccent, size: 46),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _roundBtn(
                Icons.arrow_back_ios_new_rounded,
                () => Navigator.pop(context),
              ),
            ),
          ),

          if (_loadingGpsAwal)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _lGreen),
                      ),
                      const SizedBox(width: 8),
                      Text('Mencari lokasi kamu...', style: _ls(size: 12)),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                    ],
                  ),
                  child: Text(
                    'Geser peta untuk menentukan titik lokasi',
                    style: _ls(size: 12, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, _center),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: _lGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Pakai Lokasi Ini',
                        style: _ls(size: 14, weight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
        ),
        child: Icon(icon, size: 18, color: _lDark),
      ),
    );
  }
}