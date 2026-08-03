// informasi_toko_page.dart
//
// Halaman Informasi Toko — Flutter
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/Theme/app_theme.dart';
import '/Theme/decor_background.dart';

class InformasiTokoPage extends StatefulWidget {
  const InformasiTokoPage({super.key});

  @override
  State<InformasiTokoPage> createState() => _InformasiTokoPageState();
}

class _InformasiTokoPageState extends State<InformasiTokoPage> {
  final _namaController = TextEditingController(text: 'Bengkel Rangga Jaya');
  final _kategoriController = TextEditingController(text: 'Bengkel motor');
  final _alamatController =
      TextEditingController(text: 'Jl. Merdeka No. 12, Balikpapan');
  final _teleponController = TextEditingController(text: '0812 3456 7890');
  final _deskripsiController = TextEditingController(
    text: 'Bengkel terpercaya dengan pengalaman lebih dari 10 tahun.',
  );

  @override
  void dispose() {
    _namaController.dispose();
    _kategoriController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _deskripsiController.dispose();
    super.dispose();
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
                  _TopBar(),
                  const SizedBox(height: 20),
                  _FormCard(
                    children: [
                      _FormField(
                        label: 'Nama toko',
                        icon: Icons.storefront_outlined,
                        controller: _namaController,
                      ),
                      _FormField(
                        label: 'Kategori',
                        icon: Icons.category_outlined,
                        controller: _kategoriController,
                      ),
                      _FormField(
                        label: 'Alamat',
                        icon: Icons.location_on_outlined,
                        controller: _alamatController,
                        maxLines: 2,
                      ),
                      _FormField(
                        label: 'Nomor telepon',
                        icon: Icons.phone_outlined,
                        controller: _teleponController,
                        keyboardType: TextInputType.phone,
                      ),
                      _FormField(
                        label: 'Deskripsi',
                        icon: Icons.description_outlined,
                        controller: _deskripsiController,
                        maxLines: 3,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Informasi toko berhasil disimpan',
                              style:
                                  GoogleFonts.manrope(fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: kGradientBottom,
                          ),
                        );
                        Navigator.maybePop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kInk,
                        foregroundColor: kCream,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
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

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
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
          'Informasi Toko',
          style: GoogleFonts.manrope(
            color: kInk,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: children),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isLast;

  const _FormField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: kInk.withOpacity(0.08)),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 4 : 0),
            child: Icon(icon, size: 18, color: kInk.withOpacity(0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    color: kInk.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: GoogleFonts.manrope(
                    color: kInk,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}