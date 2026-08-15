import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:frontend/services/address_manager.dart';
import 'package:frontend/screens/location_picker_screen.dart';

const Color _aGreen = Color(0xFF007C3F);
const Color _aDark = Color(0xFF0F1B11);

TextStyle _as({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = _aDark,
}) => GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

// ─────────────────────────────────────────────
//  AddressEditorSheet
//  Bottom sheet buat isi/ubah alamat pengiriman. Ada 2 cara ambil
//  koordinat:
//   1. "Lokasi Saat Ini"  -> GPS device (otomatis)
//   2. "Pilih di Peta"    -> user geser pin sendiri di peta interaktif
//  Plus fallback isi manual (tanpa koordinat) kalau dua-duanya nggak
//  dipakai/gagal.
// ─────────────────────────────────────────────
class AddressEditorSheet extends StatefulWidget {
  const AddressEditorSheet({super.key});

  @override
  State<AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<AddressEditorSheet> {
  final _controller = TextEditingController();
  double? _lat;
  double? _lng;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefill dari alamat yang sudah tersimpan (kalau ada), biar user
    // gampang edit tanpa mulai dari kosong.
    final current = AddressManager.instance.address.value;
    if (current != null) {
      _controller.text = current.text;
      _lat = current.lat;
      _lng = current.lng;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Dipakai bareng oleh alur GPS maupun alur pilih-di-peta: ubah
  /// koordinat jadi alamat yang gampang dibaca (reverse geocode),
  /// lalu isi ke form.
  Future<void> _terapkanKoordinat(double lat, double lng) async {
    String alamatText =
        'Titik lokasi: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final bagian = [p.street, p.subLocality, p.locality]
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(', ');
        if (bagian.isNotEmpty) alamatText = bagian;
      }
    } catch (_) {
      // Reverse-geocode gagal (mis. offline) -> tetap pakai teks koordinat.
    }

    if (!mounted) return;
    setState(() {
      _lat = lat;
      _lng = lng;
      _controller.text = alamatText;
      _loading = false;
      _error = null;
    });
  }

  // ── Opsi 1: Lokasi Saat Ini (GPS) ──
  Future<void> _gunakanLokasiSaatIni() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'GPS tidak aktif. Nyalakan lokasi di pengaturan device dulu.';
          _loading = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Izin lokasi ditolak. Aktifkan izin lokasi untuk pakai fitur ini.';
            _loading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Izin lokasi diblokir permanen. Aktifkan lewat pengaturan aplikasi.';
          _loading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _terapkanKoordinat(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _error = 'Gagal ambil lokasi. Coba lagi ya.';
        _loading = false;
      });
    }
  }

  // ── Opsi 2: Pilih Lokasi di Peta (manual) ──
  Future<void> _pilihLokasiDiPeta() async {
    final hasil = await Navigator.push<ll.LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLat: _lat, initialLng: _lng),
      ),
    );

    if (hasil == null) return; // user batal / back tanpa pilih

    setState(() => _loading = true);
    await _terapkanKoordinat(hasil.latitude, hasil.longitude);
  }

  void _simpan() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Isi alamat dulu, atau pilih lokasi lewat GPS/peta.');
      return;
    }
    AddressManager.instance.setAddress(
      DeliveryAddress(text: text, lat: _lat, lng: _lng),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Biar sheet naik pas keyboard muncul
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Alamat Pengiriman', style: _as(size: 18, weight: FontWeight.bold)),
            const SizedBox(height: 16),

            // ── Dua opsi ambil lokasi, sejajar ──
            Row(
              children: [
                Expanded(
                  child: _opsiLokasiButton(
                    icon: Icons.my_location_rounded,
                    label: 'Lokasi Saat Ini',
                    onTap: _loading ? null : _gunakanLokasiSaatIni,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _opsiLokasiButton(
                    icon: Icons.map_rounded,
                    label: 'Pilih di Peta',
                    onTap: _loading ? null : _pilihLokasiDiPeta,
                  ),
                ),
              ],
            ),

            if (_loading) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _aGreen),
                  ),
                  const SizedBox(width: 8),
                  Text('Memproses lokasi...', style: _as(size: 12, color: Colors.black45)),
                ],
              ),
            ],

            if (_lat != null && _lng != null) ...[
              const SizedBox(height: 10),
              Text(
                'Titik lokasi: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                style: _as(size: 11, color: Colors.black45),
              ),
            ],

            const SizedBox(height: 16),
            Text('Atau tulis manual', style: _as(size: 12, color: Colors.black45)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 2,
              style: _as(size: 14),
              decoration: InputDecoration(
                hintText: 'Contoh: Jl. Marsma Iswahyudi No. 10, Sepinggan',
                hintStyle: _as(size: 13, color: Colors.black38),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              onChanged: (_) {
                // Kalau user ngetik manual, koordinat lama dianggap tidak
                // relevan lagi -- dikosongkan supaya ongkir jarak fallback
                // ke perkiraan, bukan salah pakai titik lama.
                if (_lat != null || _lng != null) {
                  setState(() {
                    _lat = null;
                    _lng = null;
                  });
                }
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: _as(size: 12, color: Colors.redAccent)),
            ],

            const SizedBox(height: 20),
            GestureDetector(
              onTap: _simpan,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _aGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Simpan Alamat',
                    style: _as(size: 14, weight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opsiLokasiButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _aGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _aGreen.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _aGreen, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: _as(size: 12.5, weight: FontWeight.bold, color: _aGreen),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}