// jam_operasional_page.dart
//
// Halaman Jam Operasional — Flutter
// Background: linear-gradient(180deg, #d9df36 0%, #007c3f 100%)
// Font       : Manrope, warna teks utama #0f1b11

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/Theme/app_theme.dart';
import '/Theme/decor_background.dart';

class JamOperasionalPage extends StatefulWidget {
  const JamOperasionalPage({super.key});

  @override
  State<JamOperasionalPage> createState() => _JamOperasionalPageState();
}

class _HariData {
  final String nama;
  bool buka;
  String jamBuka;
  String jamTutup;

  _HariData({
    required this.nama,
    this.buka = true,
    this.jamBuka = '08:00',
    this.jamTutup = '17:00',
  });
}

class _JamOperasionalPageState extends State<JamOperasionalPage> {
  final List<_HariData> _hari = [
    _HariData(nama: 'Senin', jamBuka: '08:00', jamTutup: '17:00'),
    _HariData(nama: 'Selasa', jamBuka: '08:00', jamTutup: '17:00'),
    _HariData(nama: 'Rabu', jamBuka: '08:00', jamTutup: '17:00'),
    _HariData(nama: 'Kamis', jamBuka: '08:00', jamTutup: '17:00'),
    _HariData(nama: 'Jumat', jamBuka: '08:00', jamTutup: '17:00'),
    _HariData(nama: 'Sabtu', jamBuka: '08:00', jamTutup: '17:00'),
    _HariData(nama: 'Minggu', buka: false, jamBuka: '08:00', jamTutup: '17:00'),
  ];

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
                  Container(
                    decoration: BoxDecoration(
                      color: kCream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: List.generate(_hari.length, (index) {
                        final h = _hari[index];
                        final isLast = index == _hari.length - 1;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: isLast
                                  ? BorderSide.none
                                  : BorderSide(color: kInk.withOpacity(0.08)),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70,
                                child: Text(
                                  h.nama,
                                  style: GoogleFonts.manrope(
                                    color: kInk,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: h.buka
                                    ? Text(
                                        '${h.jamBuka} - ${h.jamTutup}',
                                        style: GoogleFonts.manrope(
                                          color: kInk.withOpacity(0.65),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    : Text(
                                        'Tutup',
                                        style: GoogleFonts.manrope(
                                          color: kInk.withOpacity(0.4),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                              Switch(
                                value: h.buka,
                                onChanged: (v) => setState(() => h.buka = v),
                                activeColor: kGradientBottom,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Jam operasional berhasil disimpan',
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
          'Jam Operasional',
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