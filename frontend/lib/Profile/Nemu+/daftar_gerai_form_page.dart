// daftar_gerai_form_page.dart
//
// Form Pendaftaran Gerai — dibuka dari tombol "Lanjutkan ke Pendaftaran"
// di nemu_plus_page.dart.
//
// VERSI PALING SEDERHANA UNTUK TAHAP DEVELOPMENT:
// Cuma 3 data yang diminta — Nama lengkap, Nama pasar, Nomor rekening.
// Tidak ada upload foto, tidak ada SPSTB, tidak ada NIK/HP/dll.
// Fokusnya cuma memastikan alur: isi form -> submit -> data masuk
// Firestore -> muncul pop-up sukses.
//
// TODO ke depan kalau development lanjut ke tahap verifikasi beneran:
// tambahkan lagi field wajib lain (NIK, nomor HP, nomor kios) dan upload
// foto (KTP, gerai, produk) sesuai kebutuhan verifikasi admin.
//
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Theme/app_theme.dart';
import '../../Theme/decor_background.dart';
import '../../main.dart'; // untuk AuthGate — sesuaikan path kalau struktur foldermu beda
import '../../services/gerai_service.dart'; // sesuaikan path kalau struktur foldermu beda
import '../../services/auth_service.dart'; // untuk AuthService.registerAsSeller

// Daftar pasar yang bisa dipilih user sebagai lokasi gerai.
// NOTE: kalau daftar pasar ini nanti sering berubah/ditambah, sebaiknya
// dipindah ke Firestore (collection 'pasar') supaya tidak perlu update
// aplikasi tiap ada pasar baru — untuk sekarang di-hardcode dulu.
const List<String> kDaftarPasarBalikpapan = [
  'Pasar Klandasan',
  'Pasar Baru',
  'Pasar Pandansari',
  'Pasar Sepinggan',
  'Pasar Segar',
  'Pasar Balikpapan Permai',
  'Pasar Manggar',
  'Pasar Buton',
  'Pasar Kebun Sayur',
];

class DaftarGeraiFormPage extends StatefulWidget {
  const DaftarGeraiFormPage({super.key});

  @override
  State<DaftarGeraiFormPage> createState() => _DaftarGeraiFormPageState();
}

class _DaftarGeraiFormPageState extends State<DaftarGeraiFormPage> {
  final _namaController = TextEditingController();
  final _alamatGeraiController = TextEditingController();
  final _rekeningController = TextEditingController();

  // Pasar yang dipilih user sebagai lokasi kios.
  String? _selectedPasar;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _namaController.dispose();
    _alamatGeraiController.dispose();
    _rekeningController.dispose();
    super.dispose();
  }

  String? _validateBeforeSubmit() {
    if (_namaController.text.trim().isEmpty) return 'Nama lengkap wajib diisi.';
    if (_selectedPasar == null) return 'Pilih pasar tempat kios kamu berada.';
    if (_alamatGeraiController.text.trim().isEmpty) {
      return 'Alamat gerai wajib diisi.';
    }
    if (_rekeningController.text.trim().isEmpty) {
      return 'Nomor rekening wajib diisi.';
    }
    return null; // lolos validasi
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    final validationError = _validateBeforeSubmit();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Kamu harus login terlebih dahulu untuk mendaftar.');
      }

      final geraiData = <String, dynamic>{
        'nama': _namaController.text.trim(),
        'namaPasar': _selectedPasar,
        'alamatGerai': _alamatGeraiController.text.trim(),
        'nomorRekening': _rekeningController.text.trim(),
        'status': 'menunggu_verifikasi', // lihat alur di nemu_plus_page.dart
      };

      // Simpan record pendaftaran gerai (untuk histori/verifikasi admin)...
      await FirebaseFirestore.instance.collection('gerai').add({
        'ownerId': uid,
        ...geraiData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ...lalu aktifkan label "Penjual" DAN buat dokumen di koleksi
      // "seller" (setara "users") dalam satu langkah atomik.
      // Catatan: kalau nanti verifikasi admin sudah jalan (lihat alur di
      // nemu_plus_page.dart), pertimbangkan pindahkan pemanggilan ini ke
      // Cloud Function yang trigger saat status gerai berubah jadi "aktif",
      // supaya tidak bisa dimanipulasi langsung dari client.
      await AuthService.registerAsSeller(geraiData: geraiData);

      if (!mounted) return;

      // Popup: minta user login ulang supaya label Pembeli -> Penjual
      // ke-refresh di seluruh aplikasi (halaman akun cuma baca roles
      // sekali waktu dibuka, jadi cara paling gampang buat prototipe
      // sekarang adalah paksa re-login).
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: kCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Pendaftaran Berhasil',
            style: GoogleFonts.manrope(
              color: kInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Mohon login ulang untuk memverifikasi data.',
            style: GoogleFonts.manrope(
              color: kInk.withOpacity(0.75),
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'OK',
                style: GoogleFonts.manrope(
                  color: kGradientBottom,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

      // Sign out, lalu balik ke root aplikasi. AuthGate otomatis
      // mengarahkan ke LandingPage/LoginScreen karena user sudah logout.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pendaftaran: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Pop-up yang muncul setelah pendaftaran berhasil dikirim.
  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kGradientBottom.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: kGradientBottom,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pendaftaran Berhasil Dikirim',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: kInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Terima kasih! Data gerai kamu sudah kami terima dan sedang menunggu proses persetujuan dari admin. Kami akan memberi tahu kamu begitu gerai kamu aktif.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: kInk.withOpacity(0.7),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kInk,
                  foregroundColor: kCream,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext); // tutup dialog
                  Navigator.pop(context); // kembali dari form pendaftaran
                },
                child: Text(
                  'Oke, Mengerti',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Bottom sheet untuk memilih pasar.
  Future<void> _pickPasar() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kInk.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Pasar',
                    style: GoogleFonts.manrope(
                      color: kInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: kDaftarPasarBalikpapan.length,
                  itemBuilder: (context, index) {
                    final pasar = kDaftarPasarBalikpapan[index];
                    final isSelected = pasar == _selectedPasar;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? kGradientBottom
                            : kInk.withOpacity(0.4),
                        size: 20,
                      ),
                      title: Text(
                        pasar,
                        style: GoogleFonts.manrope(
                          color: kInk,
                          fontSize: 13.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, pasar),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() => _selectedPasar = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kGradientTop, kGradientBottom],
          ),
        ),
        child: Stack(
          children: [
            ...decorCircles(),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.maybePop(context),
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.arrow_back, color: kInk),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Form Pendaftaran Gerai',
                        style: GoogleFonts.manrope(
                          color: kInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _SectionHeading('Data gerai'),
                  const SizedBox(height: 10),
                  _FormCard(
                    fields: [
                      _TextFieldData(
                        label: 'Nama lengkap',
                        hint: 'Sesuai KTP',
                        controller: _namaController,
                        keyboardType: TextInputType.name,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Pilih pasar.
                  _PasarPickerField(
                    selectedPasar: _selectedPasar,
                    onTap: _pickPasar,
                  ),

                  // Muncul cuma setelah pasar dipilih — alamat spesifik
                  // gerai di dalam pasar tersebut (bukan alamat pasarnya).
                  if (_selectedPasar != null) ...[
                    const SizedBox(height: 10),
                    _FormCard(
                      fields: [
                        _TextFieldData(
                          label: 'Alamat gerai',
                          hint:
                              'Contoh: Blok A, Los 5, dekat pintu masuk utama',
                          controller: _alamatGeraiController,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),
                  _FormCard(
                    fields: [
                      _TextFieldData(
                        label: 'Nomor rekening',
                        hint: 'Untuk pencairan pembayaran',
                        controller: _rekeningController,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kInk,
                        foregroundColor: kCream,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kCream,
                              ),
                            )
                          : Text(
                              'Kirim Pendaftaran',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status pendaftaranmu bisa dipantau lewat halaman Kelola toko / bengkel setelah dikirim.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: kInk.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget bantu
// ---------------------------------------------------------------------------
class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          color: kInk,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _TextFieldData {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _TextFieldData({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });
}

class _FormCard extends StatelessWidget {
  final List<_TextFieldData> fields;
  const _FormCard({required this.fields});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(fields.length, (index) {
          final field = fields[index];
          final isLast = index == fields.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: GoogleFonts.manrope(
                    color: kInk.withOpacity(0.7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _PlainTextField(
                  hint: field.hint,
                  controller: field.controller,
                  keyboardType: field.keyboardType,
                  maxLines: field.maxLines,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _PlainTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _PlainTextField({
    required this.hint,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.manrope(
        color: kInk,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
          color: kInk.withOpacity(0.35),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// Field untuk memilih pasar — dropdown lewat bottom sheet.
class _PasarPickerField extends StatelessWidget {
  final String? selectedPasar;
  final VoidCallback onTap;

  const _PasarPickerField({
    required this.selectedPasar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedPasar != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nama pasar',
            style: GoogleFonts.manrope(
              color: kInk.withOpacity(0.7),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasSelection
                      ? kGradientBottom
                      : kInk.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: hasSelection
                        ? kGradientBottom
                        : kInk.withOpacity(0.6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedPasar ?? 'Pilih pasar tempat kios kamu berada',
                      style: GoogleFonts.manrope(
                        color: hasSelection ? kInk : kInk.withOpacity(0.4),
                        fontSize: 13.5,
                        fontWeight:
                            hasSelection ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: kInk.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}