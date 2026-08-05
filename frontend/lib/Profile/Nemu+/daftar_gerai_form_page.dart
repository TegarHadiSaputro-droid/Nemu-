// daftar_gerai_form_page.dart
//
// Form Pendaftaran Gerai — dibuka dari tombol "Lanjutkan ke Pendaftaran"
// di nemu_plus_page.dart. Berisi data wajib, pertanyaan SPSTB (dengan
// field kondisional Ya/Tidak), dan data opsional.
//
// Upload foto memakai package image_picker (pilih dari galeri/kamera).
// Tambahkan di pubspec.yaml:
//   dependencies:
//     image_picker: ^1.1.2
//
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Theme/app_theme.dart';
import '../../Theme/decor_background.dart';
import '../../services/auth_service.dart';

class DaftarGeraiFormPage extends StatefulWidget {
  const DaftarGeraiFormPage({super.key});

  @override
  State<DaftarGeraiFormPage> createState() => _DaftarGeraiFormPageState();
}

class _DaftarGeraiFormPageState extends State<DaftarGeraiFormPage> {
  // null = belum dipilih, true = Ya, false = Tidak
  bool? _punyaSpstb;

  // Menyimpan foto yang sudah dipilih per label, misalnya:
  // {'Foto KTP': XFile(...), 'Foto gerai': XFile(...)}
  final Map<String, XFile> _uploadedFiles = {};

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Kamu harus login terlebih dahulu untuk mendaftar.');
      }

      // TODO: upload isi _uploadedFiles ke Firebase Storage lalu simpan
      // URL-nya di sini, plus field teks lain dari _FormCard (nama, NIK,
      // nama pasar, nomor kios, SPSTB, dst) — sambungkan lewat
      // TextEditingController lalu masukkan ke geraiData di bawah.
      final geraiData = <String, dynamic>{
        'punyaSpstb': _punyaSpstb,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran gerai berhasil dikirim'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pendaftaran: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickImage(String label) async {
    // Tampilkan pilihan sumber: Kamera atau Galeri
    final source = await showModalBottomSheet<ImageSource>(
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
                  color: kInk.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: kInk),
                title: Text(
                  'Ambil dari kamera',
                  style: GoogleFonts.manrope(color: kInk, fontSize: 13.5),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: kInk),
                title: Text(
                  'Pilih dari galeri',
                  style: GoogleFonts.manrope(color: kInk, fontSize: 13.5),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _uploadedFiles[label] = pickedFile;
      });
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

                  _SectionHeading('Data diri & gerai (wajib)'),
                  const SizedBox(height: 10),
                  _FormCard(
                    fields: const [
                      _TextFieldData(
                        label: 'Nama lengkap',
                        hint: 'Sesuai KTP',
                      ),
                      _TextFieldData(
                        label: 'NIK (KTP)',
                        hint: '16 digit nomor KTP',
                      ),
                      _TextFieldData(
                        label: 'Nomor HP',
                        hint: '08xx-xxxx-xxxx',
                      ),
                      _TextFieldData(
                        label: 'Nama pasar',
                        hint: 'Contoh: Pasar Klandasan',
                      ),
                      _TextFieldData(
                        label: 'Nomor kios / los / lapak',
                        hint: 'Contoh: Blok A No. 12',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _UploadGroup(
                    items: const [
                      'Foto KTP',
                      'Foto gerai',
                      'Foto produk',
                      'Foto pemilik gerai',
                    ],
                    uploadedFiles: _uploadedFiles,
                    onPick: _pickImage,
                  ),

                  const SizedBox(height: 24),

                  _SectionHeading('Kepemilikan SPSTB'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kCream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apakah Anda memiliki SPSTB?',
                          style: GoogleFonts.manrope(
                            color: kInk,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _RadioOption(
                          label: 'Ya, saya punya SPSTB',
                          selected: _punyaSpstb == true,
                          onTap: () => setState(() => _punyaSpstb = true),
                        ),
                        _RadioOption(
                          label: 'Tidak / belum punya',
                          selected: _punyaSpstb == false,
                          onTap: () => setState(() => _punyaSpstb = false),
                        ),

                        if (_punyaSpstb == true) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Nomor SPSTB',
                            style: GoogleFonts.manrope(
                              color: kInk.withValues(alpha: 0.7),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _PlainTextField(hint: 'Masukkan nomor SPSTB'),
                          const SizedBox(height: 10),
                          _UploadButton(
                            label: 'Upload foto SPSTB',
                            file: _uploadedFiles['Foto SPSTB'],
                            onTap: () => _pickImage('Foto SPSTB'),
                          ),
                        ],

                        if (_punyaSpstb == false) ...[
                          const SizedBox(height: 14),
                          _UploadButton(
                            label: 'Upload foto kios',
                            file: _uploadedFiles['Foto kios'],
                            onTap: () => _pickImage('Foto kios'),
                          ),
                          const SizedBox(height: 10),
                          _UploadButton(
                            label:
                                'Upload bukti sewa / surat pengelola pasar (jika ada)',
                            file: _uploadedFiles['Bukti sewa'],
                            onTap: () => _pickImage('Bukti sewa'),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Keterangan tambahan',
                            style: GoogleFonts.manrope(
                              color: kInk.withValues(alpha: 0.7),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _PlainTextField(
                            hint:
                                'Ceritakan kondisi kios/losmu, misalnya lama berjualan di sini',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pendaftaranmu tetap diproses dan akan diperiksa langsung oleh admin.',
                            style: GoogleFonts.manrope(
                              color: kInk.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _SectionHeading('Data tambahan (opsional)'),
                  const SizedBox(height: 10),
                  _FormCard(
                    fields: const [
                      _TextFieldData(
                        label: 'NPWP (jika ada)',
                        hint: 'Nomor NPWP',
                      ),
                      _TextFieldData(
                        label: 'Nomor rekening atau QRIS',
                        hint: 'Untuk pencairan pembayaran',
                      ),
                      _TextFieldData(
                        label: 'Jam operasional',
                        hint: 'Contoh: 06.00 - 15.00',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _UploadButton(
                    label: 'Pilih titik lokasi kios di peta',
                    file: null,
                    onTap: () {
                      // TODO: buka map picker (google_maps_flutter / geolocator)
                    },
                    icon: Icons.location_on_outlined,
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
                      color: kInk.withValues(alpha: 0.6),
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
  const _TextFieldData({required this.label, required this.hint});
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
                    color: kInk.withValues(alpha: 0.7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _PlainTextField(hint: field.hint),
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
  final int maxLines;
  const _PlainTextField({required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLines,
      style: GoogleFonts.manrope(
        color: kInk,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
          color: kInk.withValues(alpha: 0.35),
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

// Grup tombol upload foto (Foto KTP, Foto gerai, dst)
class _UploadGroup extends StatelessWidget {
  final List<String> items;
  final Map<String, XFile> uploadedFiles;
  final void Function(String label) onPick;

  const _UploadGroup({
    required this.items,
    required this.uploadedFiles,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final label = items[index];
        final isLast = index == items.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: _UploadButton(
            label: label,
            file: uploadedFiles[label],
            onTap: () => onPick(label),
          ),
        );
      }),
    );
  }
}

// Satu tombol upload foto/dokumen — sudah tersambung ke image_picker lewat
// callback onTap. Kalau file sudah dipilih, tampilkan thumbnail + nama file.
// Pakai XFile + Image.memory supaya jalan di semua platform (termasuk Web),
// karena dart:io File tidak didukung di Flutter Web.
class _UploadButton extends StatelessWidget {
  final String label;
  final XFile? file;
  final VoidCallback onTap;
  final IconData icon;

  const _UploadButton({
    required this.label,
    required this.file,
    required this.onTap,
    this.icon = Icons.upload_file_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFile ? kGradientBottom : kInk.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            if (hasFile)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: FutureBuilder<Uint8List>(
                  future: file!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        width: 34,
                        height: 34,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return Image.memory(
                      snapshot.data!,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              )
            else
              Icon(icon, size: 18, color: kInk.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasFile ? '$label — foto terpilih' : label,
                style: GoogleFonts.manrope(
                  color: hasFile ? kInk : kInk.withValues(alpha: 0.75),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              hasFile ? Icons.check_circle : Icons.chevron_right,
              size: 18,
              color: hasFile ? kGradientBottom : kInk.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// Opsi radio kustom Ya/Tidak
class _RadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? kGradientBottom : kInk.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: kInk,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}