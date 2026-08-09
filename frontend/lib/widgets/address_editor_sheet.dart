// address_editor_sheet.dart
//
// Popup (bottom sheet) untuk mengganti alamat pengiriman.
// - Input alamat manual, selalu tersedia, jadi cara utama.
// - Opsional: switch "Gunakan lokasi saat ini" -> minta izin lokasi,
//   ambil posisi GPS, lalu reverse-geocode jadi alamat yang otomatis
//   ngisi kolom teks (masih bisa diedit manual).
// - Kalau lokasi otomatis gagal / alamatnya nggak valid (kosong), muncul
//   peta kecil buat "drop pin" manual: geser peta sampai pin merah di
//   tengah pas di lokasinya, lalu tekan "Pakai Titik Ini".
//
// ──────────────────────────────────────────────────────────────────
// SETUP YANG PERLU DITAMBAHIN MANUAL (belum otomatis lewat chat ini):
//
// 1. Tambahin ke pubspec.yaml (di bagian dependencies:):
//      geolocator: ^13.0.1
//      geocoding: ^3.0.0
//      flutter_map: ^7.0.2
//      latlong2: ^0.9.1
//    Lalu jalanin: flutter pub get
//
// 2. Izin lokasi Android — android/app/src/main/AndroidManifest.xml,
//    taruh di dalam tag <manifest> (sebelum <application>):
//      <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
//      <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
//
// 3. Izin lokasi iOS — ios/Runner/Info.plist, taruh di dalam <dict>:
//      <key>NSLocationWhenInUseUsageDescription</key>
//      <string>Nemu pakai lokasimu buat isi alamat pengiriman otomatis.</string>
//
// 4. Flutter Web: geolocator otomatis pakai Geolocation API browser,
//    tapi browser cuma ngasih izin di halaman yang dibuka lewat HTTPS
//    (atau localhost pas development). Nggak perlu setup tambahan.
//
// Peta pin-drop di bawah pakai tile OpenStreetMap gratis (tanpa API key),
// jadi tidak perlu daftar Google Maps API buat fitur ini.
// ──────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../services/address_manager.dart';

const Color _kGreen = Color(0xFF007C3F);

class AddressEditorSheet extends StatefulWidget {
  const AddressEditorSheet({super.key});

  @override
  State<AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<AddressEditorSheet> {
  late final TextEditingController _addressController;

  bool _useLocation = false;
  bool _isLocating = false;
  String? _locationError;
  bool _showPinMap = false;

  // Koordinat hasil GPS/pin-drop terakhir (null kalau alamat murni diketik
  // manual tanpa pernah pakai lokasi/pin).
  double? _resolvedLat;
  double? _resolvedLng;

  // Default: pusat Balikpapan, dipakai sebelum GPS/pin diatur manual.
  latlng.LatLng _pinLocation = const latlng.LatLng(-1.2379, 116.8529);

  @override
  void initState() {
    super.initState();
    final current = AddressManager.instance.address.value;
    _addressController = TextEditingController(text: current?.text ?? '');
    if (current?.hasCoordinates ?? false) {
      _resolvedLat = current!.lat;
      _resolvedLng = current.lng;
      _pinLocation = latlng.LatLng(current.lat!, current.lng!);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleUseLocationToggle(bool value) async {
    setState(() {
      _useLocation = value;
      _locationError = null;
      _showPinMap = false;
    });
    if (value) await _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
          _locationError = 'Layanan lokasi perangkat kamu sedang mati. Aktifkan dulu di pengaturan, atau isi manual.';
          _showPinMap = true;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          _useLocation = false;
          _locationError = permission == LocationPermission.deniedForever
              ? 'Izin lokasi diblokir permanen. Aktifkan manual lewat pengaturan aplikasi, atau isi alamat manual di bawah.'
              : 'Izin lokasi ditolak. Kamu tetap bisa isi alamat manual di bawah.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _pinLocation = latlng.LatLng(position.latitude, position.longitude);

      final address = await _reverseGeocode(position.latitude, position.longitude);

      if (address == null || address.trim().isEmpty) {
        setState(() {
          _isLocating = false;
          _locationError = 'Alamat otomatis tidak ditemukan di titik ini. Tandai lokasimu di peta ya.';
          _showPinMap = true;
        });
        return;
      }

      setState(() {
        _addressController.text = address;
        _resolvedLat = position.latitude;
        _resolvedLng = position.longitude;
        _isLocating = false;
      });
    } catch (e) {
      setState(() {
        _isLocating = false;
        _locationError = 'Gagal ambil lokasi: $e';
        _showPinMap = true;
      });
    }
  }

  Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [p.street, p.subLocality, p.locality, p.subAdministrativeArea]
          .where((s) => s != null && s.trim().isNotEmpty)
          .toList();
      if (parts.isEmpty) return null;
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> _useThisPin() async {
    setState(() => _isLocating = true);
    final address = await _reverseGeocode(_pinLocation.latitude, _pinLocation.longitude);
    setState(() {
      _isLocating = false;
      _resolvedLat = _pinLocation.latitude;
      _resolvedLng = _pinLocation.longitude;
      _addressController.text = address ??
          'Titik lokasi: ${_pinLocation.latitude.toStringAsFixed(5)}, ${_pinLocation.longitude.toStringAsFixed(5)}';
    });
  }

  bool _isSaving = false;

  Future<void> _handleSave() async {
    final text = _addressController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat tidak boleh kosong')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await AddressManager.instance.setAddress(
        DeliveryAddress(text: text, lat: _resolvedLat, lng: _resolvedLng),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan alamat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'Ganti Alamat',
                  style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Isi manual, atau nyalakan lokasi buat auto-isi.',
                  style: GoogleFonts.manrope(fontSize: 12.5, color: Colors.black54),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  style: GoogleFonts.manrope(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Jl. Mawar No. 12, RT 03, Balikpapan',
                    hintStyle: GoogleFonts.manrope(fontSize: 12.5, color: Colors.black38),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    value: _useLocation,
                    onChanged: _isLocating ? null : _handleUseLocationToggle,
                    activeColor: _kGreen,
                    title: Text(
                      'Gunakan lokasi saat ini',
                      style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Opsional — alamat otomatis terisi dari GPS',
                      style: GoogleFonts.manrope(fontSize: 11, color: Colors.black54),
                    ),
                  ),
                ),

                if (_isLocating) ...[
                  const SizedBox(height: 14),
                  const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen)),
                ],

                if (_locationError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _locationError!,
                    style: GoogleFonts.manrope(fontSize: 11.5, color: Colors.red.shade700),
                  ),
                ],

                if (_showPinMap) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Tandai lokasi di peta',
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: _pinLocation,
                              initialZoom: 16,
                              onPositionChanged: (camera, hasGesture) {
                                if (hasGesture) _pinLocation = camera.center;
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.nemu.app', // TODO: sesuaikan applicationId project kamu
                              ),
                              RichAttributionWidget(
                                attributions: [
                                  TextSourceAttribution('OpenStreetMap contributors'),
                                ],
                              ),
                            ],
                          ),
                          const IgnorePointer(
                            child: Icon(Icons.location_on, size: 40, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Geser peta sampai pin merah tepat di lokasimu.',
                    style: GoogleFonts.manrope(fontSize: 10.5, color: Colors.black45),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLocating ? null : _useThisPin,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kGreen,
                        side: const BorderSide(color: _kGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Pakai Titik Ini', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Simpan Alamat',
                            style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}